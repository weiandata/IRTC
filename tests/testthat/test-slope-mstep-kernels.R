test_that("slope sufficient statistics reshape observed node scores", {
    hwt <- matrix(c(.75, .25, .25, .75), nrow=2, byrow=TRUE)
    theta <- matrix(c(-1, 1), ncol=1)
    category_response <- matrix(
        c(1, 0, 0, 1, 0, 1, 1, 0), nrow=2, byrow=TRUE
    )

    result <- irtc_mml_2pl_sufficient_statistics_item_slope(
        hwt=hwt, theta=theta, cResp=category_response,
        pweights=c(1, 2), maxK=2, nitems=2, ndim=1
    )

    expect_equal(result$thetabar, matrix(c(-.5, .5), ncol=1))
    expect_equal(
        result$cB_obs,
        crossprod(category_response * c(1, 2), result$thetabar)
    )
    expect_equal(
        result$B_obs,
        aperm(array(result$cB_obs, dim=c(2, 2, 1)), c(2, 1, 3))
    )
})

test_that("R and native 2PL slope kernels compute the defining moments", {
    probabilities <- array(
        c(.7, .4, .3, .6, .5, .2, .5, .8, .2, .9, .8, .1),
        dim=c(2, 2, 3)
    )
    theta <- matrix(c(-1, 0, 1), ncol=1)
    itemwt <- matrix(c(1, 2, 3, 4, 5, 6), nrow=3)
    zeros <- matrix(0, 2, 2)

    pure_r <- irtc_mml_2pl_mstep_item_slopes_suffstat_R(
        rprobs=probabilities, maxK=2, LIT=2, TP=3,
        itemwt=itemwt, theta=theta, dd=1, items.temp=1:2,
        items.conv=NULL, xbar=zeros, xbar2=zeros, xxf=zeros,
        xtemp=matrix(0, 1, 1), irtmodel="2PL"
    )
    native <- irtc_rcpp_mml_2pl_mstep_item_slopes_suffstat(
        rprobs=as.vector(probabilities), items_temp=1:2,
        theta=theta, dd=0, LIT=2, TP=3, nitems=2,
        maxcat=c(2L, 2L), maxK=2, itemwt=itemwt,
        xxf_=zeros, xbar_=zeros, xbar2_=zeros,
        irtmodel="2PL", xtemp_=matrix(0, 1, 1),
        items_conv=-1L, n_threads=2L
    )

    expected_xbar <- expected_xxf <- expected_xbar2 <- zeros
    for (item in 1:2) {
        for (category in 1:2) {
            probability <- probabilities[item, category, ]
            weight <- itemwt[, item]
            expected_xbar[item, category] <- sum(theta[, 1] * probability * weight)
            expected_xxf[item, category] <- sum(theta[, 1]^2 * probability * weight)
            expected_xbar2[item, category] <- sum(
                theta[, 1]^2 * probability^2 * weight
            )
        }
    }

    expect_equal(pure_r$xbar, expected_xbar)
    expect_equal(pure_r$xxf, expected_xxf)
    expect_equal(pure_r$xbar2, expected_xbar2)
    expect_equal(native$xbar, pure_r$xbar)
    expect_equal(native$xxf, pure_r$xxf)
    expect_equal(native$xbar2, pure_r$xbar2)
})

test_that("GPCM slope moments apply category scores", {
    probabilities <- array(
        c(.7, .4, .3, .6, .5, .2, .5, .8, .2, .9, .8, .1),
        dim=c(2, 2, 3)
    )
    theta <- matrix(c(-1, 0, 1), ncol=1)
    itemwt <- matrix(c(1, 2, 3, 4, 5, 6), nrow=3)
    zeros <- matrix(0, 2, 2)

    pure_r <- irtc_mml_2pl_mstep_item_slopes_suffstat_R(
        rprobs=probabilities, maxK=2, LIT=2, TP=3,
        itemwt=itemwt, theta=theta, dd=1, items.temp=1:2,
        items.conv=NULL, xbar=zeros, xbar2=zeros, xxf=zeros,
        xtemp=matrix(0, 2, 3), irtmodel="GPCM"
    )
    native <- irtc_rcpp_mml_2pl_mstep_item_slopes_suffstat(
        rprobs=as.vector(probabilities), items_temp=1:2,
        theta=theta, dd=0, LIT=2, TP=3, nitems=2,
        maxcat=c(2L, 2L), maxK=2, itemwt=itemwt,
        xxf_=zeros, xbar_=zeros, xbar2_=zeros,
        irtmodel="GPCM", xtemp_=matrix(0, 2, 3),
        items_conv=-1L, n_threads=2L
    )

    expect_equal(pure_r$xxf[, 1], c(0, 0))
    expect_equal(
        pure_r$xtemp,
        matrix(theta[, 1], 2, 3, byrow=TRUE) * probabilities[, 2, ]
    )
    expect_equal(native$xbar, pure_r$xbar)
    expect_equal(native$xxf, pure_r$xxf)
    expect_equal(native$xtemp, pure_r$xtemp)
})

test_that("2PL slope M-step agrees across R and native sufficient statistics", {
    arguments <- list(
        B_orig=array(c(0, 1), c(1, 2, 1)),
        B=array(c(0, 1), c(1, 2, 1)),
        B_obs=array(c(0, .5), c(1, 2, 1)), B.fixed=NULL,
        max.increment=1, nitems=1,
        A=array(c(0, -1), c(1, 2, 1)), AXsi=matrix(0, 1, 2),
        xsi=0, theta=matrix(c(-1, 1), ncol=1), nnodes=2,
        maxK=2, itemwt=matrix(1, 2, 1), Msteps=2, ndim=1,
        convM=1e-4, irtmodel="2PL", progress=FALSE,
        est.slopegroups=1, E=matrix(1), basispar=matrix(1),
        se.B=array(0, c(1, 2, 1)), equal.categ=TRUE,
        B_acceleration=list(acceleration="none"), iter=1,
        maxcat=2L, use_rcpp_calc_prob=FALSE
    )

    pure_r <- do.call(
        irtc_mml_2pl_mstep_slope, c(arguments, list(use_rcpp=FALSE))
    )
    native <- do.call(
        irtc_mml_2pl_mstep_slope, c(arguments, list(use_rcpp=TRUE))
    )

    expect_equal(native, pure_r, tolerance=1e-14)
    expect_equal(as.numeric(pure_r$B), c(0, 1.0986109988062), tolerance=1e-13)
    expect_equal(pure_r$Biter, 3)
    expect_identical(Mstep_slope.v2, irtc_mml_2pl_mstep_slope)
})
