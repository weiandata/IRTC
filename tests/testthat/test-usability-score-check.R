# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-usability-score-check.R
## Tests for irtc_score() and irtc_check_data().

test_that("irtc_score scores against a named answer key", {
    resp <- data.frame(Q1=c("A", "b", " C", NA),
        Q2=c("\uff21", "B", "D", "B"), stringsAsFactors=FALSE)
    key <- c(Q1="A", Q2="B")
    out <- irtc_score(resp, key=key)
    expect_equal(out$Q1, c(1, 0, 0, NA))
    ## full-width A normalises to A -> wrong answer for key B
    expect_equal(out$Q2, c(0, 1, 0, 1))

    out2 <- irtc_score(resp, key=key, na_as_wrong=TRUE)
    expect_equal(out2$Q1[4], 0)
})

test_that("irtc_score works with unnamed keys and irtc_data objects", {
    resp <- data.frame(Q1=c("A", "B"), Q2=c("C", "C"),
        stringsAsFactors=FALSE)
    out <- irtc_score(resp, key=c("A", "C"))
    expect_equal(out$Q1, c(1, 0))
    expect_equal(out$Q2, c(1, 1))

    obj <- irtc_read(resp, verbose=FALSE)
    scored <- irtc_score(obj, key=c("A", "C"))
    expect_s3_class(scored, "irtc_data")
    expect_equal(scored$resp$Q1, c(1, 0))
    expect_true(any(scored$log$code == "I200"))
})

test_that("irtc_score applies partial-credit rules", {
    resp <- data.frame(Q1=c("A", "B", "C", "X"), stringsAsFactors=FALSE)
    rules <- data.frame(item="Q1", response=c("A", "B", "C"),
        score=c(2, 1, 0), stringsAsFactors=FALSE)
    expect_warning(out <- irtc_score(resp, rules=rules),
        class="irtc_warning_scoring")
    expect_equal(out$Q1, c(2, 1, 0, NA))
})

test_that("irtc_score raises structured errors", {
    resp <- data.frame(Q1=c("A", "B"), stringsAsFactors=FALSE)
    cond <- tryCatch(irtc_score(resp), condition=function(c) c)
    expect_equal(cond$code, "E202")

    cond2 <- tryCatch(irtc_score(resp, key=c("A", "B", "C")),
        condition=function(c) c)
    expect_equal(cond2$code, "E203")

    cond3 <- tryCatch(irtc_score(resp, key=c(QX="A")),
        condition=function(c) c)
    expect_equal(cond3$code, "E204")

    cond4 <- tryCatch(irtc_score(resp,
        rules=data.frame(a=1, b=2)), condition=function(c) c)
    expect_equal(cond4$code, "E205")
})

test_that("irtc_check_data flags structural problems", {
    ## healthy data
    set.seed(1)
    ok_data <- as.data.frame(matrix(rbinom(200, 1, 0.5), nrow=50))
    chk <- irtc_check_data(ok_data, verbose=FALSE)
    expect_true(chk$ok)
    expect_equal(chk$n_errors, 0L)

    ## single item
    chk1 <- irtc_check_data(data.frame(i1=c(0, 1, 1)), verbose=FALSE)
    expect_false(chk1$ok)
    expect_true("E302" %in% chk1$issues$code)

    ## small sample warning
    small <- data.frame(i1=c(0, 1, 1), i2=c(1, 0, 1))
    chk2 <- irtc_check_data(small, verbose=FALSE)
    expect_true("W304" %in% chk2$issues$code)

    ## character columns without a key are an error, with a key only info
    raw <- data.frame(Q1=c("A", "B"), Q2=c("C", "D"),
        stringsAsFactors=FALSE)
    chk3 <- irtc_check_data(raw, verbose=FALSE)
    expect_true("E305" %in% chk3$issues$code)
    chk4 <- irtc_check_data(raw, key=c(Q1="A", Q2="C"), verbose=FALSE)
    expect_false("E305" %in% chk4$issues$code)
    expect_true("I306" %in% chk4$issues$code)
})

test_that("irtc_check_data flags item and person problems", {
    df <- data.frame(
        neg=c(-5, 0, 1, 0, 1),
        frac=c(0.5, 1, 0, 1, 0),
        const=c(1, 1, 1, 1, 1),
        empty=rep(NA_real_, 5),
        ok=c(0, 1, 0, 1, 1)
    )
    chk <- irtc_check_data(df, verbose=FALSE)
    codes <- chk$issues$code
    expect_true("E308" %in% codes)
    expect_true("E309" %in% codes)
    expect_true("W310" %in% codes)
    expect_true("W307" %in% codes)
    expect_false(chk$ok)

    ## all-NA person and duplicated pid via irtc_data (clean=FALSE keeps
    ## the empty row so the check itself must flag it)
    df2 <- data.frame(id=c("a", "a", "b"), i1=c(NA, 0, 1),
        i2=c(NA, 1, 0), stringsAsFactors=FALSE)
    obj <- irtc_read(df2, clean=FALSE, verbose=FALSE)
    chk2 <- irtc_check_data(obj, verbose=FALSE)
    expect_true("W313" %in% chk2$issues$code)
    expect_true("W314" %in% chk2$issues$code)
})

test_that("print methods run without error in both languages", {
    df <- data.frame(id=c("a", "b", "c"), i1=c(0, 1, 1), i2=c(1, 0, 1),
        stringsAsFactors=FALSE)
    obj <- irtc_read(df, verbose=FALSE)
    chk <- irtc_check_data(obj, verbose=FALSE)
    for (lang in c("zh", "en")) {
        expect_output(print(obj, lang=lang))
        expect_output(print(chk, lang=lang))
    }
})
