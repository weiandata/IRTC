test_that("covariate/group/weight models route to streaming when large; NA inputs error", {
  # discrete covariates -> few unique patterns -> streaming for a large model
  r <- irtc_route_decide("auto", N = 2e5, I = 200, D = 3, Q = 15, maxK = 2,
                         simple_structure = TRUE, has_covariates = TRUE, n_patterns = 200)
  expect_equal(r$engine, "streaming")

  # NA in pweights on a streaming-bound model -> clear error
  data(data.sim.rasch)
  expect_error(
    irtc.mml.2pl(resp = data.sim.rasch, irtmodel = "2PL",
                 pweights = c(NA, rep(1, nrow(data.sim.rasch) - 1)),
                 method = "streaming", verbose = FALSE),
    "missing")
})
