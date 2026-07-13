test_that("fixed covariance entries override the default identity", {
  expect_identical(
    IRTC:::irtc_mml_inits_variance(
      NULL, 2, matrix(c(1, 2, 0.3), nrow = 1)
    ),
    list(variance = matrix(c(1, 0.3, 0.3, 1), nrow = 2))
  )
})

test_that("beta initialization without covariates creates intercept and case anchors", {
  result <- IRTC:::irtc_mml_inits_beta(
    Y = NULL, formulaY = NULL, dataY = NULL,
    G = 1, group = NULL, groups = NULL, nstud = 3,
    pweights = c(1, 2, 1), ridge = 0,
    beta.fixed = NULL, xsi.fixed = NULL, constraint = "cases",
    ndim = 2, beta.inits = NULL
  )

  expect_true(result$nullY)
  expect_identical(result$Y, matrix(1, nrow = 3, ncol = 1))
  expect_identical(result$nreg, 0)
  expect_identical(result$W, matrix(4, nrow = 1, ncol = 1))
  expect_equal(result$YYinv, matrix(0.25, nrow = 1, ncol = 1), tolerance = 1e-14)
  expect_identical(
    result$beta.fixed,
    matrix(c(1, 1, 1, 2, 0, 0), nrow = 2, ncol = 3)
  )
  expect_identical(result$beta, matrix(0, nrow = 1, ncol = 2))
})

test_that("beta initialization labels covariates and preserves vector indexing behavior", {
  result <- IRTC:::irtc_mml_inits_beta(
    Y = matrix(c(2, 3, 4), ncol = 1),
    formulaY = NULL, dataY = NULL,
    G = 1, group = NULL, groups = NULL, nstud = 3,
    pweights = c(1, 2, 1), ridge = 0,
    beta.fixed = FALSE, xsi.fixed = NULL, constraint = "items",
    ndim = 1, beta.inits = matrix(c(2, 1, 7), nrow = 1)
  )

  expect_false(result$nullY)
  expect_identical(colnames(result$Y), c("Intercept", "Y1"))
  expect_identical(result$nreg, 1L)
  expect_identical(result$W, matrix(c(4, 12, 12, 38), 2, 2,
    dimnames = list(c("Intercept", "Y1"), c("Intercept", "Y1"))))
  expect_null(result$beta.fixed)
  expect_identical(result$beta, matrix(c(7, 7), nrow = 2, ncol = 1))
})

test_that("null covariates become group indicators in multiple groups", {
  result <- IRTC:::irtc_mml_inits_beta(
    Y = NULL, formulaY = NULL, dataY = NULL,
    G = 2, group = c(1L, 1L, 2L, 2L), groups = c("a", "b"), nstud = 4,
    pweights = rep(1, 4), ridge = 0,
    beta.fixed = NULL, xsi.fixed = NULL, constraint = "items",
    ndim = 1, beta.inits = NULL
  )

  expect_identical(result$Y, matrix(c(1, 1, 0, 0, 0, 0, 1, 1), 4, 2,
    dimnames = list(NULL, c("groupa", "groupb"))))
  expect_identical(result$nreg, 1)
})

test_that("variance initialization applies fixed entries symmetrically", {
  expect_identical(
    IRTC:::irtc_mml_inits_variance(NULL, 2, matrix(c(1, 2, 0.3), nrow = 1)),
    list(variance = matrix(c(1, 0.3, 0.3, 1), nrow = 2))
  )

  supplied <- matrix(c(2, 0.1, 0.1, 3), 2, 2)
  expect_identical(
    IRTC:::irtc_mml_inits_variance(supplied, 2, NULL),
    list(variance = supplied)
  )
})

test_that("xsi initialization preserves override order and category flag", {
  A <- array(0, c(2, 2, 2))
  A[1, 2, 1] <- -1
  A[2, 2, 2] <- -1
  resp <- matrix(c(0, 1, 1, 0, 1, 1), nrow = 3)
  resp_ind <- 1 - is.na(resp)

  result <- IRTC:::irtc_mml_inits_xsi(
    A = A, resp.ind = resp_ind, ItemScore = c(-2, -1),
    xsi.inits = matrix(c(1, 9), nrow = 1),
    xsi.fixed = matrix(c(2, -4), nrow = 1),
    est.xsi.index = 1:2, pweights = c(1, 2, 1),
    xsi.start0 = FALSE, xsi = c(0, 0), resp = resp
  )

  expect_identical(result$xsi, c(9, -4))
  expect_identical(result$personMaxA, matrix(-1, nrow = 3, ncol = 2))
  expect_identical(result$ItemMax, matrix(c(-4, -4), nrow = 2, ncol = 1))
  expect_true(result$equal.categ)

  zeroed <- IRTC:::irtc_mml_inits_xsi(
    A = A, resp.ind = resp_ind, ItemScore = c(-2, -1),
    xsi.inits = NULL, xsi.fixed = NULL, est.xsi.index = 1:2,
    pweights = c(1, 2, 1), xsi.start0 = TRUE,
    xsi = c(5, 6), resp = resp
  )
  expect_identical(zeroed$xsi, c(0, 0))
})
