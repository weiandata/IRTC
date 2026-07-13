test_that("weighted statistics select requested non-missing observations", {
    selected <- irtc_weighted_stats_select(
        x=c(1, NA, 3, 5), w=c(2, 4, NA, 1), select=c(1, 2, 3)
    )

    expect_equal(selected$x, c(1, 3))
    expect_equal(selected$w, c(2, NA))
    expect_equal(weighted_mean(c(1, 3, 9), c(1, 3, 20), select=1:2), 2.5)
    expect_true(is.nan(weighted_mean(numeric(), numeric())))
})

test_that("multiple-group student priors use each group's covariance", {
    theta <- matrix(c(-1, 1), ncol=1)
    design <- matrix(1, nrow=4, ncol=1)
    beta <- matrix(0, nrow=1, ncol=1)
    variance <- array(c(1, 4), dim=c(2, 1, 1))

    density <- irtc_stud_prior_multiple_groups(
        theta=theta, Y=design, beta=beta, variance=variance,
        nstud=4, nnodes=2, ndim=1, YSD=FALSE,
        unidim_simplify=TRUE, G=2,
        group_indices=list(1:2, 3:4)
    )

    expect_equal(density[1:2, ], matrix(dnorm(c(-1, 1)), 2, 2, byrow=TRUE))
    expect_equal(
        density[3:4, ],
        matrix(dnorm(c(-1, 1), sd=2), 2, 2, byrow=TRUE)
    )

    normalized <- irtc_stud_prior_multiple_groups(
        theta=theta, Y=design, beta=beta, variance=variance,
        nstud=4, nnodes=2, ndim=1, YSD=FALSE,
        unidim_simplify=TRUE, G=2,
        group_indices=list(1:2, 3:4), normalize=TRUE
    )
    expect_equal(rowSums(normalized), rep(1, 4))
})

test_that("stochastic nodes adapt to the first group and return moments", {
    skip_if_not_installed("mvtnorm")
    samples <- matrix(c(-1, 0, 1), ncol=1)
    variance <- array(c(4, 9), dim=c(2, 1, 1))
    beta <- matrix(0.5, nrow=1, ncol=1)

    updated <- irtc_mml_update_stochastic_nodes(
        theta0.samp=samples, variance=variance, snodes=3,
        beta=beta, theta=matrix(99, 1, 1)
    )

    expect_equal(updated$theta, matrix(c(-1.5, 0.5, 2.5), ncol=1))
    expect_equal(updated$theta2, updated$theta^2)
    expect_equal(
        updated$thetasamp.density,
        as.numeric(mvtnorm::dmvnorm(updated$theta, mean=0.5, sigma=matrix(4)))
    )
})

test_that("latent regression updates coefficients, variance, and item weights", {
    hwt <- matrix(c(.75, .25, .25, .75), nrow=2, byrow=TRUE)
    theta <- matrix(c(-1, 1), ncol=1)
    theta2 <- theta^2
    design <- matrix(1, nrow=2, ncol=1)

    result <- irtc_mml_mstep_regression(
        resp=matrix(0, 2, 1), hwt=hwt, resp.ind=matrix(1, 2, 1),
        pweights=c(1, 1), pweightsM=matrix(1, 2, 1),
        Y=design, theta=theta, theta2=theta2,
        YYinv=matrix(.5), ndim=1, nstud=2,
        beta.fixed=NULL, variance=matrix(2), Variance.fixed=NULL,
        group=rep(1, 2), G=1, beta=matrix(.2)
    )

    expect_equal(result$beta, matrix(0), tolerance=1e-14)
    expect_equal(result$variance, matrix(1 + 1e-10), tolerance=1e-14)
    expect_equal(result$itemwt, matrix(c(1, 1), ncol=1))
    expect_equal(result$beta_change, .2)
    expect_equal(result$variance_change, 1 - 1e-10, tolerance=1e-14)
    expect_identical(mstep.regression, irtc_mml_mstep_regression)

    fixed <- irtc_mml_mstep_regression(
        resp=matrix(0, 2, 1), hwt=hwt, resp.ind=matrix(1, 2, 1),
        pweights=c(1, 1), pweightsM=matrix(1, 2, 1),
        Y=design, theta=theta, theta2=theta2,
        YYinv=matrix(.5), ndim=1, nstud=2,
        beta.fixed=matrix(c(1, 1, .4), nrow=1),
        variance=matrix(2),
        Variance.fixed=matrix(c(1, 1, .7), nrow=1),
        group=rep(1, 2), G=1, beta=matrix(.2), nomiss=TRUE
    )

    expect_equal(fixed$beta, matrix(.4))
    expect_equal(fixed$variance, matrix(.7 + 1e-10), tolerance=1e-14)
    expect_equal(fixed$itemwt, matrix(c(1, 1), nrow=2, ncol=1))
})
