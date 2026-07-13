test_that("irtc.mml assembles a stable one-dimensional EM result", {
    data(data.sim.rasch)
    fit <- irtc.mml(
        data.sim.rasch[1:30, 1:4], verbose=FALSE,
        control=list(
            maxiter=2, nodes=seq(-3, 3, length.out=7),
            Msteps=2, n_threads=1
        )
    )

    expect_s3_class(fit, "irtc")
    expect_equal(fit$iter, 2)
    expect_equal(fit$irtmodel, "1PL")
    expect_equal(c(fit$nstud, fit$nitems, fit$maxK), c(30, 4, 2))
    expect_equal(dim(fit$A), c(4, 2, 4))
    expect_equal(dim(fit$B), c(4, 2, 1))
    expect_equal(
        as.numeric(fit$xsi$xsi),
        c(-2.52313670221269, rep(-1.8704514686815, 3)),
        tolerance=1e-12
    )
    expect_equal(fit$deviance, 99.5282722891151, tolerance=1e-12)
    expect_equal(nrow(fit$person), 30)
    expect_equal(dim(fit$post), c(30, 7))
    expect_equal(fit$control$n_threads, 1L)
})

test_that("item constraint route switches the main entry to PCM2", {
    data(data.sim.rasch)
    fit <- irtc.mml(
        data.sim.rasch[1:20, 1:3], constraint="items", verbose=FALSE,
        control=list(
            maxiter=1, nodes=seq(-2, 2, length.out=5),
            Msteps=1, n_threads=1
        )
    )

    expect_equal(fit$irtmodel, "PCM2")
    expect_equal(fit$iter, 1)
    expect_false(fit$printxsi)
    expect_equal(fit$G, 1)
    expect_equal(fit$groups, 1)
    expect_equal(
        as.numeric(fit$xsi$xsi), c(2.02394146330176, 3.19517496806195),
        tolerance=1e-12
    )
    expect_equal(fit$deviance, 218.96383996933, tolerance=1e-12)
})
