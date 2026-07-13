test_that("EM progress reports objective and parameter changes", {
    output <- paste(capture.output(irtc_mml_progress_em(
        progress=TRUE, deviance=100.12345, deviance_change=1, iter=2,
        rel_deviance_change=.00123456789, xsi_change=.1, beta_change=.2,
        variance_change=.3, B_change=.4, devch=.5
    )), collapse="\n")

    expect_match(output, "Deviance = 100.1234")
    expect_match(output, "Absolute change: 0.5")
    expect_match(output, "Relative change: 0.00123457")
    expect_match(output, "Maximum item intercept parameter change: 0.1")
    expect_match(output, "Maximum variance parameter change: 0.3")
    expect_length(capture.output(irtc_mml_progress_em(
        progress=FALSE, deviance=1, deviance_change=1, iter=1,
        rel_deviance_change=1, xsi_change=1, beta_change=1,
        variance_change=1, B_change=1, devch=1
    )), 0)
})

test_that("regularized and alternative-skill progress uses its own fields", {
    output <- paste(capture.output(irtc_mml_progress_em(
        progress=TRUE, deviance=90, deviance_change=1, iter=2,
        rel_deviance_change=.1, xsi_change=.2, beta_change=.3,
        variance_change=.4, B_change=.5, is_mml_3pl=TRUE,
        guess_change=.6, skillspace="discrete", delta_change=.7,
        devch=-1, penalty_xsi=2, is_np=TRUE, np_change=.8,
        par_reg_penalty=c(1, 2), n_reg=c(1, 0), AIC=110,
        n_est=4, n_reg_max=2
    )), collapse="\n")

    expect_match(output, "Log posterior = 90")
    expect_match(output, "Penalty function value: 3")
    expect_match(output, "Optimization function value: 93")
    expect_match(output, "Maximum item guessing parameter change: 0.6")
    expect_match(output, "Maximum item parameter change: 0.8")
    expect_match(output, "Maximum delta parameter change: 0.7")
})

test_that("iteration and node progress select the integration description", {
    iteration <- paste(capture.output(
        irtc_mml_progress_em0(TRUE, 3, "--\n", print_estep=TRUE)
    ), collapse="\n")
    expect_match(iteration, "Iteration 3")
    expect_match(iteration, "E Step")

    numeric <- capture.output(irtc_mml_progress_proc_nodes(TRUE, 0, 21))
    qmc <- capture.output(irtc_mml_progress_proc_nodes(
        TRUE, 100, 9000, maxnodes=8000, QMC=TRUE
    ))
    expect_match(numeric, "Numerical integration with 21 nodes")
    expect_match(qmc[1], "Quasi Monte Carlo integration with 9000 nodes")
    expect_match(qmc[2], "Are you sure")
    expect_length(capture.output(irtc_mml_progress_proc_nodes(
        TRUE, 0, 21, skillspace="discrete"
    )), 0)
})

test_that("multiple-group guard rejects unsupported multidimensional fits", {
    expect_error(
        irtc_mml_warning_message_multiple_group_models(2, 2),
        "Multiple group estimation is not.*supported"
    )
    expect_null(irtc_mml_warning_message_multiple_group_models(1, 2))
    expect_null(irtc_mml_warning_message_multiple_group_models(2, 2, disable=TRUE))
})

test_that("package lifecycle helpers expose version and alignment text", {
    info <- IRTC:::version("IRTC")
    expect_match(info, "^IRTC [^ ]+  ")
    expect_match(
        info, normalizePath(dirname(system.file(package="IRTC"))), fixed=TRUE
    )
    expect_identical(IRTC:::xx(2, 3), "  =   ")
    expect_message(IRTC:::.onAttach(NULL, "IRTC"), "\\* IRTC")
})
