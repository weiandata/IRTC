## Regression tests for the defects a production survey analysis exposed in
## 1.1.1 (85k respondents, 10 dichotomous items, three content dimensions,
## sampling weights). Each block names the finding it locks down.

sq_sim <- function(n = 600, J = 6, D = 2, rho = 0.5, seed = 5) {
  set.seed(seed)
  Q <- matrix(0, J, D)
  for (j in seq_len(J)) Q[j, ((j - 1) %% D) + 1L] <- 1
  S <- matrix(rho, D, D); diag(S) <- 1
  TH <- MASS::mvrnorm(n, rep(0, D), S)
  a0 <- runif(J, 0.8, 1.6); b0 <- rnorm(J)
  th_j <- sapply(seq_len(J), function(j) TH[, which(Q[j, ] == 1)])
  resp <- matrix(rbinom(n * J, 1, plogis(t(a0 * (t(th_j) - b0)))), n, J)
  colnames(resp) <- paste0("I", seq_len(J))
  list(resp = resp, Q = Q)
}

## --- S1-01: NA in the response matrix used to segfault the C++ E-step -------

test_that("the streaming engine treats NA as missing instead of crashing", {
  d <- sq_sim()
  full <- irtc.mml.2pl(resp = d$resp, irtmodel = "GPCM", ndim = 2, Q = d$Q,
                       verbose = FALSE, method = "streaming")
  holed <- d$resp
  holed[1, 1] <- NA
  holed[5, 3] <- NA
  got <- irtc.mml.2pl(resp = holed, irtmodel = "GPCM", ndim = 2, Q = d$Q,
                      verbose = FALSE, method = "streaming")
  expect_true(is.finite(got$ic$deviance))
  expect_true(all(is.finite(got$a)))
  ## two missing cells out of 3600 must barely move the solution
  expect_equal(got$a, full$a, tolerance = 0.05)
})

test_that("a person with no responses at all is tolerated", {
  d <- sq_sim()
  holed <- d$resp
  holed[3, ] <- NA
  got <- irtc.mml.2pl(resp = holed, irtmodel = "GPCM", ndim = 2, Q = d$Q,
                      verbose = FALSE, method = "streaming")
  expect_true(is.finite(got$ic$deviance))
  ## a person carrying no information sits at the prior mean
  expect_equal(got$person$EAP.Dim1[3], 0, tolerance = 1e-6)
})

## --- S1-02: quadrature weights are probability mass, not density -----------

test_that("the streaming log-likelihood does not depend on the node count", {
  d <- sq_sim(n = 500, J = 6, D = 2)
  lls <- vapply(c(21, 31, 41), function(nq) {
    m <- irtc.mml.2pl(resp = d$resp, irtmodel = "GPCM", ndim = 2, Q = d$Q,
                      verbose = FALSE, method = "streaming",
                      control = list(nodes = seq(-6, 6, length.out = nq)))
    m$ic$loglike
  }, numeric(1))
  ## before the fix these differed by n * D * log(1/h), i.e. hundreds of units
  expect_lt(max(abs(lls - lls[1])), 1)
})

test_that("grid and streaming report the same deviance for the same model", {
  d <- sq_sim(n = 800, J = 8, D = 1)
  grid <- irtc.mml.2pl(resp = d$resp, irtmodel = "2PL", ndim = 1,
                       verbose = FALSE, method = "grid")
  stream <- irtc.mml.2pl(resp = d$resp, irtmodel = "2PL", ndim = 1,
                         verbose = FALSE, method = "streaming")
  expect_equal(stream$ic$deviance, grid$ic$deviance, tolerance = 1e-4)
  expect_equal(as.numeric(stream$EAP.rel), as.numeric(unlist(grid$EAP.rel)),
               tolerance = 1e-3)
})

test_that("the reported log-likelihood stays a log-probability", {
  d <- sq_sim(n = 600, J = 6, D = 2)
  m <- irtc.mml.2pl(resp = d$resp, irtmodel = "GPCM", ndim = 2, Q = d$Q,
                    verbose = FALSE, method = "streaming")
  expect_lt(m$ic$loglike, 0)
  expect_gt(m$ic$deviance, 0)
})

test_that("the streaming ic is the same shape as the grid ic", {
  d <- sq_sim(n = 400, J = 6, D = 2)
  m <- irtc.mml.2pl(resp = d$resp, irtmodel = "GPCM", ndim = 2, Q = d$Q,
                    verbose = FALSE, method = "streaming")
  expect_s3_class(m$ic, "data.frame")
  expect_equal(nrow(m$ic), 1L)
  expect_equal(as.numeric(logLik(m)), -m$ic$deviance / 2)
})

## --- S1-03: degenerate latent covariance -----------------------------------

test_that("a collapsed covariance keeps a valid deviance and warns", {
  ## three declared dimensions that are really one trait
  set.seed(31); n <- 1500; J <- 9
  th <- rnorm(n); a0 <- runif(J, 0.8, 1.8); b0 <- rnorm(J)
  resp <- matrix(rbinom(n * J, 1,
    plogis(sapply(seq_len(J), function(j) a0[j] * (th - b0[j])))), n, J)
  Q <- matrix(0, J, 3); Q[1:3, 1] <- 1; Q[4:6, 2] <- 1; Q[7:9, 3] <- 1
  m <- NULL
  expect_warning(
    m <- irtc.mml.2pl(resp = resp, irtmodel = "GPCM", ndim = 3, Q = Q,
                      verbose = FALSE, method = "streaming"),
    "W427")
  expect_lt(m$ic$loglike, 0)          # used to flip positive
  expect_gt(m$ic$deviance, 0)         # used to go negative
  ## the three dimensions have collapsed onto one, so the reliability must
  ## match the unidimensional fit rather than being deflated
  uni <- irtc.mml.2pl(resp = resp, irtmodel = "2PL", ndim = 1,
                      verbose = FALSE, method = "grid")
  expect_equal(as.numeric(m$EAP.rel),
               rep(as.numeric(unlist(uni$EAP.rel)), 3), tolerance = 0.02)
})

## --- S2-04: slopes come from the dimension the item loads on ---------------

test_that("multidimensional item parameters are not read off dimension 1", {
  d <- sq_sim(n = 800, J = 6, D = 2, rho = 0.4, seed = 3)
  Q <- d$Q
  dimnames(Q) <- list(colnames(d$resp), c("DimA", "DimB"))
  dd <- data.frame(pid = seq_len(nrow(d$resp)) + 90000L, d$resp)
  m <- irtc(dd, model = "GPCM", q = Q, ndim = 2, id = "pid", verbose = FALSE)
  tab <- irtc_param_table(m, resp = d$resp)
  ## every item has a real slope and difficulty, whichever dimension it loads on
  expect_false(any(tab$slope_a == 0))
  expect_false(anyNA(tab$difficulty_b))
  expect_equal(tab$slope_a,
               round(rowSums(matrix(as.numeric(m$B[, 2, ]), 6, 2)), 4))
  expect_equal(tab$dimension, colnames(Q)[apply(Q != 0, 1, which.max)])
  expect_true(all(tab$n_loadings == 1L))
})

## --- S2-05 / S3-07: pid and case weights survive the streaming path --------

test_that("the streaming path keeps the caller's ids and weights", {
  d <- sq_sim(n = 500, J = 6, D = 2, seed = 7)
  set.seed(7); wt <- runif(nrow(d$resp), 0.5, 3)
  Q <- d$Q
  dimnames(Q) <- list(colnames(d$resp), c("DimA", "DimB"))
  dd <- data.frame(pid = seq_len(nrow(d$resp)) + 90000L, d$resp, wt = wt)
  m <- irtc(dd, model = "GPCM", q = Q, ndim = 2, id = "pid", weights = "wt",
            verbose = FALSE)
  expect_equal(as.character(irtc_results(m, resp = d$resp)$persons$person_id),
               as.character(dd$pid))
  ## weights normalized to mean 1, exactly as the grid engine reports them
  expect_equal(m$person$pweight, wt * nrow(d$resp) / sum(wt), tolerance = 1e-8)
  ## the person table now carries posterior standard errors too
  expect_true(all(c("SD.EAP.Dim1", "SD.EAP.Dim2") %in% colnames(m$person)))
  expect_true(all(m$person$SD.EAP.Dim1 > 0))
})

## --- S2-06: classical statistics honour the sampling weights ---------------

test_that("irtc_ctt weights difficulties and correlations", {
  d <- sq_sim(n = 700, J = 6, D = 1, seed = 13)
  set.seed(13); wt <- runif(nrow(d$resp), 0.5, 3)
  ct <- irtc_ctt(as.data.frame(d$resp), weights = wt)
  expect_equal(ct$items$pvalue,
               round(as.numeric(apply(d$resp, 2, function(x)
                 sum(wt * x) / sum(wt))), 4))
  expect_true(ct$weighted)
})

test_that("constant weights reproduce the unweighted statistics exactly", {
  d <- sq_sim(n = 400, J = 6, D = 1, seed = 17)
  plain <- irtc_ctt(as.data.frame(d$resp))
  const <- irtc_ctt(as.data.frame(d$resp), weights = rep(2, nrow(d$resp)))
  expect_equal(const$items$pvalue, plain$items$pvalue)
  expect_equal(const$items$discr, plain$items$discr)
  expect_equal(const$alpha, plain$alpha)
  ## and the unweighted values are still the plain ones
  expect_equal(plain$items$pvalue, round(as.numeric(colMeans(d$resp)), 4))
})

test_that("irtc() gives the IRT and the classical statistics one basis", {
  d <- sq_sim(n = 600, J = 6, D = 1, seed = 19)
  set.seed(19); wt <- runif(nrow(d$resp), 0.5, 3)
  dd <- data.frame(pid = seq_len(nrow(d$resp)), d$resp, wt = wt)
  m <- irtc(dd, model = "2PL", id = "pid", weights = "wt", verbose = FALSE)
  expect_true(m$usability$weighted_statistics)
  expect_equal(m$usability$ctt$items$pvalue,
               round(as.numeric(apply(d$resp, 2, function(x)
                 sum(wt * x) / sum(wt))), 4))
})

test_that("item fit honours case weights", {
  d <- sq_sim(n = 600, J = 6, D = 1, seed = 23)
  m <- irtc.mml.2pl(resp = d$resp, irtmodel = "2PL", ndim = 1, verbose = FALSE,
                    method = "grid")
  set.seed(23); wt <- runif(nrow(d$resp), 0.5, 3)
  plain <- irtc_itemfit(m, resp = d$resp, weights = NULL)
  const <- irtc_itemfit(m, resp = d$resp, weights = rep(3, nrow(d$resp)))
  weighted <- irtc_itemfit(m, resp = d$resp, weights = wt)
  expect_equal(const$infit, plain$infit)
  expect_equal(const$outfit, plain$outfit)
  expect_false(isTRUE(all.equal(weighted$infit, plain$infit)))
})

## --- S3-08: the grid path predicts an impossible allocation -----------------

test_that("the grid engine refuses a hopeless allocation with advice", {
  err <- tryCatch(
    irtc_grid_memory_guard(N = 85035, nnodes = 21^3, D = 3,
                           streaming_possible = TRUE, budget_gb = 16),
    error = function(e) e)
  expect_s3_class(err, "irtc_error")
  expect_equal(err$code, "E409")
  expect_match(err$fix_en, "streaming")
  expect_true(err$data$required_gb > 16)
  ## a model that does fit is left alone
  expect_null(irtc_grid_memory_guard(N = 1000, nnodes = 21, D = 1,
                                     budget_gb = 16))
})

## --- weighted helper arithmetic --------------------------------------------

test_that("the weighted helpers reduce to their stats:: counterparts", {
  set.seed(29)
  x <- rnorm(50); y <- rnorm(50); w1 <- rep(1, 50)
  expect_equal(irtc_weighted_mean(x, w1), mean(x))
  expect_equal(irtc_weighted_var(x, w1), var(x))
  expect_equal(irtc_weighted_cov2(x, y, w1), cov(x, y))
  expect_equal(irtc_weighted_cor(x, y, w1), cor(x, y))
  ## replicating a case twice must equal giving it weight 2
  idx <- c(seq_along(x), 1:10)
  expect_equal(irtc_weighted_mean(x[idx], rep(1, length(idx))),
               irtc_weighted_mean(x, c(rep(2, 10), rep(1, 40))))
  ## missing values are dropped pairwise
  xm <- x; xm[1] <- NA
  expect_equal(irtc_weighted_mean(xm, w1), mean(x[-1]))
})

test_that("case weights are validated", {
  err <- tryCatch(irtc_prep_case_weights(c(1, 2), 5), error = function(e) e)
  expect_equal(err$code, "E410")
  err2 <- tryCatch(irtc_prep_case_weights(c(1, -1, 2), 3), error = function(e) e)
  expect_equal(err2$code, "E410")
  expect_equal(irtc_prep_case_weights(NULL, 4), rep(1, 4))
})

## --- weighted norm-referenced person columns -------------------------------

test_that("percentile and t_score follow the sampling weights", {
  d <- sq_sim(n = 600, J = 6, D = 1, seed = 41)
  set.seed(41); wt <- runif(nrow(d$resp), 0.5, 3)
  dd <- data.frame(pid = seq_len(nrow(d$resp)), d$resp, wt = wt)
  m <- irtc(dd, model = "2PL", id = "pid", weights = "wt", verbose = FALSE)
  p <- irtc_results(m, resp = d$resp)$persons
  eap <- m$person$EAP
  ## the same normalization the function applies, so the comparison is exact
  ## rather than differing in the last rounded digit
  w <- IRTC:::irtc_prep_case_weights(m$pweights, length(eap))
  ## a percentile is the weighted share below, ties at half weight
  expect_equal(p$percentile, round(IRTC:::irtc_weighted_percentile(eap, w), 1))
  expect_equal(p$t_score, round(IRTC:::irtc_weighted_tscore(eap, w), 1))
  ## and it genuinely differs from the unweighted norm
  plain <- 100 * (rank(eap) - 0.5) / length(eap)
  expect_false(isTRUE(all.equal(p$percentile, round(plain, 1))))
  ## the weighted T score still has weighted mean 50 and weighted SD 10
  expect_equal(IRTC:::irtc_weighted_mean(p$t_score, w), 50, tolerance = 0.05)
  expect_equal(IRTC:::irtc_weighted_sd(p$t_score, w), 10, tolerance = 0.05)
})

test_that("unweighted person norms are unchanged", {
  d <- sq_sim(n = 400, J = 6, D = 1, seed = 43)
  dd <- data.frame(pid = seq_len(nrow(d$resp)), d$resp)
  m <- irtc(dd, model = "2PL", id = "pid", verbose = FALSE)
  p <- irtc_results(m, resp = d$resp)$persons
  eap <- m$person$EAP
  expect_equal(p$percentile, round(100 * (rank(eap) - 0.5) / length(eap), 1))
  expect_equal(p$t_score, round(50 + 10 * (eap - mean(eap)) / stats::sd(eap), 1))
})

test_that("the weighted percentile reduces to the unweighted rank, ties included", {
  v <- c(1, 2, 2, 2, 3, 5, 5)
  w1 <- rep(1, length(v))
  expect_equal(IRTC:::irtc_weighted_percentile(v, w1),
               100 * (rank(v) - 0.5) / length(v))
  ## giving a case weight 2 must equal listing it twice
  x <- c(1, 2, 2, 3, 5); xw <- c(2, 1, 1, 1, 1)
  xr <- c(1, 1, 2, 2, 3, 5)
  expect_equal(IRTC:::irtc_weighted_percentile(x, xw)[1],
               IRTC:::irtc_weighted_percentile(xr, rep(1, 6))[1])
  ## missing values stay missing and do not shift the others
  vn <- c(1, NA, 2, 3)
  got <- IRTC:::irtc_weighted_percentile(vn, rep(1, 4))
  expect_true(is.na(got[2]))
  expect_equal(got[-2], 100 * (rank(c(1, 2, 3)) - 0.5) / 3)
})

## --- answer keys are written in the data file's own category coding --------

test_that("a numeric answer key survives category recoding", {
  ## responses coded 1..4, the way a survey file actually stores them
  set.seed(53)
  raw <- data.frame(
    pid = 1:200,
    Q1 = sample(1:4, 200, TRUE),
    Q2 = sample(1:4, 200, TRUE),
    Q3 = sample(1:3, 200, TRUE))
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  utils::write.csv(raw, f, row.names = FALSE)

  d <- irtc_read(f, id = "pid", verbose = FALSE)
  ## irtc_read renumbers 1..4 to 0..3 but remembers the original categories
  expect_equal(d$recode_map$Q1, c(1, 2, 3, 4))
  expect_equal(sort(unique(d$resp$Q1)), c(0, 1, 2, 3))

  ## the key is written in the file's coding, not the renumbered one
  key <- c(Q1 = 2, Q2 = 4, Q3 = 1)
  scored <- irtc_score(d, key = key)
  expect_equal(as.numeric(scored$resp$Q1), as.numeric(raw$Q1 == 2))
  expect_equal(as.numeric(scored$resp$Q2), as.numeric(raw$Q2 == 4))
  expect_equal(as.numeric(scored$resp$Q3), as.numeric(raw$Q3 == 1))

  ## and the same key through irtc()
  m <- irtc(f, model = "2PL", key = key, id = "pid", verbose = FALSE)
  expect_equal(as.numeric(colMeans(m$resp)),
               as.numeric(c(mean(raw$Q1 == 2), mean(raw$Q2 == 4),
                            mean(raw$Q3 == 1))))
})

test_that("an answer nobody gave is reported instead of scoring everyone wrong", {
  set.seed(59)
  raw <- data.frame(pid = 1:150,
                    Q1 = sample(1:3, 150, TRUE),
                    Q2 = sample(1:3, 150, TRUE))
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  utils::write.csv(raw, f, row.names = FALSE)
  d <- irtc_read(f, id = "pid", verbose = FALSE)
  w <- tryCatch(irtc_score(d, key = c(Q1 = 9, Q2 = 1)),
                warning = function(e) e)
  expect_s3_class(w, "irtc_warning")
  expect_equal(w$code, "W205")
  expect_true("Q1" %in% names(w$data$unmatched))
})

test_that("scoring without irtc_read is unaffected", {
  ## a bare data frame was never recoded, so the key applies as given
  raw <- data.frame(Q1 = c(1, 2, 3), Q2 = c(3, 2, 1))
  got <- irtc_score(raw, key = c(Q1 = 2, Q2 = 2))
  expect_equal(as.numeric(got$Q1), c(0, 1, 0))
  expect_equal(as.numeric(got$Q2), c(0, 1, 0))
})

test_that("rid is recognised as a person id column", {
  set.seed(61)
  raw <- data.frame(rid = 5001:5100,
                    Q1 = sample(0:1, 100, TRUE),
                    Q2 = sample(0:1, 100, TRUE))
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  utils::write.csv(raw, f, row.names = FALSE)
  d <- irtc_read(f, verbose = FALSE)
  expect_equal(as.integer(d$pid), raw$rid)
  expect_equal(colnames(d$resp), c("Q1", "Q2"))
})

## --- person identifiers survive as text ------------------------------------

test_that("a round numeric id is not written in scientific notation", {
  ## as.character(266000000) is "2.66e+08"; ids like this occur in real
  ## survey files and silently corrupt the key used to join results back
  expect_equal(IRTC:::irtc_format_id(c(265150099, 266000000, 1e15 + 7)),
               c("265150099", "266000000", "1000000000000007"))
  expect_equal(IRTC:::irtc_format_id(c("a", "b")), c("a", "b"))
  expect_equal(IRTC:::irtc_format_id(c(1.5, 2.5)), c("1.5", "2.5"))

  set.seed(67)
  n <- 120
  raw <- data.frame(pid = c(266000000, 265150099, 2.5e8 + seq_len(n - 2)),
                    Q1 = sample(0:1, n, TRUE), Q2 = sample(0:1, n, TRUE),
                    Q3 = sample(0:1, n, TRUE), Q4 = sample(0:1, n, TRUE))
  m <- irtc(raw, model = "2PL", id = "pid", verbose = FALSE)
  got <- irtc_results(m)$persons$person_id
  expect_equal(got[1], "266000000")
  expect_false(any(grepl("e\\+", got)))
  expect_equal(irtc_person_table(m)[[1]][1], "266000000")
})

## --- the streaming engine keeps the data and the item names ---------------

test_that("a streaming fit carries its response data and item names", {
  d <- sq_sim(n = 500, J = 6, D = 2, seed = 71)
  Q <- d$Q
  dimnames(Q) <- list(colnames(d$resp), c("DimA", "DimB"))
  dd <- data.frame(pid = seq_len(nrow(d$resp)), d$resp)
  m <- irtc(dd, model = "GPCM", q = Q, ndim = 2, id = "pid", verbose = FALSE)

  ## item_id keys the cross-year linking workbook: generic I1..In would make a
  ## multidimensional export unusable for linking
  expect_equal(as.character(m$item$item), colnames(d$resp))
  expect_equal(dimnames(m$B)[[1]], colnames(d$resp))
  expect_equal(irtc_param_table(m)$item_id, colnames(d$resp))
  expect_false(anyNA(irtc_param_table(m)$p_value))

  ## and the enrichment functions no longer need resp= passed back in
  expect_false(is.null(m$resp))
  expect_s3_class(irtc_quality(m), "irtc_quality")
  expect_s3_class(irtc_itemfit(m), "irtc_itemfit")
  expect_equal(irtc_results(m)$items$item_id, colnames(d$resp))
})

## --- retrospective audit of archived analyses ------------------------------

audit_fixture <- function(seed = 79, n = 150) {
  set.seed(seed)
  raw <- data.frame(pid = seq_len(n),
                    Q1 = sample(1:4, n, TRUE), Q2 = sample(1:4, n, TRUE),
                    Q3 = sample(1:3, n, TRUE), Q4 = sample(1:3, n, TRUE))
  f <- tempfile(fileext = ".csv")
  utils::write.csv(raw, f, row.names = FALSE)
  f
}

test_that("a 1.1.2 fit that used a key audits clean", {
  f <- audit_fixture(); on.exit(unlink(f), add = TRUE)
  m <- irtc(f, model = "2PL", key = c(Q1 = 2, Q2 = 3, Q3 = 1, Q4 = 2),
            id = "pid", verbose = FALSE)
  a <- irtc_audit_scoring(m)
  expect_s3_class(a, "irtc_audit")
  expect_equal(a$status, "ok_fixed")
  expect_equal(a$n_scored, 4L)
  expect_length(a$affected_items, 0L)
})

test_that("an archived fit from before the fix is flagged with its items", {
  f <- audit_fixture(); on.exit(unlink(f), add = TRUE)
  m <- irtc(f, model = "2PL", key = c(Q1 = 2, Q2 = 3, Q3 = 1, Q4 = 2),
            id = "pid", verbose = FALSE)
  archived <- m
  archived$usability$package_version <- "1.1.1"
  a <- irtc_audit_scoring(archived)
  expect_equal(a$status, "affected")
  expect_setequal(a$affected_items, c("Q1", "Q2", "Q3", "Q4"))
  expect_true(all(a$items$categories_renumbered))
  expect_equal(a$items$original_categories[1], "1,2,3,4")
})

test_that("an unstamped object is reported as at risk, not as broken", {
  f <- audit_fixture(); on.exit(unlink(f), add = TRUE)
  m <- irtc(f, model = "2PL", key = c(Q1 = 2, Q2 = 3, Q3 = 1, Q4 = 2),
            id = "pid", verbose = FALSE)
  legacy <- m
  legacy$usability$package_version <- NULL
  legacy$usability$recode_map <- NULL
  a <- irtc_audit_scoring(legacy)
  expect_equal(a$status, "affected_if_before_1.1.2")
  expect_setequal(a$affected_items, c("Q1", "Q2", "Q3", "Q4"))
})

test_that("an analysis on already-scored data is never flagged", {
  set.seed(83); n <- 150
  sc <- data.frame(pid = seq_len(n), Q1 = rbinom(n, 1, .5), Q2 = rbinom(n, 1, .5),
                   Q3 = rbinom(n, 1, .5), Q4 = rbinom(n, 1, .5))
  m <- irtc(sc, model = "2PL", id = "pid", verbose = FALSE)
  a <- irtc_audit_scoring(m)
  expect_equal(a$status, "not_scored")
  ## even if it had come from an old version
  old <- m; old$usability$package_version <- "1.1.0"
  expect_equal(irtc_audit_scoring(old)$status, "not_scored")
})

test_that("a key on already-0-based items is not flagged", {
  set.seed(89); n <- 150
  raw <- data.frame(pid = seq_len(n),
                    Q1 = sample(0:3, n, TRUE), Q2 = sample(0:3, n, TRUE),
                    Q3 = sample(0:2, n, TRUE), Q4 = sample(0:2, n, TRUE))
  f <- tempfile(fileext = ".csv"); on.exit(unlink(f), add = TRUE)
  utils::write.csv(raw, f, row.names = FALSE)
  m <- irtc(f, model = "2PL", key = c(Q1 = 1, Q2 = 2, Q3 = 1, Q4 = 0),
            id = "pid", verbose = FALSE)
  old <- m; old$usability$package_version <- "1.1.1"
  expect_equal(irtc_audit_scoring(old)$status, "not_affected")
})

test_that("the audit accepts every artefact a project is likely to keep", {
  f <- audit_fixture(); on.exit(unlink(f), add = TRUE)
  m <- irtc(f, model = "2PL", key = c(Q1 = 2, Q2 = 3, Q3 = 1, Q4 = 2),
            id = "pid", verbose = FALSE)
  expect_s3_class(irtc_audit_scoring(irtc_results(m)), "irtc_audit")
  d <- irtc_score(irtc_read(f, id = "pid", verbose = FALSE),
                  key = c(Q1 = 2, Q2 = 3, Q3 = 1, Q4 = 2))
  expect_equal(irtc_audit_scoring(d)$status, "ok_fixed")
  ## a bare cleaning log, all that survives inside an exported workbook
  lg <- irtc_audit_scoring(m$usability$data_log)
  expect_equal(lg$status, "affected_if_before_1.1.2")
  err <- tryCatch(irtc_audit_scoring(42), error = function(e) e)
  expect_equal(err$code, "E411")
})

## --- printing and defensive branches ---------------------------------------

test_that("the audit prints a verdict in both languages for every status", {
  f <- audit_fixture(seed = 91); on.exit(unlink(f), add = TRUE)
  m <- irtc(f, model = "2PL", key = c(Q1 = 2, Q2 = 3, Q3 = 1, Q4 = 2),
            id = "pid", verbose = FALSE)

  fixed <- m
  legacy <- m; legacy$usability$package_version <- NULL
  legacy$usability$recode_map <- NULL
  archived <- m; archived$usability$package_version <- "1.1.1"

  set.seed(93); n <- 120
  sc <- data.frame(pid = seq_len(n), Q1 = rbinom(n, 1, .5), Q2 = rbinom(n, 1, .5),
                   Q3 = rbinom(n, 1, .5), Q4 = rbinom(n, 1, .5))
  unscored <- irtc(sc, model = "2PL", id = "pid", verbose = FALSE)

  set.seed(95)
  zero_based <- data.frame(pid = seq_len(n),
                           Q1 = sample(0:3, n, TRUE), Q2 = sample(0:3, n, TRUE),
                           Q3 = sample(0:2, n, TRUE), Q4 = sample(0:2, n, TRUE))
  f0 <- tempfile(fileext = ".csv"); on.exit(unlink(f0), add = TRUE)
  utils::write.csv(zero_based, f0, row.names = FALSE)
  m0 <- irtc(f0, model = "2PL", key = c(Q1 = 1, Q2 = 2, Q3 = 1, Q4 = 0),
             id = "pid", verbose = FALSE)
  m0$usability$package_version <- "1.1.1"

  cases <- list(ok_fixed = fixed, affected = archived,
                affected_if_before_1.1.2 = legacy,
                not_scored = unscored, not_affected = m0)
  for (nm in names(cases)) {
    a <- irtc_audit_scoring(cases[[nm]])
    expect_equal(a$status, nm)
    for (lg in c("en", "zh")) {
      out <- utils::capture.output(print(a, lang = lg))
      expect_true(length(out) > 2, info = paste(nm, lg))
      expect_true(any(nzchar(out)), info = paste(nm, lg))
    }
  }
})

test_that("irtc_ctt prints, flags weighting, and rejects bad input", {
  d <- sq_sim(n = 200, J = 5, D = 1, seed = 97)
  plain <- utils::capture.output(print(irtc_ctt(as.data.frame(d$resp)),
                                       lang = "en"))
  expect_false(any(grepl("case-weighted", plain)))
  wtd <- utils::capture.output(
    print(irtc_ctt(as.data.frame(d$resp), weights = runif(200, .5, 2)),
          lang = "en"))
  expect_true(any(grepl("case-weighted", wtd)))
  ## a fitted model is an accepted input; anything else is a coded error
  m <- irtc(as.data.frame(d$resp), model = "2PL", verbose = FALSE)
  expect_s3_class(irtc_ctt(m), "irtc_ctt")
  err <- tryCatch(irtc_ctt(42), error = function(e) e)
  expect_equal(err$code, "E301")
})

test_that("alpha falls back to complete cases and copes with degenerate input", {
  ## a pair of items never answered together makes the pairwise covariance
  ## matrix incomplete, so the complete-case fallback has to take over
  x <- matrix(NA_real_, 40, 3)
  x[1:20, 1] <- rbinom(20, 1, .5); x[1:20, 3] <- rbinom(20, 1, .5)
  x[21:40, 2] <- rbinom(20, 1, .5); x[21:40, 3] <- rbinom(20, 1, .5)
  colnames(x) <- c("A", "B", "C")
  expect_true(is.na(IRTC:::irtc_ctt_alpha(x)))
  ## a single item cannot have an alpha
  expect_true(is.na(IRTC:::irtc_ctt_alpha(x[, 1, drop = FALSE])))
  ## zero total variance is not an alpha either
  const <- matrix(1, 30, 3, dimnames = list(NULL, c("A", "B", "C")))
  expect_true(is.na(IRTC:::irtc_ctt_alpha(const)))
})

test_that("the weighted helpers survive degenerate input", {
  ## a single weight is recycled to every case
  expect_equal(IRTC:::irtc_prep_case_weights(3, 4), rep(1, 4))
  ## nothing observed, or no weight on what is observed
  expect_true(is.na(IRTC:::irtc_weighted_mean(rep(NA_real_, 5), rep(1, 5))))
  expect_true(is.na(IRTC:::irtc_weighted_mean(c(1, 2), c(0, 0))))
  ## fewer than two usable pairs gives no covariance
  expect_true(is.na(IRTC:::irtc_weighted_cov2(c(1, NA), c(NA, 2), c(1, 1))))
  expect_true(is.na(IRTC:::irtc_weighted_cov2(c(1, 2), c(1, 2), c(0.2, 0.2))))
  ## a constant vector has no correlation with anything
  expect_true(is.na(IRTC:::irtc_weighted_cor(c(1, 1, 1), c(1, 2, 3), rep(1, 3))))
  expect_true(is.na(IRTC:::irtc_weighted_sd(c(1, NA), c(NA, 2))))
  ## percentiles: all missing, and no usable weight
  expect_true(all(is.na(IRTC:::irtc_weighted_percentile(rep(NA_real_, 4),
                                                        rep(1, 4)))))
  expect_true(all(is.na(IRTC:::irtc_weighted_percentile(c(1, 2), c(0, 0)))))
  ## a constant vector has no T score
  expect_true(all(is.na(IRTC:::irtc_weighted_tscore(rep(2, 5), rep(1, 5)))))
  ## non-numeric ids are passed through untouched
  expect_equal(IRTC:::irtc_format_id(c("S1", "S2")), c("S1", "S2"))
})
