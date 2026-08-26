# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## SP4 experimental dimension-factorized streaming EM (no latent regression,
## no groups/weights). Estimates item params + correlated Sigma for a
## simple-structure multidim 2PL/GPCM. NOT part of the public API.

# GPCM category probabilities at nodes x for one item (slope a, thresholds bvec)
irtc_proto_item_probs <- function(a, bvec, x, maxK) {
  eta <- matrix(0, length(x), maxK)
  for (k in 1:(maxK - 1)) eta[, k + 1] <- eta[, k] + a * (x - bvec[k])
  P <- exp(eta - apply(eta, 1, max))
  P / rowSums(P)
}

# Analytic gradient & Hessian of the per-item GPCM/2PL negative log-likelihood.
# par = c(a, b_1..b_{maxK-1}); nik = maxK x Q expected counts; x = node vector.
irtc_proto_item_gh <- function(par, nik, x, maxK) {
  a <- par[1]; bvec <- par[-1]
  Q <- length(x); npar <- length(par)
  cb <- c(0, cumsum(bvec))              # cb_k, k = 0..maxK-1
  kk <- 0:(maxK - 1)
  g <- numeric(npar); H <- matrix(0, npar, npar)
  for (q in seq_len(Q)) {
    eta <- a * (kk * x[q] - cb)
    P <- exp(eta - max(eta)); P <- P / sum(P)
    nq <- nik[, q]; Nq <- sum(nq)
    S <- matrix(0, maxK, npar)
    S[, 1] <- kk * x[q] - cb            # d eta_k / d a
    if (maxK > 1) for (m in seq_len(maxK - 1)) S[(m + 1):maxK, 1 + m] <- -a
    dk <- nq - Nq * P                   # n_k - N*P_k
    g <- g - colSums(dk * S)
    PS <- P * S                         # maxK x npar
    Es <- colSums(PS)
    H <- H + Nq * (t(S) %*% PS - outer(Es, Es))   # expected (Fisher) part
    # observed-information cross term: d2 eta_k / d a d b_m = -I(k>=m)
    if (maxK > 1) for (m in seq_len(maxK - 1)) {
      cross_m <- sum(dk[(m + 1):maxK])
      H[1, 1 + m] <- H[1, 1 + m] + cross_m
      H[1 + m, 1] <- H[1 + m, 1] + cross_m
    }
  }
  list(g = g, H = H)
}

# Hybrid M-step (Layer A numerical safeguards): LM-damped Newton on the NLL +
# Armijo line search + BFGS fallback. nik = maxK x Q counts. Cost independent of N.
irtc_proto_mstep_item <- function(a, bvec, nik, x, maxK, maxit = 25L,
                                  slope_penalty = 0, slope_max = Inf) {
  tnik <- t(nik)
  negll <- function(par) {
    Pp <- irtc_proto_item_probs(par[1], par[-1], x, maxK)
    -sum(tnik * log(pmax(Pp, 1e-300))) + slope_penalty * par[1]^2   # Layer B penalty
  }
  par <- c(a, bvec); fcur <- negll(par); lambda <- 1e-3; npar <- length(par)
  for (it in seq_len(maxit)) {
    gh <- irtc_proto_item_gh(par, nik, x, maxK)
    if (slope_penalty > 0) {                       # penalty derivatives on the slope
      gh$g[1] <- gh$g[1] + 2 * slope_penalty * par[1]
      gh$H[1, 1] <- gh$H[1, 1] + 2 * slope_penalty
    }
    step <- tryCatch(solve(gh$H + lambda * diag(npar), gh$g),
                     error = function(e) NULL)
    if (is.null(step) || any(!is.finite(step))) {       # BFGS fallback
      fit <- tryCatch(stats::optim(par, negll, method = "BFGS",
                                   control = list(maxit = 20)),
                      error = function(e) list(par = par))
      par <- fit$par; break
    }
    tt <- 1; ok <- FALSE                                # Armijo backtracking
    for (ls in 1:20) {
      cand <- par - tt * step
      fcand <- negll(cand)
      if (is.finite(fcand) && fcand <= fcur - 1e-4 * tt * sum(gh$g * step)) {
        par <- cand; ok <- TRUE; break
      }
      tt <- tt / 2
    }
    if (ok) {
      lambda <- max(1e-8, lambda / 2); fnew <- negll(par)
      if (abs(fcur - fnew) < 1e-8) { fcur <- fnew; break }
      fcur <- fnew
    } else {
      lambda <- lambda * 10; if (lambda > 1e8) break
    }
  }
  if (!all(is.finite(par))) par <- c(a, bvec)        # Layer A: revert if degenerate
  par[-1] <- pmax(pmin(par[-1], 20), -20)            # bound thresholds (keep probs finite)
  list(a = min(par[1], slope_max), bvec = sort(par[-1]))
}

# nearest positive-definite (Layer A): clip eigenvalues to a small floor.
.nearest_pd <- function(S, eps = 1e-6) {
  if (any(!is.finite(S))) return(diag(nrow(S)))    # degenerate -> identity prior
  S <- (S + t(S)) / 2
  e <- eigen(S, symmetric = TRUE)
  e$vectors %*% diag(pmax(e$values, eps), nrow(S)) %*% t(e$vectors)
}

# log multivariate normal density at grid rows, mean 0, covariance Sigma
.mvn_logdensity <- function(gridx, Sigma) {
  D <- ncol(gridx)
  R <- chol(Sigma)                                   # upper triangular
  Si <- chol2inv(R)
  logdet <- 2 * sum(log(diag(R)))
  quad <- rowSums((gridx %*% Si) * gridx)
  -0.5 * (D * log(2 * pi) + logdet + quad)
}

# multivariate normal density at grid rows, mean 0, covariance Sigma
.mvn_density <- function(gridx, Sigma) exp(.mvn_logdensity(gridx, Sigma))

# Discrete prior MASS at the grid rows: the density renormalized to sum to one.
# The quadrature weights have to be probability mass, not density: summing a
# density over a grid of spacing h gives ~h^-D, which would offset every reported
# marginal log-likelihood by n*D*log(1/h) and make deviance / AIC / BIC
# incomparable across dimensionalities, node settings and the grid engine. It is
# also what keeps the reported log-likelihood a genuine log-probability (<= 0)
# when Sigma approaches singularity and the density blows up like 1/sqrt(det).
# Computed on the log scale so a near-singular Sigma cannot over- or underflow.
# Posterior quantities are invariant to this rescaling, so parameter estimates,
# EAPs and expected counts are unchanged.
.mvn_grid_mass <- function(gridx, Sigma) {
  ld <- .mvn_logdensity(gridx, Sigma)
  ld <- ld - max(ld)
  w <- exp(ld)
  s <- sum(w)
  if (!is.finite(s) || s <= 0) return(rep(1 / nrow(gridx), nrow(gridx)))
  w / s
}

# Largest absolute off-diagonal correlation of a covariance / correlation matrix.
.max_abs_offdiag_cor <- function(S) {
  if (is.null(S) || nrow(S) < 2L) return(0)
  R <- tryCatch(stats::cov2cor(S), error = function(e) NULL)
  if (is.null(R) || any(!is.finite(R))) return(1)
  max(abs(R[upper.tri(R)]))
}

# Warn when the latent correlations have been driven to the boundary. This is
# usually a substantive finding -- the dimensions are not separable in this data
# set and the model has degenerated to a lower-dimensional one -- but it also
# means the fixed quadrature grid can no longer resolve the ridge, so the
# information criteria and EAP reliabilities deserve caution.
.warn_boundary_correlation <- function(Sigma_out, threshold = 0.999) {
  Ss <- if (is.list(Sigma_out)) Sigma_out else list(Sigma_out)
  rmax <- suppressWarnings(max(vapply(Ss, .max_abs_offdiag_cor, numeric(1))))
  if (!is.finite(rmax) || rmax < threshold) return(invisible(FALSE))
  irtc_warn(code = "W427",
    en = paste0("The estimated latent correlation reached the boundary (max |r| = ",
      format(round(rmax, 4)), "); the dimensions are not separable in these data ",
      "and the model has degenerated to a lower-dimensional one."),
    zh = paste0("\u4f30\u8ba1\u5f97\u5230\u7684\u7ef4\u5ea6\u95f4\u6f5c\u5728\u76f8\u5173\u5df2\u8fbe\u5230\u8fb9\u754c\uff08\u6700\u5927 |r| = ",
      format(round(rmax, 4)), "\uff09\uff0c\u8bf4\u660e\u5728\u672c\u6570\u636e\u4e0a\u5404\u7ef4\u5ea6\u65e0\u6cd5\u533a\u5206\uff0c",
      "\u6a21\u578b\u5df2\u9000\u5316\u4e3a\u66f4\u4f4e\u7ef4\u7684\u7ed3\u6784\u3002"),
    fix_en = paste0("Treat this as evidence for a lower-dimensional model: refit with ",
      "fewer dimensions and compare. Information criteria and EAP reliabilities from ",
      "the degenerate fit are computed on a grid that can no longer resolve the ",
      "collapsed covariance, so read them with care."),
    fix_zh = paste0("\u5efa\u8bae\u5c06\u6b64\u89c6\u4e3a\u9700\u8981\u964d\u7ef4\u7684\u8bc1\u636e\uff1a\u6539\u7528\u66f4\u5c11\u7684\u7ef4\u5ea6\u91cd\u65b0\u4f30\u8ba1\u5e76\u6bd4\u8f83\u3002",
      "\u9000\u5316\u89e3\u4e0b\u7684\u4fe1\u606f\u51c6\u5219\u4e0e EAP \u4fe1\u5ea6\u662f\u5728\u5df2\u65e0\u6cd5\u5206\u8fa8\u584c\u9677\u534f\u65b9\u5dee\u7684\u7f51\u683c\u4e0a\u7b97\u51fa\u7684\uff0c\u8bf7\u8c28\u614e\u89e3\u8bfb\u3002"),
    class = "irtc_warning_estimation", data = list(max_abs_cor = rmax))
  invisible(TRUE)
}

# pack / unpack (a, b, Sigma) <-> parameter vector
.pack <- function(a, b, Sigma) {
  D <- ncol(Sigma)
  c(a, as.vector(b), Sigma[upper.tri(Sigma, diag = TRUE)])
}
.unpack <- function(par, I, maxK, D) {
  a <- par[1:I]
  nb <- I * (maxK - 1)
  b <- matrix(par[(I + 1):(I + nb)], I, maxK - 1)
  vs <- par[(I + nb + 1):length(par)]
  Sigma <- matrix(0, D, D)
  Sigma[upper.tri(Sigma, diag = TRUE)] <- vs
  Sigma[lower.tri(Sigma)] <- t(Sigma)[lower.tri(Sigma)]
  list(a = a, b = b, Sigma = Sigma)
}

# one SQUAREM acceleration step; emf(par) -> list(par=, deviance=)
.squarem_step <- function(par, emf) {
  r1 <- emf(par);  p1 <- r1$par
  r2 <- emf(p1);   p2 <- r2$par
  rr <- p1 - par;  vv <- (p2 - p1) - rr
  sv <- sum(vv^2)
  if (!is.finite(sv) || sv < 1e-12) return(r2)
  alpha <- -sqrt(sum(rr^2) / sv)
  if (alpha > -1) alpha <- -1                      # steplength stabilization
  pnew <- par - 2 * alpha * rr + alpha^2 * vv
  rn <- tryCatch(emf(pnew), error = function(e) NULL)
  if (is.null(rn) || !all(is.finite(rn$par)) || rn$deviance > r2$deviance) return(r2)
  rn
}

irtc_mml_fast_proto <- function(resp, dim_of, maxK = 2L, Q = 21L,
        nodes = seq(-5, 5, length.out = Q),
        n_threads = 2L, maxiter = 50L, conv = 1e-3,
        squarem = TRUE, adaptive = FALSE, adaptive_threshold = 1e-6,
        fast = FALSE, mass_budget = 1e-3, burnin = 3L,
        want_eap = FALSE, reg = NULL, Y = NULL, group = NULL, pweights = NULL,
        group_structure = c("full", "mean"), verbose = FALSE) {
  group_structure <- match.arg(group_structure)
  n_threads <- max(1L, min(as.integer(n_threads)[1L], 2L))
  rg <- list(slope_penalty = 0, slope_max = Inf, sigma_shrink = 0, sigma_shrink_pooled = 0)
  if (!is.null(reg)) rg[names(reg)] <- reg
  reg_active <- (rg$slope_penalty > 0) || is.finite(rg$slope_max) ||
                (rg$sigma_shrink > 0) || (rg$sigma_shrink_pooled > 0)
  storage.mode(resp) <- "integer"
  N <- nrow(resp); I <- ncol(resp); D <- max(dim_of)
  x <- nodes; Q <- length(x)
  gridcoord <- as.matrix(do.call(expand.grid, rep(list(0:(Q - 1L)), D)))
  storage.mode(gridcoord) <- "integer"
  gridx <- matrix(x[gridcoord + 1L], nrow(gridcoord), D)
  dimj0 <- as.integer(dim_of - 1L)

  #--- weights, groups (SP5.2)
  wprep <- irtc_proto_prep_weights(pweights, N); w <- wprep$w; n_eff <- wprep$n_eff
  group0 <- if (is.null(group)) integer(N) else as.integer(as.factor(group)) - 1L
  G <- length(unique(group0))
  beta <- if (is.null(Y)) NULL else matrix(0, ncol(Y), D)
  general <- (G > 1) || !is.null(Y)
  Sigma_list <- replicate(G, diag(D), simplify = FALSE)
  gmean <- matrix(0, G, D)

  a <- rep(1, I)
  b <- matrix(rep(if (maxK == 2) 0 else seq(-1, 1, length.out = maxK - 1), each = I),
              I, maxK - 1)
  Sigma <- diag(D)
  it_em <- 0L; postocc <- NULL                         # SP5.3 calibrated-pruning state
  nodes_full <- nrow(gridcoord); nodes_kept <- nodes_full; keep_final <- seq_len(nodes_full)

  em_update <- function(par) {
    z <- .unpack(par, I, maxK, D); a <- z$a; b <- z$b; Sigma1 <- z$Sigma
    if (!is.null(Y))     mu <- Y %*% beta
    else if (G > 1)      mu <- gmean[group0 + 1L, , drop = FALSE]
    else                 mu <- matrix(0, N, D)
    patt <- irtc_proto_build_patterns(mu, group0); npat <- nrow(patt$mu)
    Sig_of <- function(k) if (general) Sigma_list[[patt$group[k] + 1L]] else Sigma1
    probs <- numeric(I * maxK * Q)
    for (j in 1:I) {
      Pj <- irtc_proto_item_probs(a[j], b[j, ], x, maxK)
      for (cc in 1:maxK) probs[((j - 1) * maxK + (cc - 1)) * Q + 1:Q] <- Pj[, cc]
    }
    gw_full <- vapply(seq_len(npat),
                      function(k) .mvn_grid_mass(sweep(gridx, 2, patt$mu[k, ]), Sig_of(k)),
                      numeric(nrow(gridx)))
    gw_full <- matrix(gw_full, ncol = npat)
    if (fast && it_em > burnin) {                      # calibrated mass-budget pruning
      if (is.null(postocc)) {                          # establish posterior occupancy once
        Eo <- irtc_rcpp_proto_estep(resp, dimj0, probs, gridcoord, gw_full,
                as.integer(patt$pattern), w, group0, as.integer(G), x,
                as.integer(Q), as.integer(maxK), as.integer(n_threads), 0L, 1L)
        postocc <<- Eo$nodeocc
      }
      pc <- tabulate(patt$pattern + 1L, npat)
      keep <- irtc_calibrate_keep(gw_full, pc, postocc, mass_budget)
    } else if (adaptive && !fast) {                    # legacy threshold pruning
      keep <- which(gw_full[, 1] >= adaptive_threshold * max(gw_full[, 1]))
    } else {
      keep <- seq_len(nrow(gridcoord))
    }
    nodes_kept <<- length(keep); keep_final <<- keep
    gc_use <- gridcoord[keep, , drop = FALSE]
    gw_mat <- gw_full[keep, , drop = FALSE]
    want <- if (general) 1L else 0L
    E <- irtc_rcpp_proto_estep(resp, dimj0, probs, gc_use, gw_mat,
                               as.integer(patt$pattern), w, group0, as.integer(G), x,
                               as.integer(Q), as.integer(maxK), as.integer(n_threads), want)
    nik <- array(E$nik, c(Q, maxK, I))
    for (j in 1:I) {
      m <- irtc_proto_mstep_item(a[j], b[j, ], t(nik[, , j]), x, maxK,
                                 slope_penalty = rg$slope_penalty, slope_max = rg$slope_max)
      a[j] <- m$a; b[j, ] <- m$bvec
    }
    Mg_list <- lapply(seq_len(G), function(g) {
      Mg <- matrix(E$M2[((g - 1) * D * D + 1):(g * D * D)], D, D, byrow = TRUE)
      Mg[lower.tri(Mg)] <- t(Mg)[lower.tri(Mg)]; Mg
    })
    if (!general) {                                 # G==1, no Y: single Sigma in par
      Sigma1 <- stats::cov2cor(.nearest_pd(Mg_list[[1]] / sum(E$wsum)))
      if (rg$sigma_shrink > 0)
        Sigma1 <- (1 - rg$sigma_shrink) * Sigma1 + rg$sigma_shrink * diag(D)
      return(list(par = .pack(a, b, Sigma1), deviance = E$deviance))
    }
    # general path: per-group mean / regression beta, per-group Sigma (full moments).
    # Identification: reference group (g=1) is anchored N(0, corr); others free.
    if (!is.null(Y)) beta <<- irtc_proto_gls_beta(Y, E$eap, w)
    else for (g in seq_len(G)) if (g > 1L) {
      idx <- which(group0 == (g - 1L))
      gmean[g, ] <<- colSums(w[idx] * E$eap[idx, , drop = FALSE]) / E$wsum[g]
    }
    Slist <- lapply(seq_len(G), function(g) {
      if (!is.null(Y)) {
        idx <- which(group0 == (g - 1L))
        sb <- crossprod(Y[idx, , drop = FALSE], w[idx] * E$eap[idx, , drop = FALSE])
        (Mg_list[[g]] - crossprod(sb, beta)) / E$wsum[g]
      } else {
        Mg_list[[g]] / E$wsum[g] - outer(gmean[g, ], gmean[g, ])
      }
    })
    if (group_structure == "mean") {                # shared Sigma across groups
      Sp <- Reduce(`+`, Map(function(S, g) S * E$wsum[g], Slist, seq_len(G))) / sum(E$wsum)
      Slist <- replicate(G, Sp, simplify = FALSE)
    }
    if (rg$sigma_shrink_pooled > 0) {               # Layer B: shrink toward pooled
      Sp <- Reduce(`+`, Map(function(S, g) S * E$wsum[g], Slist, seq_len(G))) / sum(E$wsum)
      s <- rg$sigma_shrink_pooled
      Slist <- lapply(Slist, function(S) (1 - s) * S + s * Sp)
    }
    anchor <- !is.null(Y) || group_structure == "mean"   # cov2cor all if regression/shared
    Sigma_list <<- lapply(seq_len(G), function(g) {
      if (g == 1L || anchor) stats::cov2cor(.nearest_pd(Slist[[g]]))  # reference: unit var
      else .nearest_pd(Slist[[g]])                                    # other groups: free var
    })
    list(par = .pack(a, b, Sigma_list[[1]]), deviance = E$deviance)
  }

  use_sq <- squarem && !general                    # group means / beta are EM state -> plain EM
  par <- .pack(a, b, Sigma); dev_old <- Inf; it <- 0L
  for (iter in 1:maxiter) {
    it <- iter; it_em <- iter                        # SP5.3: drives burn-in vs prune
    res <- if (use_sq) .squarem_step(par, em_update) else em_update(par)
    par <- res$par; dev <- res$deviance
    if (verbose) cat(sprintf("iter %d  dev=%.3f\n", iter, dev))
    if (is.finite(dev_old) && abs(dev_old - dev) < conv) break
    dev_old <- dev
  }
  z <- .unpack(par, I, maxK, D)
  eap <- NULL; eap_sd <- NULL; EAP.rel <- NULL
  if (want_eap) {
    a <- z$a; b <- z$b; Sigma <- z$Sigma
    if (!is.null(Y))     mu <- Y %*% beta
    else if (G > 1)      mu <- gmean[group0 + 1L, , drop = FALSE]
    else                 mu <- matrix(0, N, D)
    patt <- irtc_proto_build_patterns(mu, group0); npat <- nrow(patt$mu)
    Sig_of <- function(k) if (general) Sigma_list[[patt$group[k] + 1L]] else Sigma
    gw_mat <- vapply(seq_len(npat),
                     function(k) .mvn_grid_mass(sweep(gridx, 2, patt$mu[k, ]), Sig_of(k)),
                     numeric(nrow(gridx)))
    gw_mat <- matrix(gw_mat, ncol = npat)
    probs <- numeric(I * maxK * Q)
    for (j in 1:I) {
      Pj <- irtc_proto_item_probs(a[j], b[j, ], x, maxK)
      for (cc in 1:maxK) probs[((j - 1) * maxK + (cc - 1)) * Q + 1:Q] <- Pj[, cc]
    }
    Ef <- irtc_rcpp_proto_estep(resp, dimj0, probs, gridcoord, gw_mat,
                                as.integer(patt$pattern), w, group0, as.integer(G), x,
                                as.integer(Q), as.integer(maxK),
                                as.integer(n_threads), want_eap = 1L)
    eap <- Ef$eap
    eap_sd <- Ef$eapsd
    # Same definition as the grid engine (irtc_mml_person_EAP_rel): the case-weighted
    # ratio of true-score variance to total variance. The previous var(EAP)/diag(Sigma)
    # proxy ignored both the case weights and the posterior error variance.
    EAP.rel <- vapply(seq_len(D), function(d)
      irtc_mml_person_EAP_rel(eap[, d], eap_sd[, d], pweights = w), numeric(1))
    EAP.rel <- pmin(pmax(EAP.rel, 1e-3), 0.999)
  }
  Sigma_out <- if (G > 1) Sigma_list else if (general) Sigma_list[[1]] else z$Sigma
  .warn_boundary_correlation(Sigma_out)
  list(a = z$a, b = z$b, Sigma = Sigma_out, deviance = dev, iter = it,
       eap = eap, eap_sd = eap_sd, EAP.rel = EAP.rel, pweights = w,
       beta = beta, gmean = gmean, n_eff = n_eff,
       G = G, group_structure = group_structure,
       nodes_full = nodes_full, nodes_kept = nodes_kept, keep = keep_final,
       mass_budget = mass_budget, fast = fast, nodes = x,
       regularization = list(active = reg_active, slope_penalty = rg$slope_penalty,
                             slope_max = rg$slope_max, sigma_shrink = rg$sigma_shrink))
}
