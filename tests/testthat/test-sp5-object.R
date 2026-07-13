test_that("engine result is a working irtc object", {
  d <- sp4_simulate(N = 3000, I = 12, D = 2, maxK = 2, seed = 1)
  obj <- IRTC:::irtc_proto_run_and_build(d$resp, d$dim_of, maxK = 2, Q = 21)
  expect_s3_class(obj, "irtc")
  expect_output(print(obj))
  invisible(capture.output(summary(obj)))
  expect_true(is.finite(as.numeric(logLik(obj))))
  expect_equal(attr(logLik(obj), "df"), obj$ic$Npars)
})

test_that("engine object agrees with irtc.mml.2pl on item slopes and latent correlation", {
  d <- sp4_simulate(N = 5000, I = 16, D = 2, maxK = 2, seed = 7)
  Q <- matrix(0, 16, 2); for (j in 1:16) Q[j, d$dim_of[j]] <- 1
  ref <- irtc.mml.2pl(resp = d$resp, irtmodel = "2PL", Q = Q, est.variance = TRUE,
                      control = list(nodes = seq(-6, 6, len = 21)), verbose = FALSE)
  obj <- IRTC:::irtc_proto_run_and_build(d$resp, d$dim_of, maxK = 2, Q = 21)
  ref_a <- apply(ref$B, 1, function(z) z[which.max(abs(z))])
  expect_gt(cor(obj$a, ref_a), 0.99)
  expect_equal(obj$variance[1, 2], cov2cor(ref$variance)[1, 2], tolerance = 0.02)
})
