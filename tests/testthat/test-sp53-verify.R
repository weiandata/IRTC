test_that("verify samples strata incl. high-weight, reports quantiles, catches bad prune", {
  d <- sp4_simulate(N = 5000, I = 16, D = 2, maxK = 2, seed = 3)
  pw <- rep(1, 5000); pw[1:10] <- 40                              # a few high-weight persons
  fit <- IRTC:::irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21,
                                    fast = TRUE, mass_budget = 1e-3, pweights = pw)
  rep_ok <- IRTC:::irtc_proto_verify(d$resp, d$dim_of, fit, Q = 21, maxK = 2,
              pweights = pw, verify_n = 1500, verify_seed = 7,
              tol = list(deviance = 1e-3, eap = 1e-2, moment = 1e-2, par = 1e-2))
  expect_true(all(c("deviance_rel", "eap_abs", "moment_abs", "par_change") %in% names(rep_ok)))
  expect_named(rep_ok$eap_abs, c("median", "p95", "max"))         # quantiles, not just max
  expect_true(any(rep_ok$strata == "high_weight"))               # high-weight stratum present

  # an over-aggressive budget should fail the verdict
  bad <- IRTC:::irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21,
                                    fast = TRUE, mass_budget = 0.2)
  rep_bad <- suppressWarnings(IRTC:::irtc_proto_verify(d$resp, d$dim_of, bad, Q = 21, maxK = 2,
              verify_n = 1500, verify_seed = 7,
              tol = list(deviance = 1e-4, eap = 1e-3, moment = 1e-3, par = 1e-3)))
  expect_false(rep_bad$met)
})
