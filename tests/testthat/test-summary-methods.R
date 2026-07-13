test_that("logLik method exposes likelihood metadata", {
    model <- list(ic=list(deviance=120, Npars=7, n=80))
    result <- logLik_irtc(model)

    expect_s3_class(result, "logLik")
    expect_equal(as.numeric(result), -60)
    expect_identical(attr(result, "df"), 7)
    expect_identical(attr(result, "nobs"), 80)
    expect_identical(logLik.irtc, logLik_irtc)
})

test_that("anova method orders models and computes a likelihood-ratio test", {
    small <- list(deviance=120, ic=list(AIC=130, BIC=140, Npars=5))
    large <- list(deviance=100, ic=list(AIC=116, BIC=130, Npars=8))

    output <- capture.output(result <- anova_irtc(small, large))

    expect_true(length(output) > 0)
    expect_identical(result$Npars, c(5, 8))
    expect_equal(result$Chisq[1], 20)
    expect_equal(result$df[1], 3)
    expect_equal(result$p[1], round(stats::pchisq(20, 3, lower.tail=FALSE), 5))
    expect_true(all(is.na(result[2, c("Chisq", "df", "p")])))
    expect_error(anova_irtc(small), "only be applied for comparison of two models")
})

test_that("summary criterion helpers format supported measures", {
    expect_identical(irtc_summary_display("=", 4), "====\n")
    expect_identical(
        irtc_summary_print_ic_description("AIC"),
        "AIC=-2*LL + 2*p"
    )
    expect_null(irtc_summary_print_ic_description("unknown"))

    ic <- list(deviance=100, AIC=108, BIC=115.6, GHP=.123456)
    output <- capture.output(irtc_summary_print_ic(
        list(ic=ic, calc_ic=TRUE), digits_ic=0, digits_values=2
    ))
    output <- paste(output, collapse="\n")
    expect_match(output, "AIC = 108 .*penalty=8")
    expect_match(output, "BIC = 116 .*penalty=15.6")
    expect_match(output, "GHP = 0.12346")
})

test_that("standardized latent-regression summary prints every component", {
    object <- list(latreg_stand=list(
        beta_stand=data.frame(term="x", estimate=.12345, standardized=.45678),
        R2_theta=c(theta=.25),
        sd_theta=c(theta=1.2),
        sd_x=c(x=.8)
    ))

    output <- capture.output(summary_irtc_print_latreg_stand(object, 3))
    output <- paste(output, collapse="\n")
    expect_match(output, "Standardized Coefficients")
    expect_match(output, "Explained Variance")
    expect_match(output, "SD Theta")
    expect_match(output, "SD Predictors")
})

test_that("summary method reports the core fitted-model sections", {
    object <- structure(list(
        irtmodel="1PL", CALL=quote(irtc.mml(resp=data)), iter=3,
        control=list(snodes=0, QMC=FALSE), theta=matrix(0, 2, 1),
        deviance=100, nstud=10, nitems=2, formulaA=NULL,
        ic=list(
            loglike=-50, n=9, Npars=4, Nparsxsi=2, NparsB=0,
            Nparsbeta=1, Nparscov=1, deviance=100, AIC=108
        ),
        calc_ic=TRUE, EAP.rel=.7, variance=matrix(1),
        beta=matrix(0, 1, 1), latreg_stand=NULL,
        item=data.frame(item=c("i1", "i2"), xsi=c(.1, -.1)),
        maxK=2, printxsi=FALSE, item_irt=NULL, G=1,
        time=as.POSIXct(c("2026-07-13 10:00:00", "2026-07-13 10:00:01"), tz="UTC")
    ), class="irtc")

    output <- capture.output(result <- summary_irtc(object))
    output <- paste(output, collapse="\n")

    expect_null(result)
    expect_match(output, "Multidimensional Item Response Model in IRTC")
    expect_match(output, "IRT Model: 1PL")
    expect_match(output, "Number of iterations = 3")
    expect_match(output, "Deviance = 100")
    expect_match(output, "EAP Reliability")
    expect_match(output, "Item Parameters -A\\*Xsi")
    expect_identical(summary.irtc, summary_irtc)
})
