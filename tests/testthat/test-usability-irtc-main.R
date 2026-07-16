# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-usability-irtc-main.R
## Tests for the one-stop irtc() entry point and plain_summary().

irtc_test_sim_main <- function(n=200, k=6, seed=11)
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

test_that("irtc requires a valid model argument", {
    resp <- irtc_test_sim_main()
    cond <- tryCatch(irtc(resp), condition=function(c) c)
    expect_equal(cond$code, "E406")
    cond2 <- tryCatch(irtc(resp, model="3PL"), condition=function(c) c)
    expect_equal(cond2$code, "E406")
})

test_that("irtc runs end to end on a data frame", {
    resp <- irtc_test_sim_main()
    mod <- irtc(resp, model="Rasch", verbose=FALSE)
    expect_s3_class(mod, "irtc")
    expect_equal(mod$nitems, 6L)
    expect_equal(mod$nstud, 200L)
    expect_equal(mod$usability$model, "1PL")
    expect_s3_class(mod$usability$quality, "irtc_quality")
    expect_s3_class(mod$usability$itemfit, "irtc_itemfit")
    expect_s3_class(mod$usability$ctt, "irtc_ctt")
})

test_that("irtc runs from a csv file with an ID column and 2PL", {
    resp <- irtc_test_sim_main(n=150, k=5)
    path <- tempfile(fileext=".csv")
    utils::write.csv(cbind(id=paste0("S", seq_len(nrow(resp))), resp),
        path, row.names=FALSE)
    mod <- irtc(path, model="2PL", verbose=FALSE)
    expect_s3_class(mod, "irtc")
    expect_equal(mod$nitems, 5L)
    expect_equal(as.character(mod$pid)[1L], "S1")
})

test_that("irtc scores raw responses with a key", {
    set.seed(3)
    n <- 120
    theta <- stats::rnorm(n)
    correct <- c("A", "B", "C", "D")
    resp <- as.data.frame(lapply(seq_along(correct), function(j) {
        hit <- stats::runif(n) < stats::plogis(theta)
        ifelse(hit, correct[j], sample(setdiff(LETTERS[1:4], correct[j]),
            n, replace=TRUE))
    }), stringsAsFactors=FALSE)
    colnames(resp) <- paste0("Q", 1:4)
    mod <- irtc(resp, model="1PL", key=c(Q1="A", Q2="B", Q3="C", Q4="D"),
        verbose=FALSE)
    expect_s3_class(mod, "irtc")
    expect_equal(mod$nitems, 4L)
})

test_that("irtc removes unusable items and stops when data are broken", {
    resp <- irtc_test_sim_main()
    resp$constant <- 1
    expect_warning(mod <- irtc(resp, model="1PL", verbose=FALSE),
        class="irtc_warning_estimation")
    expect_equal(mod$nitems, 6L)
    expect_equal(mod$usability$removed_items, "constant")

    broken <- data.frame(Q1=c("A", "B", "A"), Q2=c("C", "C", "D"),
        stringsAsFactors=FALSE)
    cond <- tryCatch(irtc(broken, model="1PL", verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond$code, "E407")
    expect_s3_class(cond$data$check, "irtc_check")
})

test_that("plain_summary prints layered output in both languages", {
    resp <- irtc_test_sim_main()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    expect_output(plain_summary(mod, lang="zh"), "\u603b\u4f53\u7ed3\u8bba")
    expect_output(plain_summary(mod, lang="en"), "Conclusion")
    sections <- withCallingHandlers(plain_summary(mod, lang="en"),
        message=function(m) invokeRestart("muffleMessage"))
    expect_true(all(c("conclusion", "setup", "next_steps") %in%
        names(sections)))
    cond <- tryCatch(plain_summary(42), condition=function(c) c)
    expect_equal(cond$code, "E401")
})

test_that("plain_summary works for models fitted with irtc.mml directly", {
    resp <- irtc_test_sim_main(n=150, k=5)
    mod <- irtc.mml(resp=resp, verbose=FALSE)
    expect_output(plain_summary(mod, lang="zh"), "\u603b\u4f53\u7ed3\u8bba")
})
