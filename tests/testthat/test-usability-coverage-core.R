# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-usability-coverage-core.R
## Coverage for optional paths of the estimation entry points
## (irtc.mml / irtc.mml.2pl) and remaining branches of the usability layer.

irtc_test_sim_cov <- function(n=150, k=6, seed=101)
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

test_that("irtc.mml covers acceleration, snodes and constraints", {
    resp <- irtc_test_sim_cov()

    mod_yu <- irtc.mml(resp=resp, verbose=FALSE,
        control=list(maxiter=15, acceleration="Yu"))
    expect_s3_class(mod_yu, "irtc")

    mod_ramsay <- irtc.mml(resp=resp, verbose=FALSE,
        control=list(maxiter=15, acceleration="Ramsay"))
    expect_s3_class(mod_ramsay, "irtc")

    ## stochastic (QMC and Monte Carlo) integration nodes
    mod_qmc <- irtc.mml(resp=resp, verbose=FALSE,
        control=list(maxiter=10, snodes=300, QMC=TRUE))
    expect_true(is.finite(mod_qmc$deviance))
    mod_mc <- irtc.mml(resp=resp, verbose=FALSE,
        control=list(maxiter=10, snodes=300, QMC=FALSE))
    expect_true(is.finite(mod_mc$deviance))

    ## item-constraint identification
    mod_items <- irtc.mml(resp=resp, constraint="items", verbose=FALSE,
        control=list(maxiter=15))
    expect_s3_class(mod_items, "irtc")
})

test_that("irtc.mml covers fixed parameters, weights and regression", {
    resp <- irtc_test_sim_cov(seed=103)
    n <- nrow(resp)

    ## fixed and initialised item parameters
    mod_fix <- irtc.mml(resp=resp, xsi.fixed=cbind(1, 0), verbose=FALSE,
        control=list(maxiter=15))
    expect_equal(unname(mod_fix$xsi$xsi[1]), 0)
    mod_init <- irtc.mml(resp=resp, xsi.inits=cbind(1:2, c(-0.5, 0.5)),
        verbose=FALSE, control=list(maxiter=15))
    expect_s3_class(mod_init, "irtc")

    ## case weights
    set.seed(1)
    mod_w <- irtc.mml(resp=resp, pweights=stats::runif(n, 0.5, 1.5),
        verbose=FALSE, control=list(maxiter=15))
    expect_s3_class(mod_w, "irtc")

    ## latent regression via Y and via formulaY/dataY
    covariate <- stats::rnorm(n)
    mod_y <- irtc.mml(resp=resp, Y=matrix(covariate, ncol=1),
        verbose=FALSE, control=list(maxiter=15))
    expect_true(length(mod_y$beta) >= 2L)
    mod_f <- irtc.mml(resp=resp, formulaY=~x,
        dataY=data.frame(x=covariate), verbose=FALSE,
        control=list(maxiter=15))
    expect_s3_class(mod_f, "irtc")

    ## multiple groups with estimated variances
    grp <- rep(1:2, length.out=n)
    mod_g <- irtc.mml(resp=resp, group=grp, verbose=FALSE,
        control=list(maxiter=15))
    expect_equal(mod_g$G, 2)
})

test_that("multidimensional and polytomous variants estimate and print", {
    resp <- irtc_test_sim_cov(seed=105)
    Q <- matrix(0, 6, 2)
    Q[1:3, 1] <- 1
    Q[4:6, 2] <- 1
    mod_md <- irtc.mml(resp=resp, Q=Q, verbose=FALSE,
        control=list(maxiter=15))
    expect_equal(mod_md$ndim, 2)
    ## summary(file=) appends ".Rout" to the supplied name (legacy contract)
    file_md <- tempfile()
    summary(mod_md, file=file_md)
    expect_true(file.exists(paste0(file_md, ".Rout")))
    unlink(paste0(file_md, ".Rout"))

    data(data.gpcm)
    mod_rsm <- irtc.mml(resp=data.gpcm, irtmodel="RSM", verbose=FALSE,
        control=list(maxiter=15))
    expect_s3_class(mod_rsm, "irtc")
    mod_pcm2 <- irtc.mml(resp=data.gpcm, irtmodel="PCM2", verbose=FALSE,
        control=list(maxiter=15))
    expect_s3_class(mod_pcm2, "irtc")

    mod_gpcm <- irtc.mml.2pl(resp=data.gpcm, irtmodel="GPCM",
        verbose=FALSE, control=list(maxiter=15))
    expect_s3_class(mod_gpcm, "irtc")
    file_g <- tempfile()
    summary(mod_gpcm, file=file_g)
    expect_true(file.exists(paste0(file_g, ".Rout")))
    unlink(paste0(file_g, ".Rout"))

    ## 2PL with estimated variance and explicit grid method
    mod_2pl <- irtc.mml.2pl(resp=resp, irtmodel="2PL", est.variance=TRUE,
        method="grid", verbose=FALSE, control=list(maxiter=15))
    expect_s3_class(mod_2pl, "irtc")
    expect_output(print(mod_2pl))

    ## polytomous item fit exercises the category-restricted path
    fit_pcm <- irtc_itemfit(mod_gpcm, resp=data.gpcm)
    expect_true(all(is.finite(fit_pcm$outfit)))
})

test_that("internal numeric helpers keep their contracts", {
    rr0 <- array(stats::rnorm(2 * 3 * 4), dim=c(2, 3, 4))
    shifted <- IRTC:::irtc_calc_prob_helper_subtract_max(rr0)
    expect_equal(dim(shifted), c(2, 3, 4))
    ## per item and node, the maximum over categories becomes zero
    expect_true(all(abs(apply(shifted, c(1, 3), max)) < 1e-12))

    m <- matrix(c(1, 2, 3, 4, 5, 6), nrow=2)
    expect_equal(IRTC:::irtc_rcpp_rowCumsums(m), t(apply(m, 1, cumsum)))

    expect_null(IRTC:::irtc_cat("label", Sys.time(), active=FALSE))
    expect_output(res <- IRTC:::irtc_cat("label", Sys.time(),
        active=TRUE))
    expect_s3_class(res, "POSIXct")

    dm <- IRTC:::designMatrices(modeltype="PCM",
        resp=data.frame(a=c(0, 1, 2), b=c(0, 1, 1)))
    expect_output(print(dm))
})

test_that("irtc_quality covers misfit bands and missing responses", {
    resp <- irtc_test_sim_cov(n=200, k=5, seed=107)
    mod <- irtc.mml(resp=resp, verbose=FALSE, control=list(maxiter=20))

    ## absurdly tight thresholds force the severe and mild branches
    qual_severe <- irtc_quality(mod,
        thresholds=list(fit_severe=c(0.999, 1.001),
            fit_mild=c(0.998, 1.002)))
    expect_true(any(grepl("severe misfit", qual_severe$reasons_en)))
    qual_mild <- irtc_quality(mod,
        thresholds=list(fit_mild=c(0.999, 1.001)))
    expect_true(any(grepl("mild misfit", qual_mild$reasons_en)))

    ## model object without stored responses -> E402
    fake <- structure(list(resp=NULL), class="irtc")
    cond <- tryCatch(irtc_quality(fake), condition=function(c) c)
    expect_equal(cond$code, "E402")
})

test_that("irtc_itemfit skips items with fewer than two responses", {
    resp <- irtc_test_sim_cov(n=120, k=5, seed=109)
    mod <- irtc.mml(resp=resp, verbose=FALSE, control=list(maxiter=20))
    crafted <- resp
    crafted$I5[2:120] <- NA
    fit <- irtc_itemfit(mod, resp=crafted)
    expect_true(is.na(fit$outfit[5]))
    expect_true(all(is.finite(fit$outfit[1:4])))
})

test_that("irtc_read covers haven formats and empty delimited files", {
    testthat::skip_if_not_installed("haven")
    df <- data.frame(id=c("a", "b", "c"), i1=c(0, 1, 1), i2=c(1, 0, 1),
        stringsAsFactors=FALSE)
    sav <- tempfile(fileext=".sav")
    haven::write_sav(df, sav)
    out <- irtc_read(sav, verbose=FALSE)
    expect_equal(out$pid, c("a", "b", "c"))
    expect_equal(out$resp$i1, c(0, 1, 1))

    dta <- tempfile(fileext=".dta")
    haven::write_dta(df, dta)
    out2 <- irtc_read(dta, verbose=FALSE)
    expect_equal(out2$resp$i2, c(1, 0, 1))
    unlink(c(sav, dta))

    blank <- tempfile(fileext=".csv")
    writeLines(c("", "   ", ""), blank)
    cond <- tryCatch(irtc_read(blank, verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond$code, "E104")
    unlink(blank)
})

test_that("irtc accepts irtc_data input and stops when items run out", {
    resp <- irtc_test_sim_cov(n=100, k=4, seed=111)
    obj <- irtc_read(resp, verbose=FALSE)
    mod <- irtc(obj, model="1PL", verbose=FALSE)
    expect_s3_class(mod, "irtc")

    ## after removing unusable items fewer than 2 remain -> E302
    tiny <- data.frame(ok=resp$I1, c1=rep(1, 100), c2=rep(0, 100))
    cond <- tryCatch(suppressWarnings(irtc(tiny, model="1PL",
        verbose=FALSE)), condition=function(c) c)
    expect_equal(cond$code, "E302")
})

test_that("verbose estimation prints the progress blocks", {
    resp <- irtc_test_sim_cov(n=100, k=4, seed=115)
    out1 <- utils::capture.output(
        mod1 <- irtc.mml(resp=resp, verbose=TRUE,
            control=list(maxiter=5)))
    expect_true(length(out1) > 10L)
    expect_s3_class(mod1, "irtc")
    out2 <- utils::capture.output(
        mod2 <- irtc.mml.2pl(resp=resp, irtmodel="2PL", verbose=TRUE,
            control=list(maxiter=5)))
    expect_true(length(out2) > 10L)
    expect_s3_class(mod2, "irtc")
})

test_that("irtc.mml.2pl covers multidim, slope groups and snodes", {
    resp <- irtc_test_sim_cov(n=150, k=6, seed=117)
    Q <- matrix(0, 6, 2)
    Q[1:3, 1] <- 1
    Q[4:6, 2] <- 1
    mod_md2 <- irtc.mml.2pl(resp=resp, irtmodel="2PL", Q=Q,
        method="grid", verbose=FALSE, control=list(maxiter=10))
    expect_equal(mod_md2$ndim, 2)

    mod_sg <- irtc.mml.2pl(resp=resp, irtmodel="2PL",
        est.slopegroups=c(1, 1, 1, 2, 2, 2), method="grid",
        verbose=FALSE, control=list(maxiter=10))
    expect_s3_class(mod_sg, "irtc")

    mod_sn <- irtc.mml.2pl(resp=resp, irtmodel="2PL", method="grid",
        verbose=FALSE, control=list(maxiter=8, snodes=300, QMC=TRUE))
    expect_true(is.finite(mod_sn$deviance))
})

test_that("irtc.mml covers fixed variances and free regression means", {
    resp <- irtc_test_sim_cov(n=150, k=6, seed=119)
    Q <- matrix(0, 6, 2)
    Q[1:3, 1] <- 1
    Q[4:6, 2] <- 1
    ## fix the covariance between the two dimensions to zero
    mod_vf <- irtc.mml(resp=resp, Q=Q, variance.fixed=cbind(1, 2, 0),
        verbose=FALSE, control=list(maxiter=10))
    expect_equal(mod_vf$variance[1, 2], 0)

    ## latent regression with all coefficients estimated
    covariate <- stats::rnorm(nrow(resp))
    mod_bf <- irtc.mml(resp=resp, Y=matrix(covariate, ncol=1),
        beta.fixed=FALSE, verbose=FALSE, control=list(maxiter=10))
    expect_s3_class(mod_bf, "irtc")
})

test_that("irtc_itemfit covers multidim models and column mismatches", {
    resp <- irtc_test_sim_cov(n=150, k=6, seed=121)
    Q <- matrix(0, 6, 2)
    Q[1:3, 1] <- 1
    Q[4:6, 2] <- 1
    mod_md <- irtc.mml(resp=resp, Q=Q, verbose=FALSE,
        control=list(maxiter=10))
    fit_md <- irtc_itemfit(mod_md)
    expect_equal(nrow(fit_md), 6L)
    expect_true(all(is.finite(fit_md$outfit)))

    cond <- tryCatch(irtc_itemfit(mod_md, resp=resp[, 1:4]),
        condition=function(c) c)
    expect_equal(cond$code, "E403")
})

test_that("streaming engine guards reject missing covariate values", {
    resp <- irtc_test_sim_cov(n=100, k=6, seed=123)
    y_na <- matrix(c(NA_real_, stats::rnorm(99)), ncol=1)
    expect_error(irtc.mml.2pl(resp=resp, irtmodel="2PL",
        method="streaming", Y=y_na, verbose=FALSE,
        control=list(maxiter=5)), "missing values")
    g_na <- c(NA_integer_, rep(1:2, length.out=99))
    expect_error(irtc.mml.2pl(resp=resp, irtmodel="2PL",
        method="streaming", group=g_na, verbose=FALSE,
        control=list(maxiter=5)), "missing values")
    w_na <- c(NA_real_, rep(1, 99))
    expect_error(irtc.mml.2pl(resp=resp, irtmodel="2PL",
        method="streaming", pweights=w_na, verbose=FALSE,
        control=list(maxiter=5)), "missing values")
})

test_that("streaming engine accepts tolerance overrides and verbose", {
    resp <- irtc_test_sim_cov(n=150, k=6, seed=125)
    out <- utils::capture.output(
        mod_st <- irtc.mml.2pl(resp=resp, irtmodel="2PL",
            method="streaming", verbose=TRUE,
            control=list(maxiter=8, tol_deviance=1e-2,
                group_structure="full")))
    expect_s3_class(mod_st, "irtc")
    expect_true(any(grepl("engine", out)))
})

test_that("irtc.mml.2pl covers groups, multidim and stochastic verbose", {
    resp <- irtc_test_sim_cov(n=150, k=6, seed=127)

    ## multiple groups with progress display (G > 1 print branch)
    utils::capture.output(
        mod_g <- irtc.mml.2pl(resp=resp, irtmodel="2PL",
            group=rep(1:2, length.out=150), verbose=TRUE,
            control=list(maxiter=8)))
    expect_equal(mod_g$G, 2)

    ## between-item multidimensional with progress display
    Q <- matrix(0, 6, 2)
    Q[1:3, 1] <- 1
    Q[4:6, 2] <- 1
    utils::capture.output(
        mod_md <- irtc.mml.2pl(resp=resp, irtmodel="2PL", Q=Q,
            method="grid", verbose=TRUE, control=list(maxiter=8)))
    expect_equal(mod_md$ndim, 2)

    ## Monte-Carlo nodes with progress (deviance non-monotone branch)
    utils::capture.output(
        mod_mc <- irtc.mml.2pl(resp=resp, irtmodel="2PL", method="grid",
            verbose=TRUE, control=list(maxiter=8, snodes=300,
                QMC=FALSE)))
    expect_s3_class(mod_mc, "irtc")

    ## within-item multidimensional loading pattern (advanced routing)
    Q2 <- matrix(0, 6, 2)
    Q2[, 1] <- 1
    Q2[1, 2] <- 1
    mod_wi <- irtc.mml.2pl(resp=resp, irtmodel="2PL", Q=Q2,
        method="grid", verbose=FALSE, control=list(maxiter=8))
    expect_s3_class(mod_wi, "irtc")
})

test_that("irtc.mml.2pl covers design, fixed and control variants", {
    resp <- irtc_test_sim_cov(n=150, k=6, seed=129)

    ## fixed variance entries force est.variance
    mod_vf <- irtc.mml.2pl(resp=resp, irtmodel="2PL",
        variance.fixed=cbind(1, 1, 1), method="grid", verbose=FALSE,
        control=list(maxiter=8))
    expect_s3_class(mod_vf, "irtc")

    ## user-supplied starting B array
    B0 <- array(0, dim=c(6, 2, 1))
    B0[, 2, 1] <- 1
    mod_b <- irtc.mml.2pl(resp=resp, irtmodel="2PL", B=B0,
        method="grid", verbose=FALSE, control=list(maxiter=8))
    expect_s3_class(mod_b, "irtc")

    ## fixed slope entries
    mod_bf <- irtc.mml.2pl(resp=resp, irtmodel="2PL",
        B.fixed=matrix(c(1, 2, 1, 1), 1, 4), method="grid",
        verbose=FALSE, control=list(maxiter=8))
    expect_s3_class(mod_bf, "irtc")

    ## keep unobserved categories and relative deviance criterion
    mod_ie <- irtc.mml.2pl(resp=resp, irtmodel="2PL", item.elim=FALSE,
        method="grid", verbose=FALSE, control=list(maxiter=8))
    expect_s3_class(mod_ie, "irtc")
    mod_dc <- irtc.mml.2pl(resp=resp, irtmodel="2PL", method="grid",
        verbose=FALSE, control=list(maxiter=8, dev_crit="relative"))
    expect_s3_class(mod_dc, "irtc")

    ## GPCM with a slope design matrix (GPCM.design)
    data(data.gpcm)
    mod_gd <- irtc.mml.2pl(resp=data.gpcm, irtmodel="GPCM.design",
        E=matrix(1, 3, 1), gamma.init=1, method="grid", verbose=FALSE,
        control=list(maxiter=8))
    expect_s3_class(mod_gd, "irtc")
})

test_that("irtc_score rejects rules for unknown items", {
    resp <- data.frame(Q1=c("A", "B"), stringsAsFactors=FALSE)
    rules <- data.frame(item="QX", response="A", score=1,
        stringsAsFactors=FALSE)
    cond <- tryCatch(irtc_score(resp, rules=rules),
        condition=function(c) c)
    expect_equal(cond$code, "E204")
})

test_that("irtc_score handles list keys and literal NA strings", {
    resp <- data.frame(Q1=c("A", "NA", "B"), Q2=c("", "C", "C"),
        stringsAsFactors=FALSE)
    out <- irtc_score(resp, key=list(Q1="A", Q2="C"))
    expect_equal(out$Q1, c(1, NA, 0))
    expect_equal(out$Q2, c(NA, 1, 1))
})

test_that("irtc_excel computes quality on the fly and validates input", {
    testthat::skip_if_not_installed("openxlsx")
    resp <- irtc_test_sim_cov(n=100, k=4, seed=113)
    mod <- irtc.mml(resp=resp, verbose=FALSE, control=list(maxiter=20))
    dir <- file.path(tempdir(), paste0("irtccov", sample.int(1e6, 1)))
    ## bare irtc.mml model: quality is computed from mod$resp on the fly
    paths <- suppressMessages(irtc_excel(mod, dir=dir, lang="en",
        verbose=FALSE))
    expect_true(all(file.exists(paths)))

    fake <- structure(list(resp=NULL), class="irtc")
    cond <- tryCatch(irtc_excel(fake,
        dir=file.path(dir, "fake")), condition=function(c) c)
    expect_equal(cond$code, "E402")
})
