test_that("engine survives pathological inputs without crashing or producing NA", {
  kinds <- c("empty_cat", "extreme_item", "low_disc", "high_disc",
             "corr_thresh", "sparse_region", "bad_init", "weak_dim")
  for (kind in kinds) {
    d <- sp4_simulate_pathology(kind, N = 3000, seed = 1)
    obj <- IRTC:::irtc_proto_run_and_build(d$resp, d$dim_of, maxK = d$maxK, Q = 21,
                                           maxiter = 60)
    expect_true(all(is.finite(c(obj$a, as.numeric(obj$variance)))), info = kind)
    expect_true(all(eigen(obj$variance, symmetric = TRUE)$values > 0), info = kind)
    expect_true(is.finite(obj$deviance), info = kind)
  }
})
