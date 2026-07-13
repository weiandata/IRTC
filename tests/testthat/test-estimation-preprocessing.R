test_that("response preprocessing removes missing values from the returned matrix", {
  resp <- matrix(c(0, NA, 1, 2, NA, 0), nrow = 3)

  expect_false(anyNA(IRTC:::irtc_mml_proc_response_indicators(resp, 2)$resp))
})

test_that("xsi parameter preprocessing applies inits then removes fixed indices", {
  A <- array(0, c(2, 3, 3))
  result <- IRTC:::irtc_mml_proc_est_xsi_index(
    A, matrix(c(1, 4), nrow = 1), matrix(c(2, -3), nrow = 1)
  )

  expect_identical(
    result,
    list(np = 3L, xsi = c(4, -3, 0), est.xsi.index = c(1L, 3L))
  )
})

test_that("response preprocessing records observed rows and replaces missing values", {
  resp <- matrix(c(0, NA, 1, 2, NA, 0), nrow = 3)
  result <- IRTC:::irtc_mml_proc_response_indicators(resp, 2)

  expect_identical(result$resp, matrix(c(0, 0, 1, 2, 0, 0), 3, 2))
  expect_identical(result$resp.ind, matrix(c(1, 0, 1, 1, 0, 1), 3, 2))
  expect_identical(result$resp.ind.list, list(c(1L, 3L), c(1L, 3L)))
  expect_false(result$nomiss)

  complete <- IRTC:::irtc_mml_proc_response_indicators(matrix(0:3, 2, 2), 2)
  expect_true(complete$nomiss)
})

test_that("unidimensional simplification follows group regression and fixed-beta gates", {
  A <- array(c(NA, 1, 0, -1), c(1, 2, 2))
  fixed <- matrix(c(1, 1, 0), nrow = 1)

  simple <- IRTC:::irtc_mml_proc_unidim_simplify(matrix(1, 3, 1), A, 1, fixed)
  expect_true(simple$unidim_simplify)
  expect_false(simple$YSD)
  expect_identical(simple$Avector, c(0, 1, 0, -1))

  expect_false(IRTC:::irtc_mml_proc_unidim_simplify(matrix(1:3, 3, 1), A, 1, fixed)$unidim_simplify)
  expect_false(IRTC:::irtc_mml_proc_unidim_simplify(matrix(1, 3, 1), A, 2, fixed)$unidim_simplify)
  expect_false(IRTC:::irtc_mml_proc_unidim_simplify(matrix(1, 3, 1), A, 1, NULL)$unidim_simplify)
})

test_that("A parameter preprocessing preserves item links and flattened ranges", {
  A <- array(0, c(2, 3, 3))
  A[1, 2, 1] <- 1
  A[1, 3, 1] <- 2
  A[2, 2, 2] <- -1
  A[2, 3, 3] <- 1

  result <- IRTC:::irtc_mml_proc_xsi_parameter_index_A(A, 3)
  expect_identical(result$indexIP, matrix(c(2, 0, 0, 1, 0, 1), 2, 3))
  expect_identical(result$indexIP.list, list(1L, 2L, 2L))
  expect_identical(result$indexIP.list2, c(1L, 2L, 2L))
  expect_identical(
    result$indexIP.no,
    matrix(c(1, 2, 3, 1, 2, 3), 3, 2,
      dimnames = list(NULL, c("", "lipl")))
  )
})

test_that("prior preprocessing marks active entries and resets evaluation x", {
  prior <- list(
    list("normal", list(mean = 0, sd = 1, x = 5)),
    NULL,
    list("normal", list(x = 2))
  )
  result <- IRTC:::irtc_mml_proc_prior_list_xsi(prior, c(0, 0, 0))

  expect_true(is.na(result[[1]][[2]]$x))
  expect_true(is.na(result[[3]][[2]]$x))
  expect_identical(attr(result, "dim_parameter"), 3L)
  expect_true(attr(result, "is_prior"))
  expect_identical(attr(result, "prior_entries"), c(1L, 3L))
  expect_identical(attr(result, "length_prior_entries"), 2L)

  absent <- IRTC:::irtc_mml_proc_prior_list_xsi(NULL, c(0, 0))
  expect_length(absent, 0L)
  expect_identical(attr(absent, "dim_parameter"), 2L)
  expect_false(attr(absent, "is_prior"))
  expect_null(attr(absent, "prior_entries"))
  expect_identical(attr(absent, "length_prior_entries"), 0L)
  expect_error(
    IRTC:::irtc_mml_proc_prior_list_xsi(list(), 0),
    "subscript out of bounds", fixed = TRUE
  )
})
