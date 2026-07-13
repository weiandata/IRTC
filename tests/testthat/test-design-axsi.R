test_that("PCM design matrices retain category padding and flat layout", {
  resp <- matrix(
    c(0, 1, 2, NA, 1, 0, 1, 1, 0, 1, 0, 1),
    nrow = 4,
    dimnames = list(NULL, c("i1", "i2", "i3"))
  )
  design <- designMatrices(
    "PCM", maxKi = c(i1 = 2, i2 = 1, i3 = 1), resp = resp, ndim = 1
  )

  expect_s3_class(design, "designMatrices")
  expect_equal(dim(design$A), c(3L, 3L, 4L))
  expect_true(all(is.na(design$A[2:3, 3, ])))
  expect_equal(unname(design$A[1, , 1:2]), rbind(c(0, 0), c(-1, 0), c(-1, -1)))
  expect_equal(unname(design$flatA), matrix(aperm(design$A, c(2, 1, 3)), ncol = 4L))
  expect_equal(unname(design$flatB), matrix(aperm(design$B, c(2, 1, 3)), ncol = 1L))
  expect_identical(rownames(design$flatA), rownames(design$flatB))
  expect_equal(unname(design$B[2:3, 3, 1]), c(0, 0))
})

test_that("RSM and item constraints preserve their parameterizations", {
  resp <- matrix(0, nrow = 2, ncol = 3, dimnames = list(NULL, c("i1", "i2", "i3")))
  rsm <- designMatrices("RSM", maxKi = c(i1 = 2, i2 = 1, i3 = 2), resp = resp)
  constrained <- designMatrices(
    "PCM", maxKi = c(i1 = 1, i2 = 1, i3 = 1), resp = resp,
    constraint = "items"
  )

  expect_identical(dimnames(rsm$A)[[3]], c("i1", "i2", "i3", "Cat1"))
  expect_equal(rsm$A[1, , 1], c(0, -1, -2))
  expect_equal(rsm$A[3, , 4], c(0, -1, 0))
  expect_true(all(is.na(rsm$A[2, 3, ])))
  expect_equal(dim(constrained$A), c(3L, 2L, 2L))
  expect_equal(unname(constrained$A[3, 2, ]), c(1, 1))
})

test_that("RSM generation takes precedence over a caller-supplied A", {
  resp <- matrix(0, nrow = 2, ncol = 3, dimnames = list(NULL, c("i1", "i2", "i3")))
  sentinel_A <- array(99, dim = c(3, 3, 4))

  design <- designMatrices(
    "RSM", maxKi = c(i1 = 2, i2 = 1, i3 = 2), resp = resp, A = sentinel_A
  )

  expect_false(identical(design$A, sentinel_A))
  expect_identical(dimnames(design$A)[[3]], c("i1", "i2", "i3", "Cat1"))
  expect_equal(design$A[1, , 1], c(0, -1, -2))
  expect_true(all(is.na(design$A[2, 3, ])))
})

test_that("explicit multidimensional Q determines every category slope and flat layout", {
  resp <- matrix(0, nrow = 2, ncol = 3, dimnames = list(NULL, c("i1", "i2", "i3")))
  Q <- cbind(Dim1 = c(1, 1, 0), Dim2 = c(0, 0, 1))

  design <- designMatrices(
    "PCM", maxKi = c(i1 = 2, i2 = 1, i3 = 2), resp = resp, Q = Q
  )

  expect_identical(dim(design$B), c(3L, 3L, 2L))
  expect_equal(unname(design$B[, 2, ]), unname(Q))
  expect_equal(unname(design$B[, 3, ]), unname(2 * Q))
  expect_equal(unname(design$B[2, 3, ]), c(2, 0))
  expect_equal(
    unname(design$flatB),
    matrix(aperm(design$B, c(2, 1, 3)), ncol = 2L)
  )
  expect_identical(rownames(design$flatB)[c(1, 2, 4)], c("i1.Cat0", "i1.Cat1", "i2.Cat0"))
})

test_that("multidimensional item constraints use one reference item per Q dimension", {
  resp <- matrix(
    0, nrow = 2, ncol = 4,
    dimnames = list(NULL, c("i1", "i2", "i3", "i4"))
  )
  Q <- cbind(Dim1 = c(1, 1, 0, 0), Dim2 = c(0, 0, 1, 1))

  design <- designMatrices(
    "PCM", maxKi = c(i1 = 1, i2 = 1, i3 = 1, i4 = 1),
    resp = resp, Q = Q, constraint = "items"
  )

  expect_identical(dim(design$A), c(4L, 2L, 2L))
  expect_identical(dimnames(design$A)[[3]], c("i1", "i3"))
  expect_equal(
    unname(design$A[, 2, ]),
    rbind(c(-1, 0), c(1, 0), c(0, -1), c(0, 1))
  )
  expect_equal(unname(design$B[, 2, ]), unname(Q))
  expect_equal(
    unname(design$flatA),
    matrix(aperm(design$A, c(2, 1, 3)), ncol = 2L)
  )
})

test_that("zero-score items retain the legacy design failure contract", {
  resp <- matrix(0, nrow = 2, ncol = 2, dimnames = list(NULL, c("i1", "i2")))

  expect_output(
    expect_error(
      designMatrices("PCM", maxKi = c(i1 = 2, i2 = 0), resp = resp),
      "length of 'dimnames' [3] not equal to array extent",
      fixed = TRUE
    ),
    "Items with maximum score of 0: i2",
    fixed = TRUE
  )
})

test_that("one-item item constraints retain legacy failures", {
  resp <- matrix(0, nrow = 2, ncol = 1, dimnames = list(NULL, "i1"))

  expect_error(
    designMatrices("PCM", maxKi = c(i1 = 1), resp = resp, constraint = "items"),
    "invalid first argument, must be an array",
    fixed = TRUE
  )
  expect_warning(
    expect_error(
      .A.PCM2(resp, Kitem = 2, constraint = "items"),
      "replacement has length zero",
      fixed = TRUE
    ),
    "non-empty data for zero-extent matrix",
    fixed = TRUE
  )
})

test_that("PCM2 creates cumulative step columns and pads unavailable categories", {
  resp <- matrix(0, nrow = 2, ncol = 3, dimnames = list(NULL, c("i1", "i2", "i3")))
  design <- .A.PCM2(resp, Kitem = c(3, 2, 2))

  expect_equal(dim(design), c(3L, 3L, 4L))
  expect_identical(dimnames(design)[[3]], c("i1", "i2", "i3", "i1_step1"))
  expect_equal(design[1, , 1], c(0, -1, -2))
  expect_equal(design[1, , 4], c(0, -1, 0))
  expect_true(all(is.na(design[2:3, 3, ])))
})

test_that("AXsi helpers compute linear predictors with NA propagation", {
  A <- array(
    c(0, 0, 1, 2, NA, 3, 0, 0, -1, 1, NA, 2),
    dim = c(2, 3, 2)
  )
  xsi <- c(2, -0.5)
  expected <- matrix(c(0, 0, 2.5, 3.5, NA, 5), nrow = 2)

  expect_equal(irtc_AXsi_compute(A, xsi), expected)
  expect_equal(irtc_mml_compute_AXsi(A, xsi), expected)
})

test_that("AXsi helpers reject arrays with no category columns", {
  A <- array(numeric(0), dim = c(2, 0, 2))

  expect_error(irtc_AXsi_compute(A, c(1, 2)), "subscript out of bounds", fixed = TRUE)
  expect_error(irtc_mml_compute_AXsi(A, c(1, 2)), "subscript out of bounds", fixed = TRUE)
})

test_that("AXsi category padding respects existing missing values", {
  complete <- matrix(1:9, nrow = 3)
  padded <- irtc_mml_include_NA_AXsi(complete, maxcat = c(3, 2, 1))
  expect_equal(padded[1, ], complete[1, ])
  expect_true(is.na(padded[2, 3]))
  expect_true(all(is.na(padded[3, 2:3])))

  already_missing <- complete
  already_missing[1, 1] <- NA
  expect_identical(
    irtc_mml_include_NA_AXsi(already_missing, maxcat = c(3, 2, 1)),
    already_missing
  )

  A <- array(0, dim = c(2, 3, 2))
  expect_equal(
    irtc_mml_include_NA_AXsi(matrix(99, 2, 3), maxcat = c(3, 2), A = A, xsi = c(2, 0)),
    rbind(c(0, 0, 0), c(0, 0, NA))
  )
})
