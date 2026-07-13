test_that("deviance uses deterministic likelihoods, priors, and history", {
    history <- matrix(NA_real_, nrow=3, ncol=2)
    result <- irtc_mml_compute_deviance(
        loglike_num=c(.25, .5), loglike_sto=c(.9, .9), snodes=0,
        thetawidth=2, pweights=c(1, 2), deviance=10,
        deviance.history=history, iter=2,
        logprior_xsi=log(c(.8, .9))
    )

    expected_penalty <- -2 * sum(log(c(.8, .9)))
    expected_deviance <- expected_penalty - 2 * sum(
        c(1, 2) * log(c(.25, .5) * 2)
    )
    expect_equal(result$deviance, expected_deviance)
    expect_equal(result$penalty_xsi, expected_penalty)
    expect_equal(result$deviance_change, abs(expected_deviance - 10))
    expect_equal(result$deviance_change_signed, expected_deviance - 10)
    expect_equal(
        result$rel_deviance_change,
        abs((expected_deviance - 10) / expected_deviance)
    )
    expect_equal(result$deviance.history[2, 2], expected_deviance)
})

test_that("deviance uses stochastic likelihoods when nodes are sampled", {
    result <- irtc_mml_compute_deviance(
        loglike_num=c(.9, .9), loglike_sto=c(.5, .25), snodes=4,
        thetawidth=99, pweights=c(1, 2), deviance=NA
    )

    expect_equal(result$deviance, -2 * sum(c(1, 2) * log(c(.5, .25))))
    expect_true(is.na(result$deviance_change))
    expect_equal(result$penalty_xsi, 0)
})

test_that("AXsi standard errors propagate independent xsi variances", {
    design <- array(0, dim=c(2, 2, 2))
    design[1, 1, ] <- c(1, 2)
    design[2, 1, ] <- c(0, 1)
    design[1, 2, ] <- c(NA, 1)
    design[2, 2, ] <- c(1, -1)

    standard_errors <- irtc_mml_se_AXsi(
        AXsi=matrix(0, 2, 2), A=design, se.xsi=c(2, 3), maxK=2
    )

    expect_equal(
        standard_errors,
        matrix(c(sqrt(40), 3, 3, sqrt(13)), nrow=2)
    )

    scalar_design <- array(c(1, 2), dim=c(2, 1, 1))
    expect_equal(
        irtc_mml_se_AXsi(
            AXsi=matrix(0, 2, 1), A=scalar_design,
            se.xsi=2, maxK=1
        ),
        matrix(c(2, 4), ncol=1)
    )
})

test_that("information criteria count free parameters and remove prior penalty", {
    B_orig <- array(c(0, 0, 1, 1), dim=c(2, 2, 1))
    result <- irtc_mml_ic(
        nstud=100, deviance=200, xsi=c(0, 1, 2),
        xsi.fixed=matrix(c(1, 0), nrow=1), beta=matrix(c(0, 0), 2, 1),
        beta.fixed=matrix(c(1, 1, 0), nrow=1), ndim=1,
        variance.fixed=NULL, G=2, irtmodel="2PL", B_orig=B_orig,
        B.fixed=matrix(c(1, 2, 1, 0), nrow=1), E=matrix(1),
        est.variance=TRUE, resp=matrix(0, 2, 2),
        est.slopegroups=NULL, variance.Npars=NULL,
        group=c(1, 2), penalty_xsi=4,
        AXsi=matrix(0, 2, 2), pweights=c(1, 2),
        resp.ind=matrix(1, 2, 2), B=B_orig
    )

    expect_equal(result$deviance, 196)
    expect_equal(result$loglike, -98)
    expect_equal(result$logprior, -2)
    expect_equal(result$logpost, -100)
    expect_equal(result$Nparsxsi, 2)
    expect_equal(result$NparsB, 1)
    expect_equal(result$Nparsbeta, 1)
    expect_equal(result$Nparscov, 2)
    expect_equal(result$Npars, 6)
    expect_equal(result$ghp_obs, 6)
    expect_equal(result$AIC, 208)
    expect_equal(result$GHP, 208 / 12)
    expect_identical(.IRTC.ic, irtc_mml_ic)
})

test_that("criteria helper computes the supported penalties", {
    criteria <- irtc_mml_ic_criteria(data.frame(
        n=50, deviance=100, np=4, ghp_obs=10
    ))

    expect_equal(criteria$AIC, 108)
    expect_equal(criteria$AIC3, 112)
    expect_equal(criteria$BIC, 100 + log(50) * 4)
    expect_equal(criteria$aBIC, 100 + log(48 / 24) * 4)
    expect_equal(criteria$CAIC, 100 + (log(50) + 1) * 4)
    expect_equal(criteria$AICc, 108 + 2 * 4 * 5 / 45)
    expect_equal(criteria$GHP, 108 / 20)
})
