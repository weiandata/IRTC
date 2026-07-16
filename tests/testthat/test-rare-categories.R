# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-rare-categories.R
## Tests for the rare/unobserved-category handling (collapse and prior).

irtc_test_sim_rare <- function(n=200, k=5, seed=31)
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

test_that("irtc_rare_scan flags gaps and reduced tops", {
    resp <- data.frame(I1=c(0, 2, 2, 0), I2=c(0, 1, 1, 0),
        I3=c(0, 1, 2, 1))
    qdf <- data.frame(item=c("I1", "I2", "I3"), d1=rep(1, 3),
        max_score=c(2, 2, 3))
    qm <- irtc_read_q(qdf)
    scan <- IRTC:::irtc_rare_scan(resp, q=qm)
    ## I1: middle category 1 unobserved
    expect_true(scan$needs_collapse[scan$item == "I1"])
    expect_equal(scan$unobserved[scan$item == "I1"], "1")
    ## I2: declared max 2, observed max 1
    expect_false(scan$needs_collapse[scan$item == "I2"])
    expect_true(scan$top_reduced[scan$item == "I2"])
    expect_equal(scan$unobserved[scan$item == "I2"], "2")
    ## I3: complete
    expect_equal(scan$unobserved[scan$item == "I3"], "")
})

test_that("irtc_rare_scan detects an empty zero category", {
    resp <- data.frame(I1=c(1, 2, 2, 1), I2=c(0, 1, 1, 0))
    scan <- IRTC:::irtc_rare_scan(resp)
    expect_true(scan$needs_collapse[scan$item == "I1"])
    expect_equal(scan$unobserved[scan$item == "I1"], "0")
})

test_that("collapse recodes gaps and annotates the mapping", {
    resp <- data.frame(I1=c(0, 2, 2, 0), I2=c(1, 2, 2, 1))
    scan <- IRTC:::irtc_rare_scan(resp)
    res <- IRTC:::irtc_rare_collapse(resp, scan)
    expect_equal(res$resp$I1, c(0, 1, 1, 0))
    expect_equal(res$resp$I2, c(0, 1, 1, 0))
    map1 <- res$scan$collapse_map[res$scan$item == "I1"]
    expect_match(map1, "0->0")
    expect_match(map1, "2->1")
    expect_true(all(c("I1", "I2") %in% res$collapsed_items))
    expect_true(all(res$log$code == "W425"))
})

test_that("irtc_rare_affected_xsi maps item steps to xsi indices", {
    ## I1: max 2 (steps 1,2), I2: max 1 (step 1), I3: max 2 (steps 1,2)
    resp <- data.frame(I1=c(0, 2, 2), I2=c(0, 1, 1), I3=c(0, 1, 2))
    scan <- IRTC:::irtc_rare_scan(resp)
    aff <- IRTC:::irtc_rare_affected_xsi(resp, scan)
    ## I1 category 1 empty -> step 1 -> global index 1
    expect_equal(aff$index, 1)
    expect_equal(aff$labels, "I1_Cat1")
    expect_equal(aff$n_parameters, 5)
})

test_that("prior args build a prior list for 1PL/PCM models", {
    resp <- data.frame(I1=c(0, 2, 2), I2=c(0, 1, 1), I3=c(0, 1, 2))
    scan <- IRTC:::irtc_rare_scan(resp)
    fx <- IRTC:::irtc_rare_prior_args(resp, scan, model="PCM")
    expect_false(fx$two_pl)
    expect_equal(length(fx$prior_list_xsi), 5L)
    expect_equal(fx$prior_list_xsi[[1]][[2]]$sd, 2)
    expect_equal(fx$prior_list_xsi[[2]][[2]]$sd, 1000)
})

test_that("prior args fall back to xsi.fixed for 2PL/GPCM models", {
    resp <- data.frame(I1=c(0, 2, 2), I2=c(0, 1, 1), I3=c(0, 1, 2))
    scan <- IRTC:::irtc_rare_scan(resp)
    fx <- IRTC:::irtc_rare_prior_args(resp, scan, model="GPCM")
    expect_true(fx$two_pl)
    expect_equal(unname(fx$xsi.fixed[, 1]), 1)
    expect_equal(unname(fx$xsi.fixed[, 2]), 0)
})

test_that("irtc collapse mode: nobody partially correct becomes 0/1", {
    resp <- irtc_test_sim_rare(n=200, k=5)
    resp$I1 <- resp$I1 * 2  # scores 0/2: category 1 unobserved
    ## recode=FALSE keeps the gap so that the annotated collapse handles it
    d <- irtc_read(resp, recode=FALSE, verbose=FALSE)
    w <- testthat::capture_warnings(
        mod <- irtc(d, model="PCM", verbose=FALSE))
    expect_true(any(grepl("W425", w)))
    expect_s3_class(mod, "irtc")
    expect_equal(as.numeric(mod$maxK), 2)  # collapsed to 0/1
    info <- mod$usability$rare_categories
    expect_equal(info$collapse_map[info$item == "I1"], "0->0, 2->1")
})

test_that("irtc collapse mode annotates a declared but unreached top", {
    resp <- irtc_test_sim_rare(n=150, k=4)
    qdf <- data.frame(item=paste0("I", 1:4), d1=rep(1, 4),
        max_score=c(3, 1, 1, 1))
    w <- testthat::capture_warnings(
        mod <- irtc(resp, model="PCM", q=qdf, verbose=FALSE))
    expect_true(any(grepl("W425", w)))
    info <- mod$usability$rare_categories
    expect_true(info$top_reduced[info$item == "I1"])
    expect_equal(info$max_declared[info$item == "I1"], 3L)
    expect_equal(info$max_observed[info$item == "I1"], 1L)
})

test_that("irtc prior mode keeps categories on the PCM path", {
    resp <- irtc_test_sim_rare(n=300, k=5)
    resp$I1 <- resp$I1 * 2  # category 1 unobserved
    d <- irtc_read(resp, recode=FALSE, verbose=FALSE)
    w <- testthat::capture_warnings(
        mod <- irtc(d, model="PCM", rare_categories="prior",
            verbose=FALSE, control=list(maxiter=30)))
    expect_true(any(grepl("W425", w)))
    expect_s3_class(mod, "irtc")
    expect_equal(as.numeric(mod$maxK), 3)  # categories kept
    info <- mod$usability$rare_categories
    expect_true(info$prior_dominated[info$item == "I1"])
})

test_that("irtc prior mode fixes thresholds on the GPCM path", {
    set.seed(41)
    n <- 300
    theta <- stats::rnorm(n)
    resp <- data.frame(
        I1=2 * as.numeric(stats::runif(n) < stats::plogis(theta)),
        I2=as.numeric(stats::runif(n) < stats::plogis(theta - 0.3)),
        I3=as.numeric(stats::runif(n) < stats::plogis(theta + 0.3)),
        I4=findInterval(stats::plogis(theta) + stats::runif(n, -0.3, 0.3),
            c(0.4, 0.7)))
    d <- irtc_read(resp, recode=FALSE, verbose=FALSE)
    w <- testthat::capture_warnings(
        mod <- irtc(d, model="GPCM", rare_categories="prior",
            verbose=FALSE, control=list(maxiter=30)))
    expect_true(any(grepl("W425", w)))
    expect_s3_class(mod, "irtc")
    expect_equal(as.numeric(mod$maxK), 3)
    ## the fixed threshold sits at the prior mean 0
    expect_equal(unname(mod$xsi["I1_Cat1", "xsi"]), 0, tolerance=1e-8)
})

test_that("prior mode falls back to collapse for custom designs", {
    resp <- irtc_test_sim_rare(n=150, k=4)
    resp$I1 <- resp$I1 * 2
    d <- irtc_read(resp, recode=FALSE, verbose=FALSE)
    w <- testthat::capture_warnings(
        mod <- irtc(d, model="PCM2", rare_categories="prior",
            verbose=FALSE))
    expect_true(any(grepl("W426", w)))
    expect_equal(as.numeric(mod$maxK), 2)  # collapsed after fallback
})

test_that("clean data passes through rare handling untouched", {
    resp <- irtc_test_sim_rare(n=100, k=4)
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    info <- mod$usability$rare_categories
    expect_false(any(info$needs_collapse))
    expect_false(any(info$top_reduced))
    expect_equal(mod$usability$rare_mode, "collapse")
})
