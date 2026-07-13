test_that("extreme responders: pruning preserves their EAPs (prior+posterior keep tails)", {
  d <- sp4_simulate(N = 4000, I = 16, D = 2, maxK = 2, seed = 31)
  d$resp[1:50, ] <- 0L; d$resp[51:100, ] <- 1L                       # near-0 / near-perfect
  full <- IRTC:::irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21, want_eap = TRUE)
  fast <- IRTC:::irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21,
                                     fast = TRUE, mass_budget = 1e-3)
  ext <- 1:100
  ef <- IRTC:::irtc_proto_estep_at(d$resp[ext, ], d$dim_of, full, Q = 21, maxK = 2, keep = NULL)
  ep <- IRTC:::irtc_proto_estep_at(d$resp[ext, ], d$dim_of, full, Q = 21, maxK = 2, keep = fast$keep)
  expect_lt(max(abs(ep$eap - ef$eap)), 5e-2)                         # extreme EAPs not distorted
})

test_that("posterior moments (variance/covariance) stay safe under pruning", {
  d <- sp4_simulate(N = 4000, I = 16, D = 2, maxK = 2, seed = 32)
  full <- IRTC:::irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21)
  fast <- IRTC:::irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21,
                                     fast = TRUE, mass_budget = 1e-3)
  expect_lt(max(abs(fast$Sigma - full$Sigma)), 2e-2)                 # incl. off-diagonal cov
})

test_that("a small special group is not masked under fast mode", {
  set.seed(33); N <- 6000; I <- 16; dim_of <- rep(1:2, length.out = I)
  grp <- rep(1L, N); grp[1:60] <- 2L                                 # 60-person special group
  th <- matrix(rnorm(N * 2), N, 2); th[grp == 2L, ] <- th[grp == 2L, ] + 0.8   # shifted
  a <- runif(I, 0.8, 1.5); b <- rnorm(I); resp <- matrix(0L, N, I)
  for (j in 1:I) resp[, j] <- as.integer(plogis(a[j] * (th[, dim_of[j]] - b[j])) > runif(N))
  full <- IRTC:::irtc_mml_fast_proto(resp, dim_of, maxK = 2, Q = 21, group = grp)
  fast <- IRTC:::irtc_mml_fast_proto(resp, dim_of, maxK = 2, Q = 21, group = grp,
                                     fast = TRUE, mass_budget = 1e-3)
  expect_equal(as.numeric(fast$gmean[2, ]), as.numeric(full$gmean[2, ]), tolerance = 0.1)
})

test_that("an over-aggressive budget is reported as not met", {
  d <- sp4_simulate(N = 4000, I = 16, D = 2, maxK = 2, seed = 34)
  bad <- IRTC:::irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21,
                                    fast = TRUE, mass_budget = 0.3)
  rep_bad <- suppressWarnings(IRTC:::irtc_proto_verify(d$resp, d$dim_of, bad, Q = 21, maxK = 2,
              verify_n = 1200, verify_seed = 1,
              tol = list(deviance = 1e-4, eap = 1e-3, moment = 1e-3, par = 1e-3)))
  expect_false(rep_bad$met)
})
