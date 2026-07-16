# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-output-semantics.R
## Tests for M5: semantic GPCM difficulty labels, Q dimension-name headers
## in person output, item status rows, and the results schema bump.

irtc_test_sim_2d <- function(n=250, seed=51)
{
    set.seed(seed)
    theta <- stats::rnorm(n)
    k <- 6
    b <- seq(-1, 1, length.out=k)
    resp <- sapply(seq_len(k), function(j) {
        as.numeric(stats::runif(n) < stats::plogis(theta - b[j]))
    })
    colnames(resp) <- paste0("I", seq_len(k))
    as.data.frame(resp)
}

test_that("param table labels partial and full difficulty for 3-cat items", {
    data(data.gpcm)
    mod <- irtc.mml(resp=data.gpcm, irtmodel="PCM", verbose=FALSE)
    tbl <- irtc_param_table(mod, resp=mod$resp)
    expect_true(all(c("b_partial", "b_full") %in% colnames(tbl)))
    expect_true(all(is.finite(tbl$b_partial)))
    expect_true(all(is.finite(tbl$b_full)))
    legend <- attr(tbl, "step_legend")
    expect_match(legend$b_full, "full-correct")
})

test_that("param table uses b_step1..K for items with 4+ categories", {
    set.seed(9)
    n <- 400
    theta <- stats::rnorm(n)
    make_poly <- function(shift, maxcat) {
        p <- stats::plogis(theta - shift)
        findInterval(p + stats::runif(n, -0.2, 0.2),
            seq(0.2, 0.8, length.out=maxcat - 1L))
    }
    resp <- data.frame(I1=make_poly(0, 4), I2=make_poly(0.4, 4),
        I3=make_poly(-0.4, 4), I4=make_poly(0.2, 4))
    mod <- irtc.mml(resp=as.matrix(resp), irtmodel="PCM", verbose=FALSE,
        control=list(maxiter=40))
    tbl <- irtc_param_table(mod, resp=mod$resp)
    expect_true(all(c("b_step1", "b_step2", "b_step3") %in% colnames(tbl)))
    expect_false("b_partial" %in% colnames(tbl))
})

test_that("dichotomous models get no step-difficulty columns", {
    resp <- irtc_test_sim_2d(n=150)
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    tbl <- irtc_param_table(mod, resp=mod$resp)
    expect_false(any(grepl("^b_step|b_partial|b_full", colnames(tbl))))
})

test_that("person Excel table uses Q dimension names as headers", {
    resp <- irtc_test_sim_2d(n=250)
    qdf <- data.frame(item=paste0("I", 1:6),
        algebra=c(1, 1, 1, 0, 0, 0), geometry=c(0, 0, 0, 1, 1, 1))
    mod <- irtc(resp, model="1PL", q=qdf, verbose=FALSE,
        control=list(maxiter=30))
    tbl <- irtc_person_table(mod, lang="en")
    expect_true(any(grepl("algebra", colnames(tbl))))
    expect_true(any(grepl("geometry", colnames(tbl))))
    expect_false(any(grepl("_dim1|_dim2", colnames(tbl))))
})

test_that("results persons use Q dimension names and expose them", {
    resp <- irtc_test_sim_2d(n=250)
    qdf <- data.frame(item=paste0("I", 1:6),
        verbal=c(1, 1, 1, 0, 0, 0), spatial=c(0, 0, 0, 1, 1, 1))
    mod <- irtc(resp, model="1PL", q=qdf, verbose=FALSE,
        control=list(maxiter=30))
    res <- irtc_results(mod)
    expect_true("eap_verbal" %in% colnames(res$persons))
    expect_true("se_spatial" %in% colnames(res$persons))
    expect_equal(res$model_info$dimension_names, "verbal|spatial")
})

test_that("results schema version is 1.1", {
    resp <- irtc_test_sim_2d(n=120)
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    res <- irtc_results(mod)
    expect_equal(res$model_info$schema_version, "1.1")
})

test_that("Q-only items keep a declared_not_estimated row in results", {
    resp <- irtc_test_sim_2d(n=150)
    ## I7 is declared in the Q matrix but never appears in the data
    qdf <- data.frame(item=paste0("I", 1:7), d1=rep(1, 7))
    w <- testthat::capture_warnings(
        mod <- irtc(resp, model="1PL", q=qdf, verbose=FALSE))
    res <- irtc_results(mod)
    expect_true("I7" %in% res$items$item_id)
    expect_equal(res$items$status[res$items$item_id == "I7"],
        "declared_not_estimated")
    expect_equal(res$items$status[res$items$item_id == "I1"], "estimated")
})

test_that("zero-variance items keep a dropped_no_response row in results", {
    resp <- irtc_test_sim_2d(n=150)
    resp$I7 <- rep(1, nrow(resp))  # zero variance -> removed by the check
    w <- testthat::capture_warnings(
        mod <- irtc(resp, model="1PL", verbose=FALSE))
    res <- irtc_results(mod)
    expect_true("I7" %in% res$items$item_id)
    expect_equal(res$items$status[res$items$item_id == "I7"],
        "dropped_no_response")
})

test_that("rare-category annotations flow into results items", {
    resp <- irtc_test_sim_2d(n=200)
    resp$I1 <- resp$I1 * 2  # category 1 unobserved
    d <- irtc_read(resp, recode=FALSE, verbose=FALSE)
    w <- testthat::capture_warnings(
        mod <- irtc(d, model="PCM", verbose=FALSE))
    res <- irtc_results(mod)
    row <- res$items[res$items$item_id == "I1", ]
    expect_equal(row$categories_collapsed, "0->0, 2->1")
    expect_equal(row$max_score_observed, 1L)
})
