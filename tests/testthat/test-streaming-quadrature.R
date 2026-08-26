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
