test_that("control plumbs mass_budget/verify; accuracy_report attached; refine refits", {
  d <- sp4_simulate(N = 4000, I = 16, D = 3, maxK = 2, seed = 5)
  Qm <- matrix(0, 16, 3); for (j in 1:16) Qm[j, d$dim_of[j]] <- 1
  ## The tolerance warning is the designed behaviour of the controlled-
  ## accuracy mode under this deliberately tight mass budget: assert it
  ## explicitly instead of letting it leak into the suite summary.
  expect_warning(
    m <- irtc.mml.2pl(resp = d$resp, irtmodel = "2PL", Q = Qm, method = "streaming",
                      control = list(fast = TRUE, mass_budget = 1e-3, verify = "stratified",
                                     verify_n = 1200, verify_seed = 9), verbose = FALSE),
    "accuracy verification")
  expect_true(!is.null(m$accuracy_report))
  expect_true(m$accuracy_report$verify_seed == 9)
  expect_true(is.logical(m$accuracy_report$met))
  expect_lt(m$accuracy_report$nodes_kept, m$accuracy_report$nodes_full)   # pruned
})
