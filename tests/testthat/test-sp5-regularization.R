test_that("regularization is off by default and flagged when on", {
  d <- sp4_simulate(N = 3000, I = 12, D = 2, maxK = 2, seed = 1)
  base <- IRTC:::irtc_proto_run_and_build(d$resp, d$dim_of, maxK = 2, Q = 21)
  expect_false(isTRUE(base$regularization$active))            # off by default
  reg <- IRTC:::irtc_proto_run_and_build(d$resp, d$dim_of, maxK = 2, Q = 21,
            reg = list(slope_penalty = 0.5, sigma_shrink = 0.1))
  expect_true(isTRUE(reg$regularization$active))
  expect_true(max(abs(reg$a - base$a)) > 1e-3)               # objective changed
})
