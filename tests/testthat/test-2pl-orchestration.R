test_that("irtc.mml.2pl grid route assembles stable slope estimates", {
    data(data.sim.rasch)
    fit <- irtc.mml.2pl(
        data.sim.rasch[1:30, 1:4], method="grid", verbose=FALSE,
        control=list(
            maxiter=2, nodes=seq(-3, 3, length.out=7),
            Msteps=2, n_threads=1
        )
    )

    expect_s3_class(fit, "irtc")
    expect_equal(fit$routing$engine, "grid")
    expect_equal(fit$routing$reason, "user: grid")
    expect_equal(fit$iter, 2)
    expect_equal(fit$irtmodel, "2PL")
    expect_equal(
        as.numeric(fit$xsi$xsi),
        c(-2.35235886775372, -2.03723816104811, rep(-1.84130334083813, 2)),
        tolerance=1e-12
    )
    expect_equal(
        as.numeric(fit$B),
        c(rep(0, 4), .432678202653487, 1.49733487296678,
          .912285357740723, .912285357740723),
        tolerance=1e-12
    )
    expect_equal(fit$deviance, 98.6943738974289, tolerance=1e-12)
})

test_that("irtc.mml.2pl grid route retains GPCM category slopes", {
    data(data.gpcm)
    fit <- irtc.mml.2pl(
        data.gpcm[1:30, 1:3], irtmodel="GPCM", method="grid",
        verbose=FALSE,
        control=list(
            maxiter=1, nodes=seq(-2, 2, length.out=5),
            Msteps=1, n_threads=1
        )
    )

    expect_equal(fit$irtmodel, "GPCM")
    expect_equal(fit$maxK, 4)
    expect_equal(fit$iter, 1)
    expect_equal(
        as.numeric(fit$xsi$xsi),
        c(
            -1.64744665833657, -.078368584981054, 1.17341972677537,
            -.445156120728707, .595402858950193, 2.18010988207215,
            -1.87373314832733, -.677492599643091, 1.92054951078205
        ),
        tolerance=1e-12
    )
    expect_equal(fit$deviance, 216.63132254146, tolerance=1e-12)
})

test_that("irtc.mml.2pl streaming route returns before grid orchestration", {
    data(data.sim.rasch)
    fit <- irtc.mml.2pl(
        data.sim.rasch[1:30, 1:4], method="streaming", verbose=FALSE,
        control=list(nodes=seq(-2, 2, length.out=5), n_threads=1)
    )

    expect_s3_class(fit, "irtc")
    expect_equal(fit$routing$engine, "streaming")
    expect_equal(fit$routing$reason, "user: streaming")
    expect_equal(c(fit$nstud, fit$nitems), c(30, 4))
})
