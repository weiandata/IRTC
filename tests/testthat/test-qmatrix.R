# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-qmatrix.R
## Tests for irtc_read_q(), irtc_align_q() and the q= wiring in irtc().

irtc_test_sim_q <- function(n=200, k=6, seed=21)
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

test_that("irtc_read_q reads a data frame with named columns", {
    qdf <- data.frame(item=c("I1", "I2", "I3"),
        algebra=c(1, 1, 0), geometry=c(0, 0, 1))
    qm <- irtc_read_q(qdf)
    expect_s3_class(qm, "irtc_qmatrix")
    expect_equal(dim(qm$Q), c(3L, 2L))
    expect_equal(rownames(qm$Q), c("I1", "I2", "I3"))
    expect_equal(colnames(qm$Q), c("algebra", "geometry"))
    expect_equal(unname(qm$partial), rep(FALSE, 3))
    expect_true(all(is.na(qm$max_score)))
})

test_that("irtc_read_q uses the first text column when no item name hits", {
    qdf <- data.frame(name_of_task=c("A", "B"), d1=c(1, 0), d2=c(0, 1))
    qm <- irtc_read_q(qdf)
    expect_equal(rownames(qm$Q), c("A", "B"))
    expect_equal(colnames(qm$Q), c("d1", "d2"))
})

test_that("irtc_read_q accepts a numeric matrix with rownames", {
    Q <- matrix(c(1, 0, 1, 0, 1, 0), nrow=3,
        dimnames=list(c("I1", "I2", "I3"), c("d1", "d2")))
    qm <- irtc_read_q(Q)
    expect_equal(qm$Q, Q)
})

test_that("irtc_read_q parses 0/1 partial-credit flags", {
    qdf <- data.frame(item=c("I1", "I2"), d1=c(1, 1), partial=c(0, 1))
    qm <- irtc_read_q(qdf)
    expect_equal(qm$partial, c(I1=FALSE, I2=TRUE))
    expect_true(all(is.na(qm$max_score)))
})

test_that("irtc_read_q parses max scores and Chinese yes/no", {
    qdf <- data.frame(item=c("I1", "I2", "I3"), d1=c(1, 1, 1),
        max_score=c(1, 2, 3))
    qm <- irtc_read_q(qdf)
    expect_equal(qm$partial, c(I1=FALSE, I2=TRUE, I3=TRUE))
    expect_equal(qm$max_score, c(I1=1L, I2=2L, I3=3L))

    qdf2 <- data.frame(item=c("I1", "I2"), d1=c(1, 1))
    qdf2[["\u5206\u90e8\u8ba1\u5206"]] <- c("\u5426", "\u662f")
    qm2 <- irtc_read_q(qdf2)
    expect_equal(qm2$partial, c(I1=FALSE, I2=TRUE))
})

test_that("irtc_read_q reads from csv and xlsx files", {
    qdf <- data.frame(item=c("I1", "I2"), d1=c(1, 0), d2=c(0, 1),
        partial=c(1, 0))
    path <- tempfile(fileext=".csv")
    utils::write.csv(qdf, path, row.names=FALSE)
    qm <- irtc_read_q(path)
    expect_equal(rownames(qm$Q), c("I1", "I2"))
    expect_equal(qm$partial, c(I1=TRUE, I2=FALSE))
    unlink(path)
    testthat::skip_if_not_installed("writexl")
    testthat::skip_if_not_installed("readxl")
    xpath <- tempfile(fileext=".xlsx")
    writexl::write_xlsx(qdf, xpath)
    qmx <- irtc_read_q(xpath)
    expect_equal(qmx$Q, qm$Q)
    unlink(xpath)
})

test_that("irtc_read_q treats empty cells as zero with a log entry", {
    qdf <- data.frame(item=c("I1", "I2"), d1=c(1, NA), d2=c(NA, 1))
    qm <- irtc_read_q(qdf)
    expect_equal(unname(qm$Q[, "d1"]), c(1, 0))
    expect_true("I131" %in% qm$log$code)
})

test_that("irtc_read_q validates its input", {
    cond <- tryCatch(irtc_read_q(1:3), condition=function(c) c)
    expect_equal(cond$code, "E110")
    cond <- tryCatch(
        irtc_read_q(data.frame(item=c("I1", "I1"), d1=c(1, 1))),
        condition=function(c) c)
    expect_equal(cond$code, "E112")
    cond <- tryCatch(
        irtc_read_q(data.frame(item=c("I1", "I2"))),
        condition=function(c) c)
    expect_equal(cond$code, "E113")
    cond <- tryCatch(
        irtc_read_q(data.frame(item=c("I1", "I2"), d1=c(1, 1),
            note=c("x", "y"), stringsAsFactors=FALSE)),
        condition=function(c) c)
    expect_equal(cond$code, "E113")
    cond <- tryCatch(
        irtc_read_q(data.frame(item=c("I1", "I2"), d1=c(1, 0))),
        condition=function(c) c)
    expect_equal(cond$code, "E114")
    cond <- tryCatch(
        irtc_read_q(data.frame(item=c("I1", "I2"), d1=c(1, 1),
            partial=c("maybe", "yes"))),
        condition=function(c) c)
    expect_equal(cond$code, "E115")
})

test_that("irtc_read_q reports missing files and empty / bad ID columns", {
    cond <- tryCatch(irtc_read_q("no_such_q_file_xyz.csv"),
        condition=function(c) c)
    expect_equal(cond$code, "E103")
    ## empty data frame -> empty-matrix error
    cond <- tryCatch(irtc_read_q(data.frame()), condition=function(c) c)
    expect_equal(cond$code, "E110")
    ## all-numeric columns, no name in the item pool -> no ID column
    cond <- tryCatch(irtc_read_q(data.frame(a=c(1, 2), b=c(1, 0))),
        condition=function(c) c)
    expect_equal(cond$code, "E111")
    ## an ID column that contains an empty value
    cond <- tryCatch(
        irtc_read_q(data.frame(item=c("I1", ""), d1=c(1, 1))),
        condition=function(c) c)
    expect_equal(cond$code, "E111")
    ## a numeric matrix without rownames falls through to the data-frame
    ## path and then fails to find an ID column
    cond <- tryCatch(irtc_read_q(matrix(c(1, 0, 1, 0), 2)),
        condition=function(c) c)
    expect_equal(cond$code, "E111")
})

test_that("irtc_align_q reads a raw Q input and validates the data type", {
    resp <- irtc_test_sim_q(n=15, k=3)  # I1..I3
    ## pass a raw data.frame (not yet an irtc_qmatrix): align reads it
    al <- irtc_align_q(resp, data.frame(item=c("I1", "I2", "I3"),
        d1=rep(1, 3)))
    expect_equal(rownames(al$q$Q), c("I1", "I2", "I3"))
    ## a non-data input for 'data' is rejected
    cond <- tryCatch(
        irtc_align_q(1:3, irtc_read_q(data.frame(item=c("I1", "I2"),
            d1=c(1, 1)))),
        condition=function(c) c)
    expect_equal(cond$code, "E201")
})

test_that("irtc_align_q warns and aligns on mismatch", {
    resp <- irtc_test_sim_q(n=20, k=4)  # I1..I4
    qdf <- data.frame(item=c("I1", "I2", "I3", "I9"), d1=c(1, 1, 1, 1))
    qm <- irtc_read_q(qdf)
    w <- testthat::capture_warnings(al <- irtc_align_q(resp, qm))
    expect_true(any(grepl("W420", w)))
    expect_true(any(grepl("W421", w)))
    expect_equal(al$q_only, "I9")
    expect_equal(al$data_only, "I4")
    expect_equal(colnames(al$data), c("I1", "I2", "I3"))
    expect_equal(rownames(al$q$Q), c("I1", "I2", "I3"))
})

test_that("irtc_align_q reorders the Q matrix to data column order", {
    resp <- irtc_test_sim_q(n=10, k=3)
    qdf <- data.frame(item=c("I3", "I1", "I2"), d1=c(1, 1, 0),
        d2=c(0, 0, 1))
    al <- irtc_align_q(resp, irtc_read_q(qdf))
    expect_equal(rownames(al$q$Q), c("I1", "I2", "I3"))
    expect_equal(unname(al$q$Q[, "d2"]), c(0, 1, 0))
})

test_that("irtc_align_q stops on mismatch in error mode", {
    resp <- irtc_test_sim_q(n=10, k=4)
    qdf <- data.frame(item=c("I1", "I2", "I3", "I9"), d1=rep(1, 4))
    cond <- tryCatch(
        irtc_align_q(resp, irtc_read_q(qdf), on_mismatch="error"),
        condition=function(c) c)
    expect_equal(cond$code, "E422")
    expect_equal(cond$data$q_only, "I9")
})

test_that("irtc_align_q stops when fewer than 2 items are shared", {
    resp <- irtc_test_sim_q(n=10, k=3)
    qdf <- data.frame(item=c("X1", "X2"), d1=c(1, 1))
    cond <- tryCatch(irtc_align_q(resp, irtc_read_q(qdf)),
        condition=function(c) c)
    expect_equal(cond$code, "E422")
})

test_that("irtc_align_q updates irtc_data objects and their log", {
    resp <- irtc_test_sim_q(n=15, k=4)
    d <- irtc_read(resp, verbose=FALSE)
    qdf <- data.frame(item=c("I1", "I2", "I3"), d1=rep(1, 3))
    expect_warning(al <- irtc_align_q(d, irtc_read_q(qdf)),
        class="irtc_warning_estimation")
    expect_s3_class(al$data, "irtc_data")
    expect_equal(ncol(al$data$resp), 3L)
    expect_true("W421" %in% al$data$log$code)
})

test_that("print.irtc_qmatrix shows dimensions and partial items", {
    qdf <- data.frame(item=c("I1", "I2"), alg=c(1, 1), geo=c(0, 1),
        max_score=c(1, 2))
    qm <- irtc_read_q(qdf)
    txt <- paste(capture.output(print(qm, lang="en")), collapse="\n")
    expect_match(txt, "alg, geo")
    expect_match(txt, "Partial-credit items: 1")
    expect_match(txt, "I2 \\(max 2\\)")
})

test_that("irtc estimates a unidimensional model with q from a file", {
    resp <- irtc_test_sim_q(n=150, k=5)
    qdf <- data.frame(item=paste0("I", 1:5), ability=rep(1, 5))
    path <- tempfile(fileext=".csv")
    utils::write.csv(qdf, path, row.names=FALSE)
    mod <- irtc(resp, model="1PL", q=path, verbose=FALSE)
    expect_s3_class(mod, "irtc")
    expect_equal(mod$nitems, 5L)
    expect_s3_class(mod$usability$q, "irtc_qmatrix")
    expect_equal(colnames(mod$usability$q$Q), "ability")
    unlink(path)
})

test_that("irtc estimates a between-item multidimensional model with q", {
    resp <- irtc_test_sim_q(n=200, k=6)
    qdf <- data.frame(item=paste0("I", 1:6),
        dim_a=c(1, 1, 1, 0, 0, 0), dim_b=c(0, 0, 0, 1, 1, 1))
    mod <- irtc(resp, model="1PL", q=qdf, verbose=FALSE,
        control=list(maxiter=30))
    expect_equal(mod$ndim, 2L)
    ref <- irtc.mml(resp=as.matrix(resp), irtmodel="1PL",
        Q=as.matrix(irtc_read_q(qdf)$Q), verbose=FALSE,
        control=list(maxiter=30))
    expect_equal(mod$xsi$xsi, ref$xsi$xsi, tolerance=1e-6)
})

test_that("irtc q= aligns items and drops mismatches with warnings", {
    resp <- irtc_test_sim_q(n=150, k=6)
    qdf <- data.frame(item=c(paste0("I", 1:5), "I99"), d1=rep(1, 6))
    w <- testthat::capture_warnings(
        mod <- irtc(resp, model="1PL", q=qdf, verbose=FALSE))
    expect_true(any(grepl("W420", w)))
    expect_true(any(grepl("W421", w)))
    expect_equal(mod$nitems, 5L)
})

test_that("explicit Q beats q= with W419", {
    resp <- irtc_test_sim_q(n=120, k=4)
    qdf <- data.frame(item=paste0("I", 1:4), d1=rep(1, 4))
    Qexp <- matrix(1, nrow=4, ncol=1,
        dimnames=list(paste0("I", 1:4), "expl"))
    expect_warning(
        mod <- irtc(resp, model="1PL", q=qdf, Q=Qexp, verbose=FALSE),
        class="irtc_warning_estimation")
    expect_s3_class(mod, "irtc")
})
