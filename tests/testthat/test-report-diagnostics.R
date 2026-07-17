# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-report-diagnostics.R
## Tests for M6: the model-diagnostics and data-transparency report
## sections.

irtc_test_sim_diag <- function(n=200, k=6, seed=61)
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

block_types <- function(blocks) vapply(blocks, `[[`, character(1L), "type")
block_text <- function(blocks) {
    paste(unlist(lapply(blocks, function(b) {
        if (is.character(b$value)) b$value else
            paste(unlist(b$value), collapse=" ")
    })), collapse=" \n ")
}

test_that("diagnostics blocks report convergence, IC and reliability", {
    resp <- irtc_test_sim_diag()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    b <- irtc_report_diagnostics_blocks(mod, mod$resp, "en", detail=TRUE)
    txt <- block_text(b)
    expect_match(txt, "Model diagnostics")
    expect_match(txt, "converged")
    expect_match(txt, "AIC")
    expect_match(txt, "EAP reliability")
    ## detail=TRUE includes the item-fit table
    expect_true("table" %in% block_types(b))
})

test_that("diagnostics warn when the iteration limit is reached", {
    resp <- irtc_test_sim_diag()
    mod <- suppressWarnings(irtc(resp, model="1PL", verbose=FALSE,
        control=list(maxiter=2)))
    b <- irtc_report_diagnostics_blocks(mod, mod$resp, "en", detail=FALSE)
    expect_match(block_text(b), "iteration limit")
})

test_that("transparency blocks report weights, alignment and scoring", {
    resp <- irtc_test_sim_diag()
    df <- cbind(resp, weight=stats::runif(nrow(resp), 0.5, 2))
    qdf <- data.frame(item=c(paste0("I", 1:6), "I99"), d1=rep(1, 7))
    w <- testthat::capture_warnings(
        mod <- irtc(df, model="1PL", q=qdf, verbose=FALSE))
    b <- irtc_report_transparency_blocks(mod, "en", detail=TRUE)
    txt <- block_text(b)
    expect_match(txt, "Data processing transparency")
    expect_match(txt, "weighted N")
    expect_match(txt, "I99")  # declared in Q, absent from data
    ## detail=TRUE includes the full cleaning-log table
    expect_true("table" %in% block_types(b))
})

test_that("transparency reports category collapses", {
    resp <- irtc_test_sim_diag()
    resp$I1 <- resp$I1 * 2  # category 1 unobserved
    d <- irtc_read(resp, recode=FALSE, verbose=FALSE)
    w <- testthat::capture_warnings(
        mod <- irtc(d, model="PCM", verbose=FALSE))
    b <- irtc_report_transparency_blocks(mod, "zh", detail=TRUE)
    types <- block_types(b)
    expect_true("table" %in% types)
    expect_match(block_text(b), "0->0")
})

test_that("full report embeds the new sections for stat and survey", {
    resp <- irtc_test_sim_diag()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    for (aud in c("survey", "stat", "decision")) {
        path <- tempfile(fileext=".html")
        irtc_report(mod, path, audience=aud, lang="en", verbose=FALSE)
        html <- paste(readLines(path, warn=FALSE), collapse="\n")
        expect_match(html, "Model diagnostics")
        expect_match(html, "Data processing transparency")
        unlink(path)
    }
})

test_that("verbose report announces the written file", {
    resp <- irtc_test_sim_diag()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    path <- tempfile(fileext=".html")
    msg <- testthat::capture_messages(
        irtc_report(mod, path, audience="stat", lang="en", verbose=TRUE))
    expect_true(any(grepl("Report written", msg)))
    unlink(path)
})

test_that("irtc_report_figure returns NULL when the plot expression fails", {
    expect_null(IRTC:::irtc_report_figure(stop("boom")))
})

test_that("diagnostics recompute item fit when it is not cached", {
    resp <- irtc_test_sim_diag()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    mod$usability$itemfit <- NULL  # force the recompute branch
    b <- irtc_report_diagnostics_blocks(mod, mod$resp, "en", detail=TRUE)
    expect_match(block_text(b), "Infit/outfit")
})

test_that("decision texts survive a missing EAP reliability", {
    resp <- irtc_test_sim_diag()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    mod$EAP.rel <- NULL
    txt <- IRTC:::irtc_decision_texts(mod, mod$usability$quality, "en")
    expect_type(txt, "character")
})

test_that("transparency reports removed items", {
    resp <- irtc_test_sim_diag()
    resp$I7 <- rep(1, nrow(resp))  # zero variance -> removed by the check
    w <- testthat::capture_warnings(
        mod <- irtc(resp, model="1PL", verbose=FALSE))
    b <- irtc_report_transparency_blocks(mod, "en", detail=TRUE)
    txt <- block_text(b)
    expect_match(txt, "removed")
    expect_match(txt, "I7")
})

test_that("transparency reports the partial-credit scoring summary", {
    set.seed(71)
    n <- 200
    theta <- stats::rnorm(n)
    gen_item <- function(shift) {
        u <- stats::plogis(theta - shift)
        r <- stats::runif(n)
        ifelse(r < u * 0.5, "A", ifelse(r < u, "B",
            sample(c("C", "D"), n, replace=TRUE)))
    }
    raw <- data.frame(id=paste0("S", seq_len(n)),
        Q1=gen_item(0), Q2=gen_item(0.3), Q3=gen_item(-0.3),
        stringsAsFactors=FALSE)
    dp <- tempfile(fileext=".csv")
    utils::write.csv(raw, dp, row.names=FALSE)
    kp <- tempfile(fileext=".csv")
    utils::write.csv(data.frame(item=paste0("Q", 1:3), answer="A",
        partial_answer="B"), kp, row.names=FALSE)
    mod <- suppressWarnings(irtc(dp, model="GPCM", key=kp, verbose=FALSE,
        control=list(maxiter=40)))
    b <- irtc_report_transparency_blocks(mod, "en", detail=TRUE)
    txt <- block_text(b)
    expect_match(txt, "Scoring")
    expect_match(txt, "partial credit")
    unlink(c(dp, kp))
})
