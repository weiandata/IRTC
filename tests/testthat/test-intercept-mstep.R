intercept_fixture <- function() {
  list(
    A = array(c(0, -1), c(1, 2, 1)),
    rprobs = array(c(0.4, 0.6), c(1, 2, 1)),
    AXsi = matrix(0, 1, 2),
    B = array(0, c(1, 2, 1)),
    theta = matrix(0, 1, 1),
    itemwt = matrix(1, 1, 1),
    indexIP.no = matrix(c(1, 1), 1, 2)
  )
}

test_that("quasi-Newton intercept step preserves sufficient-statistic update", {
  f <- intercept_fixture()
  result <- IRTC:::irtc_mml_mstep_intercept_quasi_newton_R(
    rprobs = f$rprobs, converge = FALSE, Miter = 1, Msteps = 1,
    nitems = 1, A = f$A, AXsi = f$AXsi, B = f$B, xsi = 0,
    theta = f$theta, nnodes = 1, maxK = 2, est.xsi.index = 1,
    itemwt = f$itemwt, indexIP.no = f$indexIP.no, indexIP.list2 = 1,
    Avector = c(0, -1), ItemScore = -0.8, xsi.fixed = NULL,
    old_increment = 1, convM = 1e-4, fac.oldxsi = 0, oldxsi = 0,
    trim_increment = "cut", progress = FALSE, np = 1,
    increments_msteps = NA_real_, maxcat = 2, use_rcpp = TRUE
  )

  expect_equal(result$xsi, -5 / 6, tolerance = 1e-14)
  expect_identical(result$Miter, 2)
  expect_equal(result$increments_msteps, 5 / 6, tolerance = 1e-14)
  expect_equal(result$se.xsi, sqrt(1 / 0.24), tolerance = 1e-14)
  expect_identical(result$logprior_xsi, 0)
})

test_that("quasi-Newton respects fixed parameters and old-xsi stabilization", {
  f <- intercept_fixture()
  fixed <- IRTC:::irtc_mml_mstep_intercept_quasi_newton_R(
    f$rprobs, FALSE, 1, 1, 1, f$A, f$AXsi, f$B, 2,
    f$theta, 1, 2, 1, f$itemwt, f$indexIP.no, 1, c(0, -1),
    -0.8, matrix(c(1, 2), nrow = 1), 1e-20, 1, 1e-4,
    0.5, 2, "cut", FALSE, 1, NA_real_, 2, TRUE
  )
  expect_identical(fixed$xsi, 2)
  expect_identical(fixed$se.xsi, 0)
  expect_identical(fixed$increments_msteps, 0)
})

test_that("optim intercept path preserves likelihood solution and return fields", {
  f <- intercept_fixture()
  n_ik <- array(c(4, 6), c(1, 1, 2, 1))
  result <- IRTC:::irtc_mml_mstep_intercept_optim(
    xsi = 0, n.ik = n_ik, prior_list_xsi = NULL, nitems = 1,
    A = f$A, AXsi = f$AXsi, B = f$B, theta = f$theta,
    nnodes = 1, maxK = 2, Msteps = 3, xsi.fixed = NULL
  )
  expect_equal(result$xsi, -0.405465136581418, tolerance = 1e-8)
  expect_equal(result$se.xsi, 0.645497273687752, tolerance = 1e-8)
  expect_identical(result$logprior_xsi, 0)
})

test_that("intercept router preserves R and optim output structures", {
  f <- intercept_fixture()
  common <- list(
    A = f$A, xsi = 0, AXsi = f$AXsi, B = f$B, theta = f$theta,
    nnodes = 1, maxK = 2, Msteps = 1, rprobs = f$rprobs, np = 1,
    est.xsi.index0 = 1, itemwt = f$itemwt, indexIP.no = f$indexIP.no,
    indexIP.list2 = 1, Avector = c(0, -1), max.increment = 1,
    xsi.fixed = NULL, fac.oldxsi = 0, ItemScore = -0.8, convM = 1e-4,
    progress = FALSE, nitems = 1, iter = 2, increment.factor = 1,
    xsi_acceleration = list(acceleration = "none"), trim_increment = "cut",
    prior_list_xsi = NULL, mstep_intercept_method = "R",
    n.ik = NULL, maxcat = 2
  )
  result_r <- do.call(IRTC:::irtc_mml_mstep_intercept, common)
  expect_equal(result_r$xsi, -5 / 6, tolerance = 1e-14)
  expect_identical(result_r$Miter, 2)
  expect_identical(names(result_r), c(
    "xsi", "max.increment", "se.xsi", "Miter", "xsi_acceleration",
    "xsi_change", "Miter", "increments_msteps", "logprior_xsi"
  ))

  common$mstep_intercept_method <- "optim"
  common$n.ik <- array(c(4, 6), c(1, 1, 2, 1))
  common$Msteps <- 3
  result_optim <- do.call(IRTC:::irtc_mml_mstep_intercept, common)
  expect_equal(result_optim$xsi, -0.405465136581418, tolerance = 1e-8)
  expect_null(result_optim$Miter)
  expect_null(result_optim$increments_msteps)
})
