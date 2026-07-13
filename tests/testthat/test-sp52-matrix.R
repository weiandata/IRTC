test_that("unique-pattern bucketing is lossless (cache consistency)", {
  set.seed(1)
  mu <- matrix(sample(c(-0.5, 0, 0.5), 200 * 2, replace = TRUE), 200, 2)
  grp <- rep(0:1, length.out = 200)
  patt <- IRTC:::irtc_proto_build_patterns(mu, grp)
  expect_lt(nrow(patt$mu), 50)                              # discrete -> few patterns
  expect_equal(patt$mu[patt$pattern + 1L, ], mu)            # reconstruction exact
  expect_equal(patt$group[patt$pattern + 1L], grp)
})

test_that("weight prep: extreme weights warn; n_eff reported and < N; negatives error", {
  w <- c(rep(1, 999), 200)
  expect_warning(p <- IRTC:::irtc_proto_prep_weights(w, 1000), "extreme")
  expect_true(is.finite(p$n_eff) && p$n_eff < 1000)
  expect_error(IRTC:::irtc_proto_prep_weights(c(-1, rep(1, 9)), 10))
})

test_that("GLS warns on collinear covariates and still returns finite beta", {
  set.seed(2); N <- 500
  x <- rnorm(N); Y <- cbind(1, x, x)                       # duplicated column
  Et <- matrix(rnorm(N * 2), N, 2)
  expect_warning(b <- IRTC:::irtc_proto_gls_beta(Y, Et, rep(1, N)), "collinear")
  expect_true(all(is.finite(b)))
})

test_that("Sigma uses full posterior moments (EAP reliability < 1, not EAP-as-observed)", {
  set.seed(3); N <- 4000; I <- 16; D <- 2
  xcov <- rnorm(N); Y <- cbind(1, xcov)
  th <- Y %*% matrix(c(0, 0.5, 0, -0.3), 2, 2) + matrix(rnorm(N * 2), N, 2)
  dim_of <- rep(1:2, length.out = I); a <- runif(I, 0.8, 1.5); b <- rnorm(I)
  resp <- matrix(0L, N, I)
  for (j in 1:I) resp[, j] <- as.integer(plogis(a[j] * (th[, dim_of[j]] - b[j])) > runif(N))
  obj <- IRTC:::irtc_proto_run_and_build(resp, dim_of, maxK = 2, Q = 21, Y = Y, maxiter = 50)
  # full-moment Sigma identifies the scale (diag = 1) while EAPs are shrunken, so
  # EAP reliability = var(EAP)/diag(Sigma) is clearly < 1. If Sigma had been built
  # from EAP-as-observed, this ratio would be ~1.
  expect_true(all(diag(obj$variance) == 1))
  expect_true(all(obj$EAP.rel < 0.95))
})
