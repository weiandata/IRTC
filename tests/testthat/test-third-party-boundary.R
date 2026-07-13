test_that("external adapters return their upstream package results", {
    skip_if_not_installed("MASS")
    skip_if_not_installed("mvtnorm")
    skip_if_not_installed("sfsmisc")

    matrix_to_invert <- matrix(c(2, .25, .25, 1), 2, 2)
    expect_identical(
        irtc_import_MASS_ginv(matrix_to_invert),
        MASS::ginv(X=matrix_to_invert)
    )

    observations <- matrix(c(-1, 0, 1, .5), ncol=2, byrow=TRUE)
    density_arguments <- list(
        x=observations, mean=c(.25, -.25),
        sigma=matrix(c(1, .2, .2, 2), 2, 2), log=TRUE
    )
    expect_identical(
        do.call(irtc_import_mvtnorm_dmvnorm, density_arguments),
        do.call(mvtnorm::dmvnorm, density_arguments)
    )

    sequence_arguments <- list(n=6, min=-1, max=2, n.min=3, p=2, leap=7)
    expect_identical(
        do.call(irtc_import_sfsmisc_QUnif, sequence_arguments),
        do.call(sfsmisc::QUnif, sequence_arguments)
    )
})

test_that("local spectrum stabilization preserves or floors singular values", {
    stable <- diag(c(2, .5))
    expect_identical(irtc_ginv(stable, eps=.05), stable)

    unstable <- diag(c(2, .01))
    adjusted <- c(2, .05)
    adjusted <- adjusted / sum(adjusted) * sum(c(2, .01))
    expect_equal(irtc_ginv(unstable, eps=.05), diag(adjusted), tolerance=1e-14)
})

test_that("scaled helper preserves MASS and local routing", {
    covariance <- matrix(c(4, 1, 1, 9), 2, 2)
    standard_deviation <- sqrt(diag(covariance))
    scale <- outer(standard_deviation, standard_deviation)
    correlation <- covariance / scale
    inverse_scale <- outer(1 / standard_deviation, 1 / standard_deviation)

    expect_equal(
        irtc_ginv_scaled(covariance, use_MASS=TRUE),
        MASS::ginv(X=correlation) * inverse_scale,
        tolerance=1e-14
    )
    expect_equal(
        irtc_ginv_scaled(covariance, use_MASS=FALSE),
        irtc_ginv(correlation) * inverse_scale,
        tolerance=1e-14
    )
})

test_that("hybrid helper signatures remain stable", {
    expect_identical(names(formals(irtc_import_MASS_ginv)), c("X", "..."))
    expect_identical(names(formals(irtc_import_mvtnorm_dmvnorm)), "...")
    expect_identical(
        names(formals(irtc_import_sfsmisc_QUnif)),
        c("n", "min", "max", "n.min", "p", "leap", "...")
    )
    expect_identical(names(formals(irtc_ginv)), c("x", "eps"))
    expect_identical(names(formals(irtc_ginv_scaled)), c("x", "use_MASS"))
})
