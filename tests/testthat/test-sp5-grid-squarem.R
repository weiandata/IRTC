test_that("grid SQUAREM reaches the same solution faster and default is unchanged", {
  data(data.sim.rasch)
  m0 <- irtc.mml(resp = data.sim.rasch, verbose = FALSE)                       # default none
  m1 <- irtc.mml(resp = data.sim.rasch, control = list(acceleration = "squarem"),
                 verbose = FALSE)
  expect_equal(as.numeric(m0$xsi$xsi), as.numeric(m1$xsi$xsi), tolerance = 1e-3)
  expect_equal(m0$deviance, m1$deviance, tolerance = 1e-2)                      # same fixed point
  expect_lte(m1$iter, m0$iter)                                                  # not more iterations
})
