test_that("fast mode prunes nodes, converges near full grid, and default stays bit-exact", {
  d <- sp4_simulate(N = 4000, I = 14, D = 2, maxK = 2, seed = 2)
  full <- IRTC:::irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21)            # default exact
  fast <- IRTC:::irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21,
                                     fast = TRUE, mass_budget = 1e-3)
  expect_equal(fast$a, full$a, tolerance = 5e-3)                 # fast ~ full
  expect_lt(fast$nodes_kept, 21^2)                               # actually pruned
  full2 <- IRTC:::irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21)
  expect_equal(full$a, full2$a, tolerance = 1e-12)              # default deterministic/bit-exact
})
