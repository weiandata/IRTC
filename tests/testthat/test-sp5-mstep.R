test_that("analytic GPCM gradient/Hessian match numerical (2PL and GPCM)", {
  x <- seq(-4, 4, length.out = 11)
  for (maxK in c(2L, 4L)) {
    set.seed(maxK)
    nik <- matrix(abs(rnorm(maxK * length(x))) + 0.1, maxK, length(x))  # counts
    par <- c(1.3, sort(rnorm(maxK - 1)))
    f <- function(p) {
      Pp <- irtc_proto_item_probs(p[1], p[-1], x, maxK)   # Q x maxK
      -sum(t(nik) * log(pmax(Pp, 1e-300)))
    }
    gh <- irtc_proto_item_gh(par, nik, x, maxK)
    g_num <- numeric(length(par))
    for (i in seq_along(par)) { pp<-par; pm<-par; pp[i]<-pp[i]+1e-5; pm[i]<-pm[i]-1e-5
      g_num[i] <- (f(pp)-f(pm))/(2e-5) }
    expect_equal(gh$g, g_num, tolerance = 1e-4)
    # Hessian by central difference of the gradient
    H_num <- matrix(0, length(par), length(par))
    for (i in seq_along(par)) { pp<-par; pm<-par; pp[i]<-pp[i]+1e-5; pm[i]<-pm[i]-1e-5
      H_num[,i] <- (irtc_proto_item_gh(pp,nik,x,maxK)$g - irtc_proto_item_gh(pm,nik,x,maxK)$g)/(2e-5) }
    expect_equal(gh$H, H_num, tolerance = 1e-3)
  }
})

test_that("hybrid M-step recovers item params and survives near-singular Hessian", {
  x <- seq(-5, 5, length.out = 21)
  a0 <- 1.4; b0 <- 0.3
  P <- irtc_proto_item_probs(a0, b0, x, 2L)        # Q x 2
  w <- dnorm(x); nik <- t(P * (w * 1000))           # 2 x Q counts proportional to truth
  fit <- irtc_proto_mstep_item(1, 0, nik, x, 2L)
  expect_equal(fit$a, a0, tolerance = 0.05)
  expect_equal(fit$bvec, b0, tolerance = 0.05)
  # near-empty category (GPCM) must not crash / NA
  nik2 <- matrix(c(rep(50, 21), rep(50, 21), rep(1e-8, 21), rep(50, 21)), 4, 21, byrow = TRUE)
  fit2 <- irtc_proto_mstep_item(1, c(-1, 0, 1), nik2, x, 4L)
  expect_true(all(is.finite(c(fit2$a, fit2$bvec))))
})
