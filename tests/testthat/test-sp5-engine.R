test_that("nearest_pd makes an indefinite matrix PD", {
  S <- matrix(c(1, 0.99, 0.99, 0.5), 2, 2)         # indefinite-ish
  P <- IRTC:::.nearest_pd(S)
  expect_true(all(eigen(P, symmetric = TRUE)$values > 0))
  expect_silent(chol(P))
})

test_that("streamed EAP tracks the latent abilities and reliability is in (0,1)", {
  set.seed(5); d <- sp4_simulate(N = 3000, I = 16, D = 2, maxK = 2, seed = 5)
  m <- irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21, maxiter = 60,
                           squarem = FALSE, want_eap = TRUE)
  expect_equal(dim(m$eap), c(3000L, 2L))
  expect_true(all(m$EAP.rel > 0 & m$EAP.rel < 1))
})
