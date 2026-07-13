test_that("calc_exp wrapper preserves flattened native sufficient statistics", {
  rprobs <- array(c(0.4, 0.6), c(1, 2, 1))
  A <- array(c(0, -1), c(1, 2, 1))
  result <- IRTC:::irtc_calc_exp(
    rprobs = rprobs, A = A, np = 1, est.xsi.index = 1,
    itemwt = matrix(1, 1, 1), indexIP.no = matrix(c(1, 1), 1, 2),
    indexIP.list2 = 1, Avector = c(0, -1)
  )
  expect_identical(result, list(xbar = -0.6, xbar2 = 0.36, xxf = 0.6))
  expect_identical(IRTC:::calc_exp_TK3, IRTC:::irtc_calc_exp)

  rprobs[1, 1, 1] <- NA_real_
  expect_identical(
    IRTC:::irtc_calc_exp(
      rprobs, A, 1, 1, matrix(1, 1, 1), matrix(c(1, 1), 1, 2), 1, c(0, -1)
    ),
    result
  )
})

test_that("difference quotient returns forward gradient and centered curvature", {
  result <- IRTC:::irtc_difference_quotient(
    c(1, 2), c(1.2, 1.8), c(0.9, 2.1), 0.1
  )
  expect_equal(result$d1, c(2, -2), tolerance = 1e-14)
  expect_equal(result$d2, c(10, -10), tolerance = 1e-12)
  expect_identical(IRTC:::irtc_mml_3pl_difference_quotient, IRTC:::irtc_difference_quotient)
})

test_that("increment trimming preserves half cut unknown and NA modes", {
  expect_identical(
    IRTC:::irtc_trim_increment(c(3, -3, NA), 1, "half", 2, 1e-10, TRUE),
    c(0.5, -0.5, 0)
  )
  expect_identical(
    IRTC:::irtc_trim_increment(c(3, -3, 0.5), 1, "cut"),
    c(1, -1, 0.5)
  )
  expect_identical(
    IRTC:::irtc_trim_increment(c(3, NA), 1, "none"),
    c(3, NA_real_)
  )
})

test_that("parameter change flattens inputs before taking the maximum", {
  expect_identical(
    IRTC:::irtc_parameter_change(matrix(1:4, 2), c(1, 1, 4, 5)),
    1
  )
  expect_warning(
    expect_identical(IRTC:::irtc_parameter_change(numeric(), numeric()), -Inf),
    "no non-missing arguments to max; returning -Inf", fixed = TRUE
  )
})

test_that("normal prior log density and analytic derivatives are preserved", {
  args <- list(mean = 1, sd = 2, x = 99)
  values <- vapply(0:2, function(deriv) {
    IRTC:::irtc_prior_eval_log_density_one_parameter("norm", args, 3, deriv)
  }, numeric(1))
  expect_equal(values, c(-2.11208571376462, -0.5, -0.25), tolerance = 1e-14)
})

test_that("prior list evaluation preserves active-entry indexing and derivative mode", {
  prior <- list(
    list("norm", list(mean = 0, sd = 1, x = 99)),
    NULL,
    list("norm", list(mean = 1, sd = 2, x = 99))
  )
  attr(prior, "is_prior") <- TRUE
  attr(prior, "prior_entries") <- c(1L, 3L)
  attr(prior, "length_prior_entries") <- 2L

  result <- IRTC:::irtc_evaluate_prior(prior, c(2, 7, 3))
  expect_equal(
    result,
    list(
      d0 = c(-2.91893853320467, 0, -6.11208571376462),
      d1 = c(-2.0001, 0, -1.500025),
      d2 = c(-1, 0, -0.25)
    ),
    tolerance = 1e-13
  )
  no_derivatives <- IRTC:::irtc_evaluate_prior(prior, c(2, 7, 3), FALSE)
  expect_identical(no_derivatives$d1, c(0, 0, 0))
  expect_identical(no_derivatives$d2, c(0, 0, 0))
})

test_that("information count and grouped aggregates retain shapes and ordering", {
  resp_ind <- matrix(c(1, 0, 1, 1, 1, 0), 3, 2)
  expect_identical(IRTC:::irtc_ghp_number_informations(c(1, 2, 3), resp_ind), 7)
  expect_null(IRTC:::irtc_ghp_number_informations(c(1, 2, 3), NULL))

  x <- matrix(c(1, 2, NA, 4, 5, 6), 3, 2)
  aggregate_result <- IRTC:::irtc_aggregate(x, c(2, 1, 2), TRUE, TRUE)
  expect_identical(
    aggregate_result,
    matrix(c(1, 2, 2, 1, 5, 5), 2, 3,
      dimnames = list(c("1", "2"), c("ng1", "", "")))
  )

  expect_identical(
    IRTC:::irtc_aggregate_derivative_information(c(1, 2, 3, 4), c(2, 1, 2, 0)),
    c(4, 2, 4, 0)
  )
})
