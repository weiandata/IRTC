# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-score-partial.R
## Tests for key/rules file import and partial-credit key scoring.

test_that("irtc_score reads an answer key from a csv file", {
    resp <- data.frame(Q1=c("A", "B", "a"), Q2=c("C", "c", "D"),
        stringsAsFactors=FALSE)
    kdf <- data.frame(item=c("Q1", "Q2"), answer=c("A", "C"))
    path <- tempfile(fileext=".csv")
    utils::write.csv(kdf, path, row.names=FALSE)
    out <- irtc_score(resp, key=path)
    expect_equal(out$Q1, c(1, 0, 1))
    expect_equal(out$Q2, c(1, 1, 0))
    unlink(path)
})

test_that("irtc_score applies partial credit from a key file", {
    resp <- data.frame(Q1=c("A", "B", "C", "D", NA),
        Q2=c("A", "B", "C", "D", "A"), stringsAsFactors=FALSE)
    kdf <- data.frame(item=c("Q1", "Q2"), answer=c("A", "B"),
        partial_answer=c("B|C", ""))
    path <- tempfile(fileext=".csv")
    utils::write.csv(kdf, path, row.names=FALSE)
    out <- irtc_score(resp, key=path)
    ## Q1: A=2 (full), B/C=1 (partial), D=0, NA=NA
    expect_equal(out$Q1, c(2, 1, 1, 0, NA))
    ## Q2: plain 0/1
    expect_equal(out$Q2, c(0, 1, 0, 0, 0))
    si <- attr(out, "score_info")
    expect_equal(si$partial_items, "Q1")
    unlink(path)
})

test_that("partial answers accept Chinese separators and column names", {
    resp <- data.frame(Q1=c("A", "B", "C"), stringsAsFactors=FALSE)
    kdf <- data.frame(x1=c("Q1"), x2=c("A"), x3=c("B\u3001C"))
    colnames(kdf) <- c("\u9898\u76ee", "\u7b54\u6848",
        "\u90e8\u5206\u6b63\u786e\u7b54\u6848")
    path <- tempfile(fileext=".csv")
    utils::write.csv(kdf, path, row.names=FALSE, fileEncoding="UTF-8")
    out <- irtc_score(resp, key=path)
    expect_equal(out$Q1, c(2, 1, 1))
    unlink(path)
})

test_that("irtc_score with irtc_data records the partial scoring log", {
    resp <- data.frame(Q1=c("A", "B"), Q2=c("C", "D"),
        stringsAsFactors=FALSE)
    d <- irtc_read(resp, verbose=FALSE)
    kdf <- data.frame(item=c("Q1", "Q2"), answer=c("A", "C"),
        partial_answer=c("B", NA))
    path <- tempfile(fileext=".csv")
    utils::write.csv(kdf, path, row.names=FALSE)
    d2 <- irtc_score(d, key=path)
    expect_true("I202" %in% d2$log$code)
    expect_equal(d2$score_info$partial_items, "Q1")
    expect_equal(d2$score_info$scored_items, c("Q1", "Q2"))
    unlink(path)
})

test_that("key file validation raises structured errors", {
    resp <- data.frame(Q1=c("A"), stringsAsFactors=FALSE)
    path <- tempfile(fileext=".csv")
    ## missing answer column
    utils::write.csv(data.frame(item="Q1", note="x"), path,
        row.names=FALSE)
    cond <- tryCatch(irtc_score(resp, key=path), condition=function(c) c)
    expect_equal(cond$code, "E207")
    ## duplicated item
    utils::write.csv(data.frame(item=c("Q1", "Q1"), answer=c("A", "B")),
        path, row.names=FALSE)
    cond <- tryCatch(irtc_score(resp, key=path), condition=function(c) c)
    expect_equal(cond$code, "E208")
    ## missing key file
    cond <- tryCatch(irtc_score(resp, key="no-such-file.xlsx"),
        condition=function(c) c)
    expect_equal(cond$code, "E103")
    unlink(path)
})

test_that("irtc_score reads a rules table with Chinese aliases", {
    resp <- data.frame(Q1=c("A", "B", "C"), stringsAsFactors=FALSE)
    rdf <- data.frame(a=c("Q1", "Q1", "Q1"), b=c("A", "B", "C"),
        d=c(2, 1, 0))
    colnames(rdf) <- c("\u9898\u76ee", "\u4f5c\u7b54", "\u5206\u503c")
    path <- tempfile(fileext=".csv")
    utils::write.csv(rdf, path, row.names=FALSE, fileEncoding="UTF-8")
    out <- irtc_score(resp, rules=path)
    expect_equal(out$Q1, c(2, 1, 0))
    si <- attr(out, "score_info")
    expect_equal(si$partial_items, "Q1")
    unlink(path)
})

test_that("W423 fires when Q declares partial but key is right/wrong", {
    set.seed(5)
    n <- 150
    theta <- stats::rnorm(n)
    correct <- c("A", "B", "C", "D")
    resp <- as.data.frame(lapply(seq_along(correct), function(j) {
        hit <- stats::runif(n) < stats::plogis(theta)
        ifelse(hit, correct[j],
            sample(setdiff(LETTERS[1:4], correct[j]), n, replace=TRUE))
    }), stringsAsFactors=FALSE)
    colnames(resp) <- paste0("Q", 1:4)
    qdf <- data.frame(item=paste0("Q", 1:4), d1=rep(1, 4),
        partial=c(1, 0, 0, 0))
    key <- stats::setNames(correct, paste0("Q", 1:4))
    w <- testthat::capture_warnings(
        mod <- irtc(resp, model="1PL", key=key, q=qdf, verbose=FALSE))
    expect_true(any(grepl("W423", w)))
    expect_true(any(grepl("Q1", w[grepl("W423", w)])))
    expect_s3_class(mod, "irtc")
})

test_that("W424 fires when key has partial answers but Q does not declare", {
    set.seed(6)
    n <- 200
    theta <- stats::rnorm(n)
    ## Q1 has answers A (full), B (partial), C/D wrong
    pick <- function(p_full, p_part) {
        u <- stats::runif(n)
        ifelse(u < p_full, "A", ifelse(u < p_full + p_part, "B",
            sample(c("C", "D"), n, replace=TRUE)))
    }
    resp <- data.frame(Q1=pick(0.4, 0.3), Q2=pick(0.5, 0),
        Q3=pick(0.5, 0), stringsAsFactors=FALSE)
    kdf <- data.frame(item=c("Q1", "Q2", "Q3"), answer=c("A", "A", "A"),
        partial_answer=c("B", "", ""))
    kpath <- tempfile(fileext=".csv")
    utils::write.csv(kdf, kpath, row.names=FALSE)
    qdf <- data.frame(item=c("Q1", "Q2", "Q3"), d1=rep(1, 3))
    w <- testthat::capture_warnings(
        mod <- irtc(resp, model="PCM", key=kpath, q=qdf, verbose=FALSE))
    expect_true(any(grepl("W424", w)))
    expect_s3_class(mod, "irtc")
    unlink(kpath)
})

test_that("end to end: GPCM with partial-credit key file and Q matrix", {
    set.seed(7)
    n <- 300
    theta <- stats::rnorm(n)
    gen_item <- function(shift) {
        u <- stats::plogis(theta - shift)
        r <- stats::runif(n)
        ifelse(r < u * 0.5, "A", ifelse(r < u, "B",
            sample(c("C", "D"), n, replace=TRUE)))
    }
    resp <- data.frame(Q1=gen_item(0), Q2=gen_item(0.5),
        Q3=gen_item(-0.5), Q4=gen_item(1), stringsAsFactors=FALSE)
    kdf <- data.frame(item=paste0("Q", 1:4), answer=rep("A", 4),
        partial_answer=rep("B", 4))
    kpath <- tempfile(fileext=".csv")
    utils::write.csv(kdf, kpath, row.names=FALSE)
    qdf <- data.frame(item=paste0("Q", 1:4), ability=rep(1, 4),
        partial=rep(1, 4))
    mod <- irtc(resp, model="GPCM", key=kpath, q=qdf, verbose=FALSE,
        control=list(maxiter=40))
    expect_s3_class(mod, "irtc")
    expect_equal(as.numeric(mod$maxK), 3)  # categories 0/1/2
    unlink(kpath)
})
