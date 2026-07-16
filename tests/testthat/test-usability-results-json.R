# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: test-usability-results-json.R
## Tests for irtc_results() and irtc_json().

irtc_test_sim_results <- function(n=150, k=5, seed=41)
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

test_that("irtc_results returns the documented schema", {
    resp <- irtc_test_sim_results()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    res <- irtc_results(mod)
    expect_s3_class(res, "irtc_results")
    expect_named(res, c("model_info", "items", "persons", "cleaning_log",
        "check_issues"))

    mi <- res$model_info
    expect_equal(nrow(mi), 1L)
    expect_true(all(c("schema_version", "package_version", "model",
        "n_persons", "n_items", "n_dimensions", "deviance", "n_parameters",
        "aic", "bic", "eap_reliability", "iterations") %in% colnames(mi)))
    expect_equal(mi$model, "1PL")
    expect_equal(mi$n_persons, 150L)

    it <- res$items
    expect_equal(nrow(it), 5L)
    expect_true(all(c("item_id", "n_obs", "p_value", "slope_a",
        "difficulty_b", "discr_ctt", "outfit", "infit", "rating",
        "reasons_en", "reasons_zh") %in% colnames(it)))
    expect_true(all(it$rating %in%
        c("good", "acceptable", "review", "revise")))
    ## merge must preserve item order
    expect_equal(it$item_id, paste0("I", 1:5))

    pe <- res$persons
    expect_equal(nrow(pe), 150L)
    expect_true(all(c("person_id", "n_answered", "raw_score", "eap",
        "percentile", "t_score") %in% colnames(pe)))

    expect_output(print(res), "model_info")
})

test_that("irtc_results works on bare irtc.mml objects", {
    resp <- irtc_test_sim_results()
    mod <- irtc.mml(resp=resp, verbose=FALSE)
    res <- irtc_results(mod)
    expect_equal(res$model_info$model, "1PL")
    expect_equal(nrow(res$items), 5L)
    expect_null(res$cleaning_log)
})

test_that("irtc_json produces valid JSON", {
    testthat::skip_if_not_installed("jsonlite")
    resp <- irtc_test_sim_results()
    mod <- irtc(resp, model="1PL", verbose=FALSE)
    json <- irtc_json(mod)
    parsed <- jsonlite::fromJSON(json)
    expect_equal(parsed$model_info$model, "1PL")
    expect_equal(nrow(parsed$items), 5L)

    file <- tempfile(fileext=".json")
    irtc_json(mod, file=file)
    expect_true(file.exists(file))
    parsed2 <- jsonlite::fromJSON(file)
    expect_equal(parsed2$model_info$n_persons, 150L)
    unlink(file)
})

test_that("irtc_results validates input", {
    cond <- tryCatch(irtc_results("x"), condition=function(c) c)
    expect_equal(cond$code, "E401")
})
