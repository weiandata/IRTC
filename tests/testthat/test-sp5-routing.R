test_that("router picks engines by predicted speed, not memory", {
  # unidim small -> grid
  r1 <- irtc_route_decide("auto", N=2000, I=20, D=1, Q=21, maxK=2, TRUE, FALSE)
  expect_equal(r1$engine, "grid")
  # large 4-dim -> streaming
  r2 <- irtc_route_decide("auto", N=1e5, I=300, D=4, Q=15, maxK=4, TRUE, FALSE)
  expect_equal(r2$engine, "streaming")
  # high memory budget but large multidim -> still streaming (the mispick guard)
  r3 <- irtc_route_decide("auto", N=2e5, I=300, D=3, Q=21, maxK=4, TRUE, FALSE,
                          mem_budget_gb = 64)
  expect_equal(r3$engine, "streaming")
  expect_gt(r3$predicted_speedup, 5)
  # covariates are now SUPPORTED by streaming (SP5.2) -> large covariate model streams
  r4 <- irtc_route_decide("auto", N=1e5, I=300, D=4, Q=15, maxK=4, TRUE, has_covariates=TRUE)
  expect_equal(r4$engine, "streaming")
  # within-item / non-simple structure -> grid; explicit streaming on it errors
  r5 <- irtc_route_decide("auto", N=1e5, I=300, D=4, Q=15, maxK=4, simple_structure=FALSE)
  expect_equal(r5$engine, "grid"); expect_true(r5$fell_back)
  expect_error(irtc_route_decide("streaming", N=1e5, I=300, D=4, Q=15, maxK=4,
                                 simple_structure=FALSE))
})
