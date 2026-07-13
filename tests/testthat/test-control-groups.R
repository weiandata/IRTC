test_that("group initialization sorts labels and records first members", {
  expect_identical(
    IRTC:::irtc_mml_inits_groups(c("b", "a", "b", NA_character_)),
    list(
      G = 2L,
      groups = c("a", "b"),
      group = c(2L, 1L, 2L, NA_integer_),
      var.indices = c(2, 1)
    )
  )

  expect_identical(
    IRTC:::irtc_mml_inits_groups(NULL),
    list(G = 1, groups = NULL, group = NULL, var.indices = NULL)
  )
})

test_that("constraint aliases and validation retain their exact contract", {
  expect_identical(IRTC:::irtc_mml_constraint_check("item"), "items")
  expect_identical(IRTC:::irtc_mml_constraint_check("case"), "cases")
  expect_identical(IRTC:::irtc_mml_constraint_check("items"), "items")
  expect_error(
    IRTC:::irtc_mml_constraint_check("invalid"),
    "Please choose one of the constraints: 'items' or 'cases'\n",
    fixed = TRUE
  )
})

test_that("control defaults, overrides and environment assignments are preserved", {
  target <- new.env(parent = emptyenv())
  result <- IRTC:::irtc_mml_control_list_define(
    control = list(fac.oldxsi = 2, progress = "F", n_threads = 64L),
    envir = target,
    irtc_fct = "irtc.mml",
    prior_list_xsi = NULL
  )

  expect_identical(result$con, result$con1a)
  expect_identical(result$con$fac.oldxsi, 0.95)
  expect_false(result$con$progress)
  expect_identical(result$con$n_threads, 2L)
  expect_identical(result$con$mstep_intercept_method, "R")
  expect_false("seed" %in% names(result$con))
  expect_false(exists("seed", envir = target, inherits = FALSE))
  expect_identical(target$fac.oldxsi, 0.95)
  expect_false(target$progress)
  expect_identical(target$n_threads, 2L)
  expect_identical(target$mstep_intercept_method, "R")
})

test_that("control prior and non-MML routing retain list shape", {
  prior_env <- new.env(parent = emptyenv())
  prior_result <- IRTC:::irtc_mml_control_list_define(
    control = list(), envir = prior_env, irtc_fct = "irtc.mml",
    prior_list_xsi = list(list("normal"))
  )
  expect_identical(prior_result$con$mstep_intercept_method, "optim")

  two_pl_env <- new.env(parent = emptyenv())
  two_pl_result <- IRTC:::irtc_mml_control_list_define(
    control = list(progress = "T", n_threads = "bad", fac.oldxsi = -2),
    envir = two_pl_env, irtc_fct = "irtc.mml.2pl",
    prior_list_xsi = NULL
  )
  expect_true(two_pl_result$con$progress)
  expect_identical(two_pl_result$con$n_threads, 1L)
  expect_identical(two_pl_result$con$fac.oldxsi, 0)
  expect_false("mstep_intercept_method" %in% names(two_pl_result$con))
})

test_that("deviance history has stable shape, names and iteration column", {
  expected <- matrix(c(1, 2, 3, 0, 0, 0), nrow = 3, ncol = 2)
  colnames(expected) <- c("iter", "deviance")
  expect_identical(IRTC:::irtc_deviance_history_init(3), expected)

  empty <- IRTC:::irtc_deviance_history_init(0)
  expect_identical(dim(empty), c(0L, 2L))
  expect_identical(colnames(empty), c("iter", "deviance"))
  expect_error(
    IRTC:::irtc_deviance_history_init(-1),
    "invalid 'nrow' value (< 0)", fixed = TRUE
  )
  expect_error(
    IRTC:::irtc_deviance_history_init(NA_real_),
    "invalid 'nrow' value (too large or NA)", fixed = TRUE
  )
})
