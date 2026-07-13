test_that("person EAP helpers compute posterior moments and reliability", {
    posterior <- matrix(
        c(.25, .5, .25, 0, .25, .75), nrow=2, byrow=TRUE
    )
    nodes <- c(-1, 0, 1)

    eap <- irtc_mml_person_EAP(hwt=posterior, theta=nodes)
    standard_deviation <- irtc_mml_person_SD_EAP(
        hwt=posterior, theta=nodes, EAP=eap
    )
    reliability <- irtc_mml_person_EAP_rel(
        EAP=eap, SD.EAP=standard_deviation, pweights=c(1, 2)
    )

    expect_equal(eap, c(0, .75))
    expect_equal(standard_deviation, sqrt(c(.5, .1875)))
    expected_variance <- weighted_mean(eap^2, c(1, 2)) -
        weighted_mean(eap, c(1, 2))^2
    expected_error <- weighted_mean(standard_deviation^2, c(1, 2))
    expect_equal(reliability, expected_variance / (expected_variance + expected_error))
})

test_that("person maximum score respects each response indicator", {
    response <- matrix(c(0, 0, 1, 2, 2, 1), nrow=3, byrow=TRUE)
    indicator <- matrix(
        c(TRUE, TRUE, TRUE, FALSE, FALSE, TRUE), nrow=3, byrow=TRUE
    )

    expect_equal(
        irtc_mml_person_maxscore(response, indicator), c(4, 2, 2)
    )
    expect_equal(irtc_mml_person_maxscore(response), rep(4, 3))
})

test_that("unidimensional person posterior returns scores and population moments", {
    posterior <- matrix(
        c(.25, .5, .25, 0, .25, .75), nrow=2, byrow=TRUE
    )
    response <- matrix(c(0, 1, 1, 2), nrow=2, byrow=TRUE)

    result <- irtc_mml_person_posterior(
        pid=c("p1", "p2"), nstud=2, pweights=c(1, 2),
        resp=response, resp.ind=matrix(1, 2, 2), snodes=0,
        hwtE=matrix(99, 1, 1), hwt=posterior, ndim=1,
        theta=matrix(c(-1, 0, 1), ncol=1)
    )

    expect_equal(result$person$score, c(1, 3))
    expect_equal(result$person$max, c(3, 3))
    expect_equal(result$person$EAP, c(0, .75))
    expect_equal(result$person$SD.EAP, sqrt(c(.5, .1875)))
    expect_equal(result$M_post, .5)
    expect_equal(result$SD_post, sqrt(2 / 3 - .25))
    expect_equal(
        result$EAP.rel,
        irtc_mml_person_EAP_rel(
            result$person$EAP, result$person$SD.EAP, c(1, 2)
        )
    )
})

test_that("multidimensional person posterior names dimension-specific results", {
    posterior <- matrix(
        c(.25, .5, .25, 0, .25, .75), nrow=2, byrow=TRUE
    )
    theta <- cbind(Dim1=c(-1, 0, 1), Dim2=c(1, 0, -1))

    result <- irtc_mml_person_posterior(
        pid=1:2, nstud=2, pweights=c(1, 2), resp=NULL,
        resp.ind=NULL, snodes=0, hwtE=NULL, hwt=posterior,
        ndim=2, theta=theta
    )

    expect_true(all(c(
        "EAP.Dim1", "SD.EAP.Dim1", "EAP.Dim2", "SD.EAP.Dim2"
    ) %in% names(result$person)))
    expect_equal(result$person$EAP.Dim1, c(0, .75))
    expect_equal(result$person$EAP.Dim2, c(0, -.75))
    expect_equal(result$M_post, c(.5, -.5))
    expect_equal(result$SD_post, rep(sqrt(2 / 3 - .25), 2))
    expect_equal(names(result$EAP.rel), c("Dim1", "Dim2"))
})
