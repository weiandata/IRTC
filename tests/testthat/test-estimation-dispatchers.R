test_that("probability dispatcher agrees across R and native routes", {
    design <- array(0, dim=c(2, 2, 2))
    design[, 2, 1] <- c(-1, 0)
    design[, 2, 2] <- c(0, -1)
    slopes <- array(c(0, 0, 1, .5), dim=c(2, 2, 1))
    theta <- matrix(c(-1, 0, 1), ncol=1)
    arguments <- list(
        iIndex=1:2, A=design, AXsi=matrix(0, 2, 2), B=slopes,
        xsi=c(.3, -.2), theta=theta, nnodes=3, maxK=2,
        recalc=TRUE, maxcat=c(2L, 2L)
    )

    pure_r <- do.call(irtc_mml_calc_prob, c(arguments, list(use_rcpp=FALSE)))
    native <- do.call(irtc_mml_calc_prob, c(arguments, list(use_rcpp=TRUE)))

    expect_equal(native, pure_r, tolerance=1e-14)
    expect_equal(apply(pure_r$rprobs, c(1, 3), sum), matrix(1, 2, 3))
    expect_identical(calc_prob.v5, irtc_mml_calc_prob)
    expect_identical(irtc_calc_prob, irtc_mml_calc_prob)
})

test_that("probability dispatcher falls back when native prerequisites are absent", {
    design <- array(c(0, 0, -1, -1), dim=c(2, 2, 1))
    slopes <- array(c(0, 0, 1, 1), dim=c(2, 2, 1))
    theta <- matrix(c(-1, 1), ncol=1)

    recalculated <- irtc_mml_calc_prob(
        iIndex=2:1, A=design, AXsi=matrix(0, 2, 2), B=slopes,
        xsi=.4, theta=theta, nnodes=2, maxK=2,
        use_rcpp=TRUE, maxcat=NULL, avoid_outer=TRUE
    )
    reused <- irtc_mml_calc_prob(
        iIndex=2:1, A=design, AXsi=recalculated$AXsi, B=slopes,
        xsi=99, theta=theta, nnodes=2, maxK=2,
        recalc=FALSE, use_rcpp=TRUE, maxcat=c(2L, 2L)
    )

    expect_equal(reused$rprobs, recalculated$rprobs)
    expect_equal(reused$AXsi, recalculated$AXsi)
})

test_that("R sufficient statistics encode categories and weighted item scores", {
    response <- matrix(c(0, 2, 1, 1, 2, 0), nrow=3, byrow=TRUE)
    response_indicator <- matrix(1, nrow=3, ncol=2)
    column_index <- c(1, 1, 1, 2, 2, 2)
    compressed_design <- matrix(1:12, nrow=6, ncol=2)

    result <- irtc_mml_sufficient_statistics_R(
        nitems=2, maxK=3, resp=response, resp.ind=response_indicator,
        pweights=c(1, 2, 3), cA=compressed_design,
        col.index=column_index
    )

    expected_response <- rbind(
        c(1, 0, 0, 0, 0, 1),
        c(0, 1, 0, 0, 1, 0),
        c(0, 0, 1, 1, 0, 0)
    )
    expected_counts <- colSums(expected_response * c(1, 2, 3))
    expect_equal(result$cResp, expected_response)
    expect_equal(
        result$ItemScore,
        as.vector(t(expected_counts) %*% compressed_design)
    )
})

test_that("constant person weights retain the unweighted sufficient-statistic path", {
    response <- matrix(c(0, 2, 1, 1, 2, 0), nrow=3, byrow=TRUE)
    result <- irtc_mml_sufficient_statistics_R(
        nitems=2, maxK=3, resp=response,
        resp.ind=matrix(1, 3, 2), pweights=rep(2, 3),
        cA=matrix(1:12, 6, 2), col.index=c(1, 1, 1, 2, 2, 2)
    )

    expect_equal(result$ItemScore, c(21, 57))
})
