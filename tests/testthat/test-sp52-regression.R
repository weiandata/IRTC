test_that("latent regression recovers a true effect and matches grid", {
  set.seed(11)
  N <- 6000; I <- 16; D <- 2; maxK <- 2
  xcov <- rnorm(N)
  Y <- cbind(1, xcov)
  beta_true <- matrix(c(0, 0.6, 0, -0.4), 2, 2)         # dim1: +0.6*x, dim2: -0.4*x
  Sig <- matrix(0.3, 2, 2); diag(Sig) <- 1
  dim_of <- rep(1:2, length.out = I)
  th <- Y %*% beta_true + matrix(rnorm(N * 2), N, 2) %*% chol(Sig)
  a <- runif(I, 0.8, 1.6); b <- rnorm(I)
  resp <- matrix(0L, N, I)
  for (j in 1:I) resp[, j] <- as.integer(plogis(a[j] * (th[, dim_of[j]] - b[j])) > runif(N))
  Qm <- matrix(0, I, 2); for (j in 1:I) Qm[j, dim_of[j]] <- 1

  obj <- IRTC:::irtc_proto_run_and_build(resp, dim_of, maxK = 2, Q = 21, Y = Y, maxiter = 60)
  ref <- irtc.mml.2pl(resp = resp, irtmodel = "2PL", Q = Qm, Y = Y, method = "grid",
                      control = list(nodes = seq(-6, 6, len = 21)), verbose = FALSE)

  # the xcov slope is the last regression row in each engine (intercept is a
  # location convention: grid anchors it to 0, streaming lets it float).
  obj_slope <- obj$beta[nrow(obj$beta), ]
  ref_slope <- ref$beta[nrow(ref$beta), ]
  expect_equal(as.numeric(obj_slope), as.numeric(beta_true[2, ]), tolerance = 0.1)  # recovery
  expect_equal(as.numeric(obj_slope), as.numeric(ref_slope), tolerance = 3e-2)      # vs grid
})
