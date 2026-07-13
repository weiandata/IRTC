test_that("multidimensional nodes preserve Cartesian order and supplied weights", {
    expected <- matrix(
        c(-1, 2, -1, 2, -1, -1, 2, 2),
        ncol=2,
        dimnames=list(NULL, c("V1", "V2"))
    )
    expect_identical(irtc_mml_create_nodes_multidim_nodes(c(-1, 2), 2), expected)

    supplied <- matrix(
        c(-1, 0.2, 1, 0.8),
        nrow=2,
        dimnames=list(c("low", "high"), c("node", "weight"))
    )
    expect_identical(irtc_mml_create_nodes_multidim_nodes(supplied, 2), supplied)
    expect_identical(
        irtc_mml_create_nodes_multidim_nodes(matrix(1:4, nrow=2), 1),
        matrix(1:4, ncol=1)
    )
})

test_that("response column naming preserves existing names and failures", {
    unnamed <- matrix(1:6, nrow=2, dimnames=list(c("a", "b"), NULL))
    named <- matrix(1:4, nrow=2, dimnames=list(NULL, c("left", NA_character_)))

    expect_identical(
        add.colnames.resp(unnamed),
        matrix(1:6, nrow=2,
               dimnames=list(c("a", "b"), c("I1", "I2", "I3")))
    )
    expect_identical(add.colnames.resp(named), named)
    expect_error(add.colnames.resp(matrix(numeric(), nrow=2, ncol=0)),
                 "length of 'dimnames'")
    expect_error(add.colnames.resp(1:3), "argument of length 0")
})

test_that("leading prefixes retain integer formatting and legacy errors", {
    expect_identical(add.lead(c(1L, 20L)), c("01", "20"))
    expect_identical(add.lead(c(1L, 20L), width=c(2, 3)), c("01", "020"))
    expect_identical(
        add.lead(1:4, width=c(2, 3)),
        c("01", "002", "03", "004")
    )
    expect_error(add.lead(1:3, width=c(2, 3)),
                 "arguments cannot be recycled to the same length")
    expect_identical(add.lead(c(-1L, 2L)), c("-1", "02"))
    expect_identical(add.lead(c(1L, 2L), width=0), c("1", "2"))
    expect_error(add.lead(c("2", "10")), "invalid format")
    expect_warning(expect_identical(add.lead(integer()), character()),
                   "no non-missing arguments")
})

test_that("truncated normal density preserves support and boundary behavior", {
    x <- c(-2, -1, 0, 1, 2)
    normalizer <- stats::pnorm(1) - stats::pnorm(-1)
    expected <- c(0, stats::dnorm(c(-1, 0, 1)) / normalizer, 0)

    expect_equal(irtc_dtnorm(x, lower=-1, upper=1), expected)
    expect_equal(
        irtc_dtnorm(x, lower=-1, upper=1, log=TRUE),
        ifelse(expected == 0, -Inf, log(expected))
    )
    expect_identical(
        irtc_dtnorm(c(-1, 0, 1), lower=2, upper=1),
        rep(NaN, 3)
    )
    expect_identical(
        irtc_dtnorm(c(-1, 0, 1), lower=0, upper=0),
        c(0, Inf, 0)
    )
    expect_identical(irtc_dtnorm(c(-Inf, Inf)), c(0, 0))
    expect_error(irtc_dtnorm(c(NA_real_, 0), lower=-1, upper=1),
                 "NAs are not allowed in subscripted assignments")
})
