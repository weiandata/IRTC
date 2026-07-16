# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-usability-read.R
## Tests for irtc_read(): format support, cleaning, ID handling, logging.

irtc_test_grab_condition <- function(expr)
{
    tryCatch(expr, condition=function(cond) cond)
}

test_that("irtc_read accepts data frames and matrices", {
    df <- data.frame(i1=c(0, 1, 1), i2=c(1, 0, 1))
    out <- irtc_read(df, verbose=FALSE)
    expect_s3_class(out, "irtc_data")
    expect_equal(dim(out$resp), c(3L, 2L))
    expect_null(out$pid)

    mat <- matrix(c(0, 1, 1, 0), nrow=2,
        dimnames=list(NULL, c("a", "b")))
    out_mat <- irtc_read(mat, verbose=FALSE)
    expect_equal(out_mat$resp$a, c(0, 1))
})

test_that("irtc_read reads csv and tsv with delimiter detection", {
    path_csv <- tempfile(fileext=".csv")
    writeLines(c("id,i1,i2", "s1,0,1", "s2,1,0"), path_csv)
    out <- irtc_read(path_csv, verbose=FALSE)
    expect_equal(colnames(out$resp), c("i1", "i2"))
    expect_equal(out$pid, c("s1", "s2"))

    path_tsv <- tempfile(fileext=".txt")
    writeLines(c("i1\ti2", "0\t1", "1\t0"), path_tsv)
    out_tsv <- irtc_read(path_tsv, verbose=FALSE)
    expect_equal(out_tsv$resp$i2, c(1, 0))

    path_semi <- tempfile(fileext=".csv")
    writeLines(c("i1;i2", "0;1", "1;0"), path_semi)
    out_semi <- irtc_read(path_semi, verbose=FALSE)
    expect_equal(colnames(out_semi$resp), c("i1", "i2"))
})

test_that("irtc_read detects the person ID by common column names", {
    df <- data.frame(ID=c("a", "b"), i1=c(0, 1), i2=c(1, 1))
    out <- irtc_read(df, verbose=FALSE)
    expect_equal(out$pid, c("a", "b"))
    expect_equal(colnames(out$resp), c("i1", "i2"))

    ## explicit id wins; extra id columns are set aside
    df2 <- data.frame(code=c("x", "y"), i1=c(0, 1), i2=c(1, 0))
    out2 <- irtc_read(df2, id="code", verbose=FALSE)
    expect_equal(out2$pid, c("x", "y"))

    ## duplicated ids are logged, not fatal
    df3 <- data.frame(id=c("a", "a"), i1=c(0, 1), i2=c(1, 0))
    out3 <- irtc_read(df3, verbose=FALSE)
    expect_true(any(out3$log$code == "W113"))
})

test_that("irtc_read cleans missing codes with the range guard", {
    df <- data.frame(i1=c(0, 1, 99), i2=c(1, -9, 0), i3=c(10, 99, 100))
    out <- irtc_read(df, verbose=FALSE, recode=FALSE)
    ## 99 is far above the 0/1 range -> NA
    expect_true(is.na(out$resp$i1[3]))
    ## negative codes are always missing
    expect_true(is.na(out$resp$i2[2]))
    ## 99 lies inside the observed 10-100 score range -> kept
    expect_false(is.na(out$resp$i3[2]))
})

test_that("irtc_read converts text numbers and NA strings", {
    df <- data.frame(i1=c(" 1", "0", ""), i2=c("2", "N/A", "1"),
        raw=c("A", "B", "C"), stringsAsFactors=FALSE)
    out <- irtc_read(df, verbose=FALSE, recode=FALSE)
    expect_true(is.numeric(out$resp$i1))
    expect_true(is.na(out$resp$i1[3]))
    expect_true(is.na(out$resp$i2[2]))
    ## letter responses stay character for later scoring
    expect_true(is.character(out$resp$raw))
})

test_that("irtc_read recodes categories to consecutive 0-based scores", {
    df <- data.frame(likert=c(1, 2, 5, 3), gap=c(0, 2, 4, 2),
        ok=c(0, 1, 0, 1))
    out <- irtc_read(df, verbose=FALSE)
    expect_equal(out$resp$likert, c(0, 1, 3, 2))
    expect_equal(out$resp$gap, c(0, 1, 2, 1))
    expect_equal(out$resp$ok, c(0, 1, 0, 1))
    expect_true(any(out$log$code == "I124"))
})

test_that("irtc_read drops empty rows and columns", {
    df <- data.frame(i1=c(0, NA, 1), i2=c(1, NA, 0), i3=c(NA, NA, NA))
    out <- irtc_read(df, verbose=FALSE)
    expect_equal(ncol(out$resp), 2L)
    expect_equal(nrow(out$resp), 2L)
})

test_that("irtc_read raises structured errors", {
    cond <- irtc_test_grab_condition(irtc_read(1:5, verbose=FALSE))
    expect_s3_class(cond, "irtc_error")
    expect_equal(cond$code, "E101")
    expect_true(nzchar(cond$fix))

    cond2 <- irtc_test_grab_condition(irtc_read("no-such-file.csv",
        verbose=FALSE))
    expect_equal(cond2$code, "E103")

    path <- tempfile(fileext=".xyz")
    writeLines("a,b", path)
    cond3 <- irtc_test_grab_condition(irtc_read(path, verbose=FALSE))
    expect_equal(cond3$code, "E105")

    df_empty <- data.frame(i1=numeric(0))
    cond4 <- irtc_test_grab_condition(irtc_read(df_empty, verbose=FALSE))
    expect_equal(cond4$code, "E104")
})

test_that("irtc_read reads GBK encoded csv files", {
    path <- tempfile(fileext=".csv")
    txt <- c("\u5b66\u53f7,i1,i2", "s1,0,1", "s2,1,0")
    gbk <- iconv(txt, from="UTF-8", to="GB18030")
    con <- file(path, open="wb")
    writeLines(gbk, con, useBytes=TRUE)
    close(con)
    out <- irtc_read(path, verbose=FALSE)
    expect_equal(out$pid, c("s1", "s2"))
    expect_equal(colnames(out$resp), c("i1", "i2"))
})

test_that("irtc_read reads xlsx files when readxl is available", {
    testthat::skip_if_not_installed("readxl")
    testthat::skip_if_not_installed("writexl")
    path <- tempfile(fileext=".xlsx")
    writexl::write_xlsx(data.frame(id=c("a", "b"), i1=c(0, 1),
        i2=c(1, 0)), path)
    out <- irtc_read(path, verbose=FALSE)
    expect_equal(out$pid, c("a", "b"))
    expect_equal(out$resp$i1, c(0, 1))
})

test_that("language option switches messages", {
    old <- options(irtc.lang="en")
    on.exit(options(old))
    cond <- irtc_test_grab_condition(irtc_read("no-such-file.csv",
        verbose=FALSE))
    expect_match(cond$message, "File not found")
    options(irtc.lang="zh")
    cond_zh <- irtc_test_grab_condition(irtc_read("no-such-file.csv",
        verbose=FALSE))
    expect_match(cond_zh$message, "\u627e\u4e0d\u5230")
})
