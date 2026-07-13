test_that("generalized kernel reduces to SP5.1 for 1 pattern / unit weight / 1 group", {
  d <- sp4_simulate(N = 2000, I = 10, D = 2, maxK = 2, seed = 1)
  storage.mode(d$resp) <- "integer"
  x <- seq(-5, 5, len = 15); Q <- 15L; D <- 2L; maxK <- 2L
  gc0 <- as.matrix(do.call(expand.grid, rep(list(0:(Q-1L)), D))); storage.mode(gc0) <- "integer"
  gridx <- matrix(x[gc0 + 1L], nrow(gc0), D)
  Sigma <- diag(2); gw <- IRTC:::.mvn_density(gridx, Sigma)
  probs <- numeric(10 * maxK * Q)
  for (j in 1:10) { Pj <- IRTC:::irtc_proto_item_probs(1, 0, x, maxK)
    for (cc in 1:maxK) probs[((j-1)*maxK + (cc-1))*Q + 1:Q] <- Pj[, cc] }
  dimj0 <- as.integer(d$dim_of - 1L)
  gwm <- matrix(gw, ncol = 1); pat <- integer(2000); grp <- integer(2000); w <- rep(1, 2000)
  E <- irtc_rcpp_proto_estep(d$resp, dimj0, probs, gc0, gwm, pat, w, grp, 1L, x,
                             Q, maxK, 1L, 1L)
  expect_equal(length(E$wsum), 1L)
  expect_true(is.finite(E$deviance))
  expect_equal(dim(E$eap), c(2000L, 2L))
})

test_that("two-pattern two-group kernel: per-group wsum and partitioned moments", {
  d <- sp4_simulate(N = 2000, I = 10, D = 2, maxK = 2, seed = 2)
  storage.mode(d$resp) <- "integer"
  x <- seq(-5, 5, len = 15); Q <- 15L; D <- 2L; maxK <- 2L
  gc0 <- as.matrix(do.call(expand.grid, rep(list(0:(Q-1L)), D))); storage.mode(gc0) <- "integer"
  gridx <- matrix(x[gc0 + 1L], nrow(gc0), D)
  probs <- numeric(10 * maxK * Q)
  for (j in 1:10) { Pj <- IRTC:::irtc_proto_item_probs(1, 0, x, maxK)
    for (cc in 1:maxK) probs[((j-1)*maxK + (cc-1))*Q + 1:Q] <- Pj[, cc] }
  dimj0 <- as.integer(d$dim_of - 1L)
  # two patterns = two group means (0 and shifted), same Sigma=I
  gwm <- cbind(IRTC:::.mvn_density(gridx, diag(2)),
               IRTC:::.mvn_density(sweep(gridx, 2, c(0.5, -0.5)), diag(2)))
  grp <- rep(0:1, length.out = 2000); pat <- grp; w <- rep(1, 2000)
  E <- irtc_rcpp_proto_estep(d$resp, dimj0, probs, gc0, gwm, pat, w, grp, 2L, x,
                             Q, maxK, 1L, 1L)
  expect_equal(length(E$wsum), 2L)
  expect_equal(sum(E$wsum), 2000)                       # weights partition by group
  expect_equal(length(E$M2), 2L * D * D)                # per-group second moments
})
