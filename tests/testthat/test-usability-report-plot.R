# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-usability-report-plot.R
## Tests for plot.irtc(), irtc_report() and the base64/html helpers.

irtc_test_sim_report <- function(n=180, k=6, seed=31)
{
    set.seed(seed)
    theta <- stats::rnorm(n)
    b <- seq(-1, 1, length.out=k)
    resp <- sapply(seq_len(k), function(j) {
        as.numeric(stats::runif(n) < stats::plogis(theta - b[j]))
    })
    colnames(resp) <- paste0("I", seq_len(k))
    as.data.frame(resp)
}

test_that("plot.irtc renders all plot types without error", {
    resp <- irtc_test_sim_report()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    path <- tempfile(fileext=".png")
    for (type in c("wright", "ability", "quality", "icc")) {
        grDevices::png(path)
        expect_error(plot(mod, type=type, lang="en"), NA)
        grDevices::dev.off()
    }
    unlink(path)
})

test_that("base64 encoder matches known vectors", {
    expect_equal(irtc_base64_encode(charToRaw("Man")), "TWFu")
    expect_equal(irtc_base64_encode(charToRaw("Ma")), "TWE=")
    expect_equal(irtc_base64_encode(charToRaw("M")), "TQ==")
    expect_equal(irtc_base64_encode(charToRaw("hello world!")),
        "aGVsbG8gd29ybGQh")
    expect_equal(irtc_base64_encode(raw(0)), "")
})

test_that("html helpers escape and tabulate", {
    expect_equal(irtc_html_escape("a<b & c>d"), "a&lt;b &amp; c&gt;d")
    html <- irtc_html_table(data.frame(x=1:2, y=c("a", "<b>")))
    expect_match(html, "<th>x</th>")
    expect_match(html, "&lt;b&gt;")
})

test_that("irtc_report writes self-contained html for all audiences", {
    resp <- irtc_test_sim_report()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    for (aud in c("decision", "survey", "stat")) {
        file <- tempfile(fileext=".html")
        suppressMessages(irtc_report(mod, file, audience=aud, lang="zh",
            verbose=FALSE))
        expect_true(file.exists(file))
        html <- paste(readLines(file, encoding="UTF-8"), collapse="\n")
        expect_match(html, "data:image/png;base64,")
        expect_match(html, "IRT \u5206\u6790\u62a5\u544a")
        unlink(file)
    }
    ## english
    file <- tempfile(fileext=".html")
    suppressMessages(irtc_report(mod, file, audience="decision", lang="en",
        verbose=FALSE))
    html <- paste(readLines(file, encoding="UTF-8"), collapse="\n")
    expect_match(html, "IRT Analysis Report")
    unlink(file)
})

test_that("irtc_report writes docx when officer is available", {
    testthat::skip_if_not_installed("officer")
    resp <- irtc_test_sim_report()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    file <- tempfile(fileext=".docx")
    suppressMessages(irtc_report(mod, file, audience="survey",
        verbose=FALSE))
    expect_true(file.exists(file))
    expect_gt(file.info(file)$size, 10000)
    unlink(file)
})

test_that("irtc_report validates format and overwrite", {
    resp <- irtc_test_sim_report()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    cond <- tryCatch(irtc_report(mod, "report.pdf", verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond$code, "E503")

    file <- tempfile(fileext=".html")
    suppressMessages(irtc_report(mod, file, verbose=FALSE))
    cond2 <- tryCatch(irtc_report(mod, file, verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond2$code, "E501")
    unlink(file)

    cond3 <- tryCatch(irtc_report(42, "x.html"), condition=function(c) c)
    expect_equal(cond3$code, "E401")
})

test_that("irtc_report creates missing output directories", {
    resp <- irtc_test_sim_report()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    nested <- file.path(tempfile(), "deep", "report.html")
    expect_false(dir.exists(dirname(nested)))
    suppressMessages(irtc_report(mod, nested, audience="stat",
        lang="en", verbose=FALSE))
    expect_true(file.exists(nested))
    unlink(dirname(dirname(nested)), recursive=TRUE)
})
