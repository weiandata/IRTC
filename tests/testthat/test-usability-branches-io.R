# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-usability-branches-io.R
## Branch-coverage tests for the data input layer: irtc_read, irtc_score,
## irtc_check_data, the condition system and the language helper.

test_that("irtc_lang falls back to zh on invalid options", {
    old <- options(irtc.lang="fr")
    on.exit(options(old))
    expect_equal(irtc_lang(), "zh")
    options(irtc.lang=c("en", "zh"))
    expect_equal(irtc_lang(), "zh")
    options(irtc.lang="en")
    expect_equal(irtc_lang(), "en")
})

test_that("condition system exposes machine-readable fields", {
    cond <- tryCatch(irtc_require("nonexistentpkg12345",
        purpose_en="test", purpose_zh="test"), condition=function(c) c)
    expect_s3_class(cond, "irtc_error_missing_package")
    expect_equal(cond$code, "E001")
    expect_equal(cond$data$package, "nonexistentpkg12345")
    expect_true(nzchar(cond$fix))
    expect_true(nzchar(cond$reason_en))

    warn <- tryCatch(
        irtc_warn(code="W999", en="test warning", zh="test warning",
            fix_en="do this", fix_zh="do this",
            class="irtc_warning_test"),
        warning=function(w) w)
    expect_s3_class(warn, "irtc_warning")
    expect_equal(warn$code, "W999")
    expect_equal(warn$fix_en, "do this")

    ## message without a fix has no Fix line
    cond2 <- tryCatch(irtc_stop(code="E998", en="x", zh="x"),
        condition=function(c) c)
    expect_false(grepl("Fix", cond2$message))
})

test_that("irtc_read handles explicit id columns and errors", {
    df <- data.frame(code=c("x", "y"), name=c("n1", "n2"),
        i1=c(0, 1), i2=c(1, 0), stringsAsFactors=FALSE)
    ## multiple explicit id columns: first kept, rest set aside
    out <- irtc_read(df, id=c("code", "name"), verbose=FALSE)
    expect_equal(out$pid, c("x", "y"))
    expect_true("name" %in% names(out$dropped))
    expect_equal(colnames(out$resp), c("i1", "i2"))

    ## numeric id index
    out2 <- irtc_read(df[, c(1, 3, 4)], id=1, verbose=FALSE)
    expect_equal(out2$pid, c("x", "y"))

    ## unknown id column -> E106
    cond <- tryCatch(irtc_read(df, id="nope", verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond$code, "E106")

    ## multiple paths -> E102
    cond2 <- tryCatch(irtc_read(c("a.csv", "b.csv"), verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond2$code, "E102")

    ## guess_id=FALSE keeps the id column as data
    out3 <- irtc_read(data.frame(id=c("a", "b"), i1=c(0, 1)),
        guess_id=FALSE, verbose=FALSE)
    expect_null(out3$pid)
    expect_true("id" %in% colnames(out3$resp))
})

test_that("irtc_read handles clean=FALSE, empty names and factors", {
    df <- data.frame(a=c(0, 99), b=c(1, 0))
    out <- irtc_read(df, clean=FALSE, verbose=FALSE)
    expect_equal(out$resp$a[2], 99)

    df2 <- data.frame(a=1:2, b=3:4)
    colnames(df2) <- c("", "b")
    out2 <- irtc_read(df2, verbose=FALSE, recode=FALSE)
    expect_true("V1" %in% colnames(out2$resp))

    df3 <- data.frame(f=factor(c("A", "B", "A")), i1=c(0, 1, 1))
    out3 <- irtc_read(df3, verbose=FALSE)
    expect_true(is.character(out3$resp$f))

    ## missing_codes=NULL disables recoding to NA
    out4 <- irtc_read(data.frame(i1=c(0, 1, 99), i2=c(1, 0, 1)),
        missing_codes=NULL, recode=FALSE, verbose=FALSE)
    expect_equal(out4$resp$i1[3], 99)
})

test_that("irtc_read skips recoding for non-integer and many categories", {
    frac <- data.frame(x=c(0.5, 1.5, 2.5), y=c(0, 1, 2))
    out <- irtc_read(frac, verbose=FALSE)
    expect_equal(out$resp$x, c(0.5, 1.5, 2.5))

    big <- data.frame(v=seq(0, 62, by=2), w=rep(c(0, 1), length.out=32))
    out2 <- irtc_read(big, verbose=FALSE)
    ## 32 distinct gapped categories: left untouched
    expect_equal(out2$resp$v, seq(0, 62, by=2))
})

test_that("irtc_read reads BOM, pipe and single-column files", {
    bom <- tempfile(fileext=".csv")
    writeBin(c(as.raw(c(0xEF, 0xBB, 0xBF)),
        charToRaw("i1,i2\n0,1\n1,0\n")), bom)
    out <- irtc_read(bom, verbose=FALSE)
    expect_equal(colnames(out$resp), c("i1", "i2"))

    pipe_file <- tempfile(fileext=".txt")
    writeLines(c("i1|i2", "0|1", "1|0"), pipe_file)
    out2 <- irtc_read(pipe_file, verbose=FALSE)
    expect_equal(out2$resp$i2, c(1, 0))

    single <- tempfile(fileext=".csv")
    writeLines(c("i1", "0", "1"), single)
    out3 <- irtc_read(single, verbose=FALSE, recode=FALSE)
    expect_equal(ncol(out3$resp), 1L)
    unlink(c(bom, pipe_file, single))
})

test_that("irtc_score covers partial keys, rules on irtc_data and E201", {
    resp <- data.frame(Q1=c("A", "B"), Q2=c("C", "D"),
        stringsAsFactors=FALSE)
    ## partial key: unkeyed columns stay raw
    out <- irtc_score(resp, key=c(Q1="A"))
    expect_equal(out$Q1, c(1, 0))
    expect_true(is.character(out$Q2))

    ## rules applied through an irtc_data object
    obj <- irtc_read(resp, verbose=FALSE)
    rules <- data.frame(item=c("Q1", "Q1", "Q2", "Q2"),
        response=c("A", "B", "C", "D"), score=c(1, 0, 2, 0),
        stringsAsFactors=FALSE)
    scored <- irtc_score(obj, rules=rules)
    expect_s3_class(scored, "irtc_data")
    expect_equal(scored$resp$Q2, c(2, 0))
    expect_true(any(scored$log$code == "I201"))

    ## invalid resp type
    cond <- tryCatch(irtc_score(1:3, key="A"), condition=function(c) c)
    expect_equal(cond$code, "E201")

    ## non-numeric scores in rules
    bad_rules <- data.frame(item="Q1", response="A", score="full",
        stringsAsFactors=FALSE)
    cond2 <- tryCatch(irtc_score(resp, rules=bad_rules),
        condition=function(c) c)
    expect_equal(cond2$code, "E206")
})

test_that("irtc_check_data covers persons, missingness and sparse cats", {
    ## single person -> E303
    chk <- irtc_check_data(data.frame(i1=1, i2=0), verbose=FALSE)
    expect_true("E303" %in% chk$issues$code)

    ## invalid input -> E301
    cond <- tryCatch(irtc_check_data(1:3, verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond$code, "E301")

    ## >90% missing -> W311
    n <- 40
    high_miss <- data.frame(
        i1=c(0, 1, rep(NA_real_, n - 2)),
        i2=rep(c(0, 1), n / 2))
    chk2 <- irtc_check_data(high_miss, verbose=FALSE)
    expect_true("W311" %in% chk2$issues$code)

    ## sparse polytomous category -> I312
    sparse <- data.frame(
        p1=c(rep(0, 20), rep(1, 17), rep(2, 3)),
        p2=rep(c(0, 1, 2), length.out=40))
    chk3 <- irtc_check_data(sparse, verbose=FALSE)
    expect_true("I312" %in% chk3$issues$code)

    ## healthy data prints the no-issue branch
    set.seed(9)
    ok <- as.data.frame(matrix(rep(c(0, 1), 100) [
        sample.int(200)], nrow=50))
    chk4 <- irtc_check_data(ok, verbose=FALSE)
    if (nrow(chk4$issues) == 0L) {
        expect_output(print(chk4, lang="en"), "No issues found")
    }
    expect_output(print(chk2, lang="en"), "WARNING")
})
