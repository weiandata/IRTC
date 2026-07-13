test_that("IRT parameterization reports binary and polytomous item parameters", {
    response <- matrix(0, nrow=2, ncol=2)
    colnames(response) <- c("binary", "poly")
    slopes <- array(0, dim=c(2, 3, 1))
    slopes[, 2, 1] <- c(1, 2)
    intercepts <- matrix(
        c(0, 0, -1, -.5, NA, -1.5), nrow=2
    )

    result <- irtc_irt_parameterization(
        resp=response, maxK=3, B=slopes, AXsi=intercepts
    )

    expect_equal(result$item, c("binary", "poly"))
    expect_equal(result$alpha, c(1, 2))
    expect_equal(result$beta, c(1, .375))
    expect_true(is.na(result$`tau.Cat1`[1]))
    expect_equal(result$`tau.Cat1`[2], -.125)
    expect_equal(result$`tau.Cat2`[2], .125)

    multidimensional <- array(0, dim=c(2, 3, 2))
    expect_null(irtc_irt_parameterization(
        resp=response, maxK=3, B=multidimensional, AXsi=intercepts
    ))
})

test_that("item parameter table summarizes weighted responses and category parameters", {
    response <- matrix(c(0, 1, NA, 1, 2, 0), nrow=3)
    colnames(response) <- c("b", "a")
    response_indicator <- !is.na(response)
    intercepts <- matrix(c(0, 0, -1, -.5, NA, -1.5), nrow=2)
    slopes <- array(0, dim=c(2, 3, 1))
    slopes[, 2, 1] <- c(1, 2)
    slopes[, 3, 1] <- c(-99, 3)

    result <- irtc_itempartable(
        resp=response, maxK=3, AXsi=intercepts, B=slopes, ndim=1,
        resp.ind=response_indicator, order=TRUE, pweights=c(1, 2, 1)
    )

    expect_equal(result$item, c("a", "b"))
    expect_equal(result$N, c(4, 3))
    expect_equal(result$M, c(1.25, 2 / 3))
    expect_equal(result$xsi.item, c(.75, 1))
    expect_equal(result$AXsi_.Cat1, c(.5, 1))
    expect_equal(result$B.Cat1.Dim1, c(2, 1))
    expect_equal(result$B.Cat2.Dim1[1], 3)
    expect_true(is.na(result$B.Cat2.Dim1[2]))
    expect_identical(.IRTC.itempartable, irtc_itempartable)
})

test_that("fixed-estimated tables preserve parameter traversal order and names", {
    slopes <- array(1:8, dim=c(2, 2, 2))
    slope_table <- irtc_generate_B_fixed_estimated(slopes)

    expect_equal(
        slope_table,
        rbind(
            c(1, 1, 1, 1), c(1, 1, 2, 5),
            c(1, 2, 1, 3), c(1, 2, 2, 7),
            c(2, 1, 1, 2), c(2, 1, 2, 6),
            c(2, 2, 1, 4), c(2, 2, 2, 8)
        )
    )

    design <- array(0, dim=c(1, 1, 2), dimnames=list(NULL, NULL, c("x1", "x2")))
    xsi_table <- irtc_generate_xsi_fixed_estimated(c(.2, -.3), design)
    expect_equal(unname(xsi_table), cbind(1:2, c(.2, -.3)))
    expect_equal(rownames(xsi_table), c("x1", "x2"))
})

test_that("latent regression standardized solution reports explained variance", {
    design <- cbind(intercept=1, predictor=c(-1, 0, 1))
    result <- irtc_latent_regression_standardized_solution(
        variance=matrix(1), beta=matrix(c(.5, 2), ncol=1), Y=design
    )

    expect_equal(result$var_y_exp, 4)
    expect_equal(result$sd_theta, sqrt(5))
    expect_equal(result$R2_theta, .8)
    expect_equal(result$sd_x, c(intercept=0, predictor=1))
    expect_equal(result$beta_stand$parm, c("intercept", "predictor"))
    expect_true(is.na(result$beta_stand$StdYX[1]))
    expect_equal(result$beta_stand$StdX[2], 2)
    expect_equal(result$beta_stand$StdY[2], 2 / sqrt(5))
    expect_equal(result$beta_stand$StdYX[2], 2 / sqrt(5))

    expect_null(irtc_latent_regression_standardized_solution(
        variance=matrix(1), beta=matrix(.5), Y=matrix(1, 3, 1)
    ))
    expect_null(irtc_latent_regression_standardized_solution(
        variance=1, beta=matrix(c(.5, 2), ncol=1), Y=design
    ))
})
