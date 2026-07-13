test_that("kernel node-occupancy sums to the weighted person count", {
  d <- sp4_simulate(N = 1500, I = 10, D = 2, maxK = 2, seed = 1)
  storage.mode(d$resp) <- "integer"
  x <- seq(-5, 5, len = 13); Q <- 13L; D <- 2L; maxK <- 2L
  gc0 <- as.matrix(do.call(expand.grid, rep(list(0:(Q-1L)), D))); storage.mode(gc0) <- "integer"
  gridx <- matrix(x[gc0 + 1L], nrow(gc0), D)
  gwm <- matrix(IRTC:::.mvn_density(gridx, diag(2)), ncol = 1)
  probs <- numeric(10 * maxK * Q)
  for (j in 1:10) { Pj <- IRTC:::irtc_proto_item_probs(1, 0, x, maxK)
    for (cc in 1:maxK) probs[((j-1)*maxK + (cc-1))*Q + 1:Q] <- Pj[, cc] }
  dimj0 <- as.integer(d$dim_of - 1L)
  E <- irtc_rcpp_proto_estep(d$resp, dimj0, probs, gc0, gwm, integer(1500), rep(1, 1500),
                             integer(1500), 1L, x, Q, maxK, 1L, 0L, 1L)   # want_nodeocc=1
  expect_equal(length(E$nodeocc), nrow(gc0))
  expect_equal(sum(E$nodeocc), 1500, tolerance = 1e-8)   # each person's posterior sums to 1
})
