test_that("call printer shows ordinary calls and suppresses oversized calls", {
    ordinary <- capture.output(irtc_print_call(quote(irtc.mml(resp=data))))
    expect_match(
        paste(ordinary, collapse="\n"), "(?s)Call:.*irtc.mml", perl=TRUE
    )

    oversized <- as.call(c(as.name("f"), list(paste(rep("x", 3001), collapse=""))))
    expect_length(capture.output(irtc_print_call(oversized)), 0)
})

test_that("package and session helpers report runtime identity", {
    package <- irtc_packageinfo("IRTC")
    session <- irtc_rsessinfo()

    ## The trailing parentheses carry the DESCRIPTION Date field; require a
    ## date so a missing field cannot silently print "IRTC 1.1.1 ()".
    expect_match(package, "^IRTC [^ ]+ \\(\\d{4}-\\d{2}-\\d{2}\\)$")
    ## R.version.string is "R version x.y.z ..." on released R but
    ## "R Under development (unstable) ..." on r-devel, so match it
    ## literally rather than assuming the released wording.
    expect_true(startsWith(session, R.version.string))
    expect_match(session, " \\| nodename=")
    expect_match(session, " \\| login=")

    combined <- paste(
        capture.output(irtc_print_package_rsession("IRTC")),
        collapse="\n"
    )
    expect_match(combined, package, fixed=TRUE)
    expect_match(combined, R.version.string, fixed=TRUE)
})

test_that("computation-time printer reports date and elapsed duration", {
    object <- list(time=as.POSIXct(
        c("2026-07-13 10:00:00", "2026-07-13 10:00:02"), tz="UTC"
    ))

    output <- paste(capture.output(irtc_print_computation_time(object)), collapse="\n")
    expect_match(output, "Date of Analysis: 2026-07-13 10:00:02")
    expect_match(output, "Time difference of 2 secs")
})

test_that("print method emits compact model fit information", {
    model <- structure(list(
        CALL=quote(irtc.mml(resp=data)), deviance=100,
        ic=list(n=9, Npars=4, AIC=108, BIC=115)
    ), class="irtc")

    output <- paste(capture.output(result <- print_irtc(model)), collapse="\n")
    expect_null(result)
    expect_match(output, "Multidimensional Item Response Model in IRTC")
    expect_match(output, "Deviance= 100 .* Log Likelihood= -50")
    expect_match(output, "Number of persons used= 9")
    expect_match(output, "AIC= 108")
    expect_match(output, "BIC= 115")
    expect_identical(print.irtc, print_irtc)
})
