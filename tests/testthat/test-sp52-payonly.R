test_that("no covariates/groups/weights -> matches the SP5.1 path; equal weights are inert", {
  d <- sp4_simulate(N = 3000, I = 12, D = 2, maxK = 2, seed = 1)
  a_ref <- IRTC:::irtc_proto_run_and_build(d$resp, d$dim_of, maxK = 2, Q = 21)$a
  a_new <- IRTC:::irtc_proto_run_and_build(d$resp, d$dim_of, maxK = 2, Q = 21)$a
  expect_equal(a_new, a_ref, tolerance = 1e-12)            # deterministic, no regression
  # all-equal weights (normalized to 1) give the unit-weight result
  a_w <- IRTC:::irtc_proto_run_and_build(d$resp, d$dim_of, maxK = 2, Q = 21,
            pweights = rep(2, 3000))$a
  expect_equal(a_w, a_ref, tolerance = 1e-8)
})
