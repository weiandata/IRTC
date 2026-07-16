# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-usability-branches-analysis.R
## Branch-coverage tests for the analysis layer: irtc(), ctt, itemfit,
## quality, plain_summary, excel tables, reports, plots and results.

irtc_test_sim_branch <- function(n=200, k=5, seed=71)
{
    set.seed(seed)
    theta <- stats::rnorm(n)
    b <- seq(-1, 1, length.out=k)
    resp <- sapply(seq_len(k), function(j) {
        as.numeric(stats::runif(n) < stats::plogis(theta - b[j]))
    })
    colnames(resp) <- paste0("I", seq_len(k))
    list(resp=as.data.frame(resp), theta=theta)
}

test_that("irtc accepts aliases, rules, quality=FALSE and check=FALSE", {
    sim <- irtc_test_sim_branch()

    ## case-insensitive alias dispatch to the 2PL engine
    mod <- irtc(sim$resp, model="gpcm", quality=FALSE, verbose=FALSE)
    expect_equal(mod$usability$model, "GPCM")
    expect_null(mod$usability$quality)

    ## partial-credit rules end to end
    set.seed(5)
    n <- 120
    theta <- stats::rnorm(n)
    letters3 <- c("A", "B", "C")
    raw <- as.data.frame(lapply(1:3, function(j) {
        idx <- findInterval(theta + stats::rnorm(n, sd=0.6),
            c(-0.5, 0.5)) + 1L
        letters3[idx]
    }), stringsAsFactors=FALSE)
    colnames(raw) <- paste0("R", 1:3)
    rules <- do.call(rbind, lapply(paste0("R", 1:3), function(item) {
        data.frame(item=item, response=letters3, score=c(0, 1, 2),
            stringsAsFactors=FALSE)
    }))
    mod2 <- irtc(raw, model="PCM", rules=rules, verbose=FALSE)
    expect_s3_class(mod2, "irtc")
    expect_equal(mod2$maxK, 3L)

    ## check=FALSE skips the E407 gate; failure then surfaces as E408
    broken <- data.frame(Q1=c("A", "B", "A"), Q2=c("C", "C", "D"),
        stringsAsFactors=FALSE)
    cond <- tryCatch(irtc(broken, model="1PL", check=FALSE,
        verbose=FALSE), condition=function(c) c)
    expect_equal(cond$code, "E408")
    expect_s3_class(cond, "irtc_error_estimation")
    expect_true(nzchar(cond$data$parent_message))
})

test_that("irtc wraps estimation failures as E408", {
    sim <- irtc_test_sim_branch(n=80, k=4)
    cond <- tryCatch(irtc(sim$resp, model="1PL", verbose=FALSE,
        control=list(maxiter=-1)), condition=function(c) c)
    expect_equal(cond$code, "E408")
})

test_that("irtc_ctt covers model input and undefined alpha", {
    sim <- irtc_test_sim_branch(n=120, k=4)
    mod <- irtc.mml(resp=sim$resp, verbose=FALSE)
    ctt <- irtc_ctt(mod)
    expect_equal(ctt$n_items, 4L)

    ## items never observed together: pairwise covariances undefined
    n <- 20
    disjoint <- data.frame(
        i1=c(rep(c(0, 1), 5), rep(NA_real_, 10)),
        i2=c(rep(NA_real_, 10), rep(c(0, 1), 5)),
        i3=rep(c(0, 1), 10))
    ctt2 <- irtc_ctt(disjoint)
    expect_true(is.na(ctt2$alpha))
    expect_output(print(ctt2, lang="en"), "NA")
})

test_that("irtc_itemfit reconstructs AXsi and validates structure", {
    sim <- irtc_test_sim_branch(n=150, k=3, seed=13)
    b <- c(-0.5, 0, 0.5)
    fake <- list(nitems=3L, maxK=2L, ndim=1L,
        B=array(0, dim=c(3L, 2L, 1L)),
        xsi=data.frame(xsi=b),
        person=data.frame(EAP=sim$theta[1:150]),
        resp=NULL)
    fake$B[, 2L, 1L] <- 1
    class(fake) <- "irtc"

    ## E402: no stored responses and none supplied
    cond <- tryCatch(irtc_itemfit(fake), condition=function(c) c)
    expect_equal(cond$code, "E402")

    ## streaming-style reconstruction of AXsi from step parameters
    fit <- irtc_itemfit(fake, resp=sim$resp[, 1:3])
    expect_equal(nrow(fit), 3L)
    expect_true(all(is.finite(fit$outfit)))

    ## E404: no EAP columns
    fake_noeap <- fake
    fake_noeap$person <- data.frame(score=1:150)
    cond2 <- tryCatch(irtc_itemfit(fake_noeap, resp=sim$resp[, 1:3]),
        condition=function(c) c)
    expect_equal(cond2$code, "E404")

    ## E405: step parameters unusable for reconstruction
    fake_badxsi <- fake
    fake_badxsi$xsi <- data.frame(xsi=c(1, 2))
    cond3 <- tryCatch(irtc_itemfit(fake_badxsi, resp=sim$resp[, 1:3]),
        condition=function(c) c)
    expect_equal(cond3$code, "E405")
})

test_that("irtc_quality flags easy, hard and negative-discr items", {
    set.seed(23)
    n <- 400
    theta <- stats::rnorm(n)
    resp <- data.frame(
        good1=as.numeric(stats::runif(n) < stats::plogis(theta)),
        good2=as.numeric(stats::runif(n) < stats::plogis(theta + 0.3)),
        good3=as.numeric(stats::runif(n) < stats::plogis(theta - 0.3)),
        easy=stats::rbinom(n, 1, 0.985),
        hard=stats::rbinom(n, 1, 0.02),
        neg=as.numeric(stats::runif(n) < stats::plogis(-1.5 * theta))
    )
    mod <- irtc.mml(resp=resp, verbose=FALSE)
    qual <- irtc_quality(mod)
    expect_match(qual$reasons_en[qual$item == "easy"], "very easy")
    expect_match(qual$reasons_en[qual$item == "hard"], "very hard")
    expect_match(qual$reasons_en[qual$item == "neg"],
        "negative discrimination")
    expect_equal(qual$rating[qual$item == "neg"], "revise")

    ## threshold overrides are applied and recorded
    qual2 <- irtc_quality(mod, thresholds=list(p_easy=0.5))
    expect_equal(attr(qual2, "thresholds")$p_easy, 0.5)
    expect_true(sum(grepl("very easy", qual2$reasons_en)) >=
        sum(grepl("very easy", qual$reasons_en)))
})

test_that("plain-language helpers cover all wording branches", {
    expect_match(irtc_reliability_label(0.95, "en"), "excellent")
    expect_match(irtc_reliability_label(0.85, "en"), "good")
    expect_match(irtc_reliability_label(0.75, "en"), "acceptable")
    expect_match(irtc_reliability_label(0.55, "en"), "low")
    expect_match(irtc_reliability_label(NA_real_, "en"), "not available")
    expect_equal(irtc_model_label("XYZ", "en"), "XYZ")
    expect_match(irtc_model_label("GPCM", "en"), "generalised")

    ## removed items appear in the summary overview
    sim <- irtc_test_sim_branch()
    resp <- sim$resp
    resp$flat <- 1
    mod <- suppressWarnings(irtc(resp, model="1PL", verbose=FALSE))
    sections <- irtc_summary_texts(mod, lang="en")
    expect_true(any(grepl("flat", sections$setup$body)))
})

test_that("excel label helpers cover every band", {
    p <- c(NA, 0.95, 0.6, 0.3, 0.1)
    expect_equal(irtc_difficulty_label(p, "en"),
        c("unknown", "easy", "moderate", "hard", "very hard"))
    r <- c(NA, -0.2, 0.1, 0.2, 0.3, 0.5)
    labels <- irtc_discr_label(r, "en")
    expect_equal(labels[1], "unknown")
    expect_match(labels[2], "negative")
    expect_equal(labels[3:6], c("poor", "weak", "good", "excellent"))
})

test_that("person tables work without an explicit person ID", {
    sim <- irtc_test_sim_branch(n=90, k=4)
    mod <- irtc.mml(resp=sim$resp, verbose=FALSE)
    tbl <- irtc_person_table(mod, lang="en")
    expect_equal(nrow(tbl), 90L)
    expect_equal(tbl$person_id[1], "1")
    expect_true("max_score" %in% colnames(tbl))
})

test_that("irtc_report honours explicit format, title and decision table", {
    set.seed(29)
    n <- 250
    theta <- stats::rnorm(n)
    resp <- data.frame(
        a=as.numeric(stats::runif(n) < stats::plogis(theta)),
        b=as.numeric(stats::runif(n) < stats::plogis(theta + 0.2)),
        c=as.numeric(stats::runif(n) < stats::plogis(theta - 0.2)),
        noise=stats::rbinom(n, 1, 0.5)
    )
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    file <- tempfile(fileext=".html")
    irtc_report(mod, file, format="html", audience="decision",
        lang="en", title="Custom Report 123", verbose=FALSE)
    html <- paste(readLines(file, encoding="UTF-8"), collapse="\n")
    expect_match(html, "Custom Report 123")
    expect_match(html, "Items needing attention")
    ## overwrite=TRUE replaces the file
    irtc_report(mod, file, audience="survey", lang="en",
        overwrite=TRUE, verbose=FALSE)
    expect_true(file.exists(file))
    unlink(file)
})

test_that("icc plots accept item names and reject multidim models", {
    sim <- irtc_test_sim_branch(n=150, k=4)
    mod <- irtc(sim$resp, model="1PL", verbose=FALSE)
    png_file <- tempfile(fileext=".png")
    grDevices::png(png_file)
    expect_error(plot(mod, type="icc", items=c("I1", "I2"), lang="en"),
        NA)
    grDevices::dev.off()
    unlink(png_file)

    fake <- list(nitems=2L, maxK=2L, ndim=2L,
        AXsi=matrix(0, 2, 2), B=array(1, dim=c(2, 2, 2)), resp=NULL)
    class(fake) <- "irtc"
    cond <- tryCatch(irtc_plot_icc(fake), condition=function(c) c)
    expect_equal(cond$code, "E502")
})

test_that("irtc_json accepts pre-built results objects", {
    testthat::skip_if_not_installed("jsonlite")
    sim <- irtc_test_sim_branch(n=100, k=4)
    mod <- irtc(sim$resp, model="1PL", verbose=FALSE)
    res <- irtc_results(mod)
    json <- irtc_json(res, pretty=FALSE)
    parsed <- jsonlite::fromJSON(json)
    expect_equal(parsed$model_info$n_persons, 100L)
})

test_that("irtc_excel validates prefix collisions and creates dirs", {
    testthat::skip_if_not_installed("openxlsx")
    sim <- irtc_test_sim_branch(n=100, k=4)
    mod <- irtc(sim$resp, model="1PL", verbose=FALSE)
    dir <- file.path(tempdir(), paste0("irtcnew", sample.int(1e6, 1)),
        "nested")
    expect_false(dir.exists(dir))
    paths <- suppressMessages(irtc_excel(mod, dir=dir, lang="en",
        verbose=FALSE))
    expect_true(dir.exists(dir))
    expect_true(all(file.exists(paths)))
})
