# Parallel E-step must be deterministic: thread count does not change results.

test_that("irtc.mml.2pl is identical for 1 vs 2 threads (multidim)", {
  data(data.sim.rasch)
  set.seed(1)
  resp <- data.sim.rasch[sample(seq_len(nrow(data.sim.rasch)), 800), 1:20]
  Q <- matrix(0, 20, 2); Q[1:10, 1] <- 1; Q[11:20, 2] <- 1
  m1 <- irtc.mml.2pl(resp = resp, irtmodel = "2PL", Q = Q, method = "grid",
                     control = list(n_threads = 1, nodes = seq(-4, 4, len = 11)),
                     verbose = FALSE)
  m2 <- irtc.mml.2pl(resp = resp, irtmodel = "2PL", Q = Q, method = "grid",
                     control = list(n_threads = 2, nodes = seq(-4, 4, len = 11)),
                     verbose = FALSE)
  expect_equal(as.numeric(m1$xsi$xsi), as.numeric(m2$xsi$xsi), tolerance = 1e-12)
  expect_equal(as.numeric(m1$B),        as.numeric(m2$B),        tolerance = 1e-12)
  expect_equal(m1$deviance,             m2$deviance,             tolerance = 1e-12)
})

test_that("irtc.mml is identical for 1 vs 2 threads", {
  data(data.sim.rasch)
  m1 <- irtc.mml(resp = data.sim.rasch, control = list(n_threads = 1), verbose = FALSE)
  m2 <- irtc.mml(resp = data.sim.rasch, control = list(n_threads = 2), verbose = FALSE)
  expect_equal(as.numeric(m1$xsi$xsi), as.numeric(m2$xsi$xsi), tolerance = 1e-12)
  expect_equal(m1$deviance, m2$deviance, tolerance = 1e-12)
})

test_that("thread control is capped at two", {
  e <- new.env(parent = emptyenv())
  IRTC:::irtc_mml_control_list_define(
    control = list(n_threads = 64L), envir = e,
    irtc_fct = "irtc.mml", prior_list_xsi = NULL
  )
  expect_equal(e$n_threads, 2L)
})
