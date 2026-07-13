test_that("maximum categories preserve vector and column contracts", {
    expect_identical(irtc_max_categories(c(0, 2, NA)), 2)
    response <- matrix(
        c(0L, 2L, NA_integer_, NA_integer_, NA_integer_, NA_integer_),
        nrow=3,
        dimnames=list(NULL, c("observed", "missing"))
    )
    expect_warning(
        maxima <- irtc_max_categories(response),
        "no non-missing arguments"
    )
    expect_identical(maxima, c(observed=2L, missing=-Inf))
    expect_error(
        irtc_max_categories(matrix(numeric(), nrow=0, ncol=0)),
        "subscript out of bounds"
    )
})

test_that("theta squares retain native layout, dimensions, and aliases", {
    theta <- matrix(c(1, 2, NA, -1, Inf, 3), nrow=3)
    expected <- array(
        c(1, 4, NA, -1, Inf, NA, -1, Inf, NA, 1, Inf, 9),
        dim=c(3L, 2L, 2L)
    )

    expect_identical(irtc_theta_sq(theta), expected)
    expect_identical(irtc_theta_sq(theta, is_matrix=TRUE),
                     matrix(expected, nrow=3, ncol=4))
    expect_identical(theta.sq2, irtc_theta_sq)
})

test_that("row normalization preserves shape, names, and special values", {
    x <- matrix(
        c(1, -1, 0, 0, 1, NA),
        nrow=3,
        byrow=TRUE,
        dimnames=list(c("unit", "zero", "unknown"), c("a", "b"))
    )

    normalized <- irtc_normalize_matrix_rows(x)
    expect_identical(dim(normalized), c(3L, 2L))
    expect_identical(dimnames(normalized), dimnames(x))
    expect_identical(unname(normalized[1, ]), c(Inf, -Inf))
    expect_true(all(is.nan(normalized[2, ])))
    expect_true(all(is.na(normalized[3, ])))
})

test_that("outer helper implements supported operations and legacy fallback", {
    expect_identical(irtc_outer(c(1, 2), c(3, 5, 7)),
                     matrix(c(3, 6, 5, 10, 7, 14), nrow=2))
    expect_identical(irtc_outer(c(1, 2), c(3, 5), op="+"),
                     matrix(c(4, 5, 6, 7), nrow=2))
    expect_identical(irtc_outer(c(1, 2), c(3, 5), op="-"),
                     matrix(c(-2, -1, -4, -3), nrow=2))
    expect_null(irtc_outer(1:2, 3:4, op="/"))
    expect_error(irtc_outer(1:2, 3:4, op=NA_character_),
                 "missing value where TRUE/FALSE needed")
})

test_that("row maxima preserve NA handling and unnamed output", {
    mat <- matrix(
        c(1, NA, NA, NaN, 3, 2),
        nrow=2,
        dimnames=list(c("first", "second"), NULL)
    )

    expect_identical(irtc_rowMaxs(mat), c(NA_real_, NaN))
    expect_identical(irtc_rowMaxs(mat, na.rm=TRUE), c(3, 2))
    expect_null(names(irtc_rowMaxs(mat, na.rm=TRUE)))
    expect_identical(
        irtc_rowMaxs(matrix(c(NA_real_, NaN), nrow=1), na.rm=TRUE),
        NaN
    )
    expect_identical(
        irtc_rowMaxs(matrix(c(NaN, NA_real_), nrow=1)),
        NA_real_
    )
    expect_identical(
        irtc_rowMaxs(matrix(c(NaN, NA_real_), nrow=1), na.rm=TRUE),
        NA_real_
    )
    expect_identical(
        irtc_rowMaxs(matrix(c(TRUE, FALSE, FALSE, FALSE), nrow=2)),
        c(TRUE, FALSE)
    )
    expect_identical(
        irtc_rowMaxs(matrix(integer(), nrow=2, ncol=0)),
        matrix(integer(), nrow=0, ncol=2)
    )
    expect_identical(
        irtc_rowMaxs(matrix(numeric(), nrow=0, ncol=0)),
        matrix(numeric(), nrow=0, ncol=0)
    )
    expect_error(
        irtc_rowMaxs(matrix(numeric(), nrow=0, ncol=2)),
        "argument lengths differ"
    )
    expect_warning(
        indeterminate <- irtc_rowMaxs(
            matrix(c(1, NA_real_, 2), nrow=1),
            na.rm=NA
        ),
        "data length \\[2\\].*number of rows \\[3\\]"
    )
    expect_identical(indeterminate, 1)
    expect_identical(rowMaxs, irtc_rowMaxs)
})

test_that("matrix replication preserves dimensions, defaults, and recycling", {
    expect_identical(irtc_matrix2(1:3), matrix(1:3, nrow=1))
    expect_identical(irtc_matrix2(1:3, nrow=2),
                     matrix(c(1L, 1L, 2L, 2L, 3L, 3L), nrow=2))
    expect_warning(
        recycled <- irtc_matrix2(1:3, nrow=2, ncol=4),
        "data length.*number of rows"
    )
    expect_identical(recycled,
                     matrix(c(1L, 2L, 2L, 3L, 3L, 1L, 1L, 2L), nrow=2))
})
