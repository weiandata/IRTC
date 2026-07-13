# Fast (approximate) mode: opt-in, default off; close to exact but faster.

test_that("default mode is exact (fast is off by default)", {
  data(data.sim.rasch)
  m_def  <- irtc.mml.2pl(resp = data.sim.rasch, irtmodel = "2PL", verbose = FALSE)
  m_slow <- irtc.mml.2pl(resp = data.sim.rasch, irtmodel = "2PL",
                         control = list(fast = FALSE), verbose = FALSE)
  expect_equal(m_def$deviance, m_slow$deviance, tolerance = 1e-10)
})

test_that("fast mode stays close to exact", {
  data(data.sim.rasch)
  m_exact <- irtc.mml.2pl(resp = data.sim.rasch, irtmodel = "2PL", verbose = FALSE)
  m_fast  <- irtc.mml.2pl(resp = data.sim.rasch, irtmodel = "2PL",
                          control = list(fast = TRUE), verbose = FALSE)
  expect_equal(as.numeric(m_fast$xsi$xsi), as.numeric(m_exact$xsi$xsi), tolerance = 1e-2)
  rel <- abs(m_fast$deviance - m_exact$deviance) / abs(m_exact$deviance)
  expect_lt(rel, 1e-3)
})
