test_that("calibrated keep retains high-mass nodes, unions across patterns, protects tails", {
  set.seed(1); TP <- 400; ax <- seq(-8, 8, len = TP)
  gw <- matrix(c(dnorm(ax),                                         # pattern A: centered
                 dnorm(ax, mean = 3)), TP, 2)                       # pattern B: shifted
  postocc <- dnorm(ax, mean = -3.5)                                 # extreme responders, left tail
  keep <- IRTC:::irtc_calibrate_keep(gw, counts = c(900, 100), postocc = postocc, eps = 0.02)
  expect_true(length(keep) < TP)                                    # far corners (no mass) pruned
  expect_true(which.max(gw[, 1]) %in% keep)                         # pattern A peak kept
  expect_true(which.max(gw[, 2]) %in% keep)                         # pattern B peak kept (union)
  expect_true(which.max(postocc) %in% keep)                        # extreme-tail node kept (posterior)
})
