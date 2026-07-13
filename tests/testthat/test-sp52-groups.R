# The grid engine does not support multidimensional multiple-group models, so
# the streaming engine (which adds this capability) is validated by ground-truth
# recovery: reference group ~ N(0, corr); other groups have free mean and variance.
test_that("multiple groups: recover group-2 mean shift and item slopes; small group PD with shrinkage", {
  set.seed(4); N <- 8000; I <- 16; D <- 2; maxK <- 2
  grp <- rep(1:2, length.out = N)
  dim_of <- rep(1:2, length.out = I)
  shift <- c(0.5, -0.3)
  th <- matrix(rnorm(N * 2), N, 2)
  th[grp == 2, ] <- sweep(th[grp == 2, ], 2, shift, "+")
  a <- runif(I, 0.8, 1.6); b <- rnorm(I)
  resp <- matrix(0L, N, I)
  for (j in 1:I) resp[, j] <- as.integer(plogis(a[j] * (th[, dim_of[j]] - b[j])) > runif(N))

  obj <- IRTC:::irtc_proto_run_and_build(resp, dim_of, maxK = 2, Q = 21, group = grp,
                                         maxiter = 80)
  expect_true(is.list(obj$variance) && length(obj$variance) == 2)
  expect_equal(as.numeric(obj$gmean[2, ]), shift, tolerance = 0.15)   # mean shift recovered
  expect_gt(cor(obj$a, a), 0.95)                                       # item slopes recovered

  # tiny group + pooled shrinkage -> per-group Sigma stays PD
  grp2 <- grp; grp2[1:25] <- 3L
  obj2 <- IRTC:::irtc_proto_run_and_build(resp, dim_of, maxK = 2, Q = 21, group = grp2,
            reg = list(sigma_shrink_pooled = 0.3), maxiter = 40)
  for (S in obj2$variance) expect_true(all(eigen(S, symmetric = TRUE)$values > 0))
})
