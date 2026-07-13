test_that("argument and list helpers preserve their public contracts", {
    arguments <- list(alpha=1, beta=2)

    expect_identical(
        irtc_args_replace_value(arguments, "beta", 9),
        list(alpha=1, beta=9)
    )
    expect_identical(irtc_args_replace_value(arguments), arguments)
    expect_true(irtc_in_names_list(arguments, "alpha"))
    expect_false(irtc_in_names_list(arguments, "gamma"))
    expect_false(irtc_in_names_list(list(1, 2), "alpha"))

    target <- new.env(parent=emptyenv())
    expect_invisible(irtc_assign_list_elements(list(first=1, second="two"), target))
    expect_identical(target$first, 1)
    expect_identical(target$second, "two")
})

test_that("rounding helpers handle tabular and vector inputs", {
    table <- data.frame(a=c(1.234, 2.345), b=c(3.456, 4.567))
    rounded <- irtc_round_data_frame(
        table, from=2, to=2, digits=1, rownames_null=TRUE
    )

    expect_equal(rounded$a, table$a)
    expect_equal(rounded$b, c(3.5, 4.6))
    expect_identical(rownames(rounded), c("1", "2"))
    expect_equal(irtc_round_data_frame(c(1.25, 2.35), digits=1), c(1.2, 2.4))

    printed <- capture.output(returned <- irtc_round_data_frame_print(
        table, digits=1
    ))
    expect_true(length(printed) > 0)
    expect_equal(returned, irtc_round_data_frame(table, digits=1))
})

test_that("sink helpers open and close the requested output", {
    output_base <- tempfile("irtc-sink-")
    initial_sink_depth <- sink.number()
    on.exit({
        while (sink.number() > initial_sink_depth) sink()
        unlink(paste0(output_base, ".Rout"))
    }, add=TRUE)

    expect_invisible(irtc_osink(output_base))
    cat("captured output\n")
    expect_invisible(irtc_csink(output_base))

    expect_match(readLines(paste0(output_base, ".Rout")), "captured output")
    expect_null(irtc_cat("unused", Sys.time(), active=FALSE))
})

test_that("compatibility helpers provide namespace checks and normal draws", {
    expect_invisible(irtc_require_namespace("stats"))
    expect_invisible(require_namespace_msg("stats"))
    expect_error(
        irtc_require_namespace("irtcPackageThatCannotExist"),
        "Package 'irtcPackageThatCannotExist' is needed"
    )

    mean <- c(1, -1)
    covariance <- matrix(c(2, .25, .25, 1), 2, 2)
    set.seed(42)
    expected <- MASS::mvrnorm(n=4, mu=mean, Sigma=covariance)
    set.seed(42)
    observed <- irtc_rmvnorm(n=4, mean=mean, sigma=covariance)

    expect_identical(observed, expected)
})
