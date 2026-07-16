# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-usability-excel.R
## Tests for irtc_excel() and the underlying tables.

irtc_test_sim_excel <- function(n=200, k=6, seed=21)
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

test_that("irtc_param_table has the frozen linking schema", {
    resp <- irtc_test_sim_excel()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    tbl <- irtc_param_table(mod, resp=mod$resp)
    expect_equal(colnames(tbl)[1:9],
        c("schema_version", "analysis_id", "model", "item_id", "n_obs",
          "p_value", "slope_a", "difficulty_b", "se_b"))
    expect_equal(tbl$schema_version, rep("1.0", 6L))
    expect_equal(tbl$item_id, paste0("I", 1:6))
    ## difficulty should increase with the generating b parameters
    expect_true(tbl$difficulty_b[6L] > tbl$difficulty_b[1L])
    expect_true(all(is.finite(tbl$difficulty_b)))
})

test_that("irtc_param_table includes tau columns for polytomous models", {
    data(data.gpcm)
    mod <- irtc.mml(resp=data.gpcm, irtmodel="PCM", verbose=FALSE)
    tbl <- irtc_param_table(mod, resp=mod$resp)
    expect_true(any(grepl("^tau_", colnames(tbl))))
    expect_true(all(is.finite(tbl$difficulty_b)))
})

test_that("irtc_person_table is flat and row-aligned with the input", {
    resp <- irtc_test_sim_excel(n=100, k=5)
    mod <- irtc(cbind(id=paste0("P", 1:100), resp), model="1PL",
        verbose=FALSE)
    tbl <- irtc_person_table(mod, lang="en")
    expect_equal(nrow(tbl), 100L)
    expect_equal(tbl$person_id[1L], "P1")
    expect_true(all(c("ability_EAP", "percentile", "T_score") %in%
        colnames(tbl)))
    expect_true(abs(mean(tbl$T_score, na.rm=TRUE) - 50) < 1)
    tbl_zh <- irtc_person_table(mod, lang="zh")
    expect_true("\u80fd\u529b\u503cEAP" %in% colnames(tbl_zh))
})

test_that("irtc_excel writes three separate xlsx files", {
    testthat::skip_if_not_installed("openxlsx")
    resp <- irtc_test_sim_excel()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    dir <- file.path(tempdir(), paste0("irtcxl", sample.int(1e6, 1)))
    paths <- suppressMessages(irtc_excel(mod, dir=dir, lang="zh",
        verbose=FALSE))
    expect_length(paths, 3L)
    expect_true(all(file.exists(paths)))

    quality <- openxlsx::read.xlsx(paths[["quality"]], sheet=1)
    expect_equal(nrow(quality), 6L)
    expect_true("\u8d28\u91cf\u8bc4\u7ea7" %in% colnames(quality))

    params <- openxlsx::read.xlsx(paths[["parameters"]], sheet=1)
    expect_true(all(c("item_id", "difficulty_b", "slope_a") %in%
        colnames(params)))

    ability <- openxlsx::read.xlsx(paths[["ability"]], sheet=1)
    expect_equal(nrow(ability), 200L)

    ## refuses to overwrite unless asked
    cond <- tryCatch(irtc_excel(mod, dir=dir, verbose=FALSE),
        condition=function(c) c)
    expect_equal(cond$code, "E501")
    paths2 <- suppressMessages(irtc_excel(mod, dir=dir, overwrite=TRUE,
        verbose=FALSE))
    expect_true(all(file.exists(paths2)))

    ## English output
    paths_en <- suppressMessages(irtc_excel(mod, dir=dir, lang="en",
        prefix="EN", verbose=FALSE))
    quality_en <- openxlsx::read.xlsx(paths_en[["quality"]], sheet=1)
    expect_true("Overall.rating" %in% colnames(quality_en))
})

test_that("irtc_excel validates its input", {
    cond <- tryCatch(irtc_excel(list()), condition=function(c) c)
    expect_equal(cond$code, "E401")
})
