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

# multivariate normal density at grid rows, mean 0, covariance Sigma
.mvn_density <- function(gridx, Sigma) {
  D <- ncol(gridx)
  R <- chol(Sigma)                                   # upper triangular
  Si <- chol2inv(R)
  logdet <- 2 * sum(log(diag(R)))
  quad <- rowSums((gridx %*% Si) * gridx)
  exp(-0.5 * (D * log(2 * pi) + logdet + quad))
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
                      function(k) .mvn_density(sweep(gridx, 2, patt$mu[k, ]), Sig_of(k)),
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
  eap <- NULL; EAP.rel <- NULL
  if (want_eap) {
    a <- z$a; b <- z$b; Sigma <- z$Sigma
    if (!is.null(Y))     mu <- Y %*% beta
    else if (G > 1)      mu <- gmean[group0 + 1L, , drop = FALSE]
    else                 mu <- matrix(0, N, D)
    patt <- irtc_proto_build_patterns(mu, group0); npat <- nrow(patt$mu)
    Sig_of <- function(k) if (general) Sigma_list[[patt$group[k] + 1L]] else Sigma
    gw_mat <- vapply(seq_len(npat),
                     function(k) .mvn_density(sweep(gridx, 2, patt$mu[k, ]), Sig_of(k)),
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
    EAP.rel <- pmin(pmax(apply(eap, 2, stats::var) / diag(Sigma), 1e-3), 0.999)
  }
  Sigma_out <- if (G > 1) Sigma_list else if (general) Sigma_list[[1]] else z$Sigma
  list(a = z$a, b = z$b, Sigma = Sigma_out, deviance = dev, iter = it,
       eap = eap, EAP.rel = EAP.rel, beta = beta, gmean = gmean, n_eff = n_eff,
       G = G, group_structure = group_structure,
       nodes_full = nodes_full, nodes_kept = nodes_kept, keep = keep_final,
       mass_budget = mass_budget, fast = fast, nodes = x,
       regularization = list(active = reg_active, slope_penalty = rg$slope_penalty,
                             slope_max = rg$slope_max, sigma_shrink = rg$sigma_shrink))
}
