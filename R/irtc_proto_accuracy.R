# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## SP5.3: calibrated controlled-accuracy quadrature helpers.

# Keep-set calibrated to a mass budget eps. Importance combines normalized prior
# (per pattern) with normalized aggregate posterior occupancy (protects extreme
# responders' low-prior/high-likelihood nodes). Each pattern retains >= 1-eps of
# its combined mass; the union is returned (so small/special groups are not masked).
irtc_calibrate_keep <- function(gw, counts, postocc = NULL, eps = 1e-3) {
  gw <- as.matrix(gw); TP <- nrow(gw); npat <- ncol(gw)
  po <- if (is.null(postocc) || sum(postocc) <= 0) numeric(TP) else postocc / sum(postocc)
  keep <- logical(TP)
  for (k in seq_len(npat)) {
    imp <- gw[, k] / sum(gw[, k]) + po                 # prior(pattern k) + posterior
    ord <- order(imp)                                   # ascending: smallest first
    cum <- cumsum(imp[ord]) / sum(imp)
    drop_k <- ord[cum <= eps]                           # drop smallest mass up to eps
    kp <- rep(TRUE, TP); kp[drop_k] <- FALSE
    keep <- keep | kp                                   # union across patterns
  }
  which(keep)
}

# Stratified verification sample: ordinary, small groups, high-weight, extreme
# responders (near 0/perfect score), high-missingness. Fixed seed -> reproducible.
irtc_verify_sample <- function(resp, group = NULL, pweights = NULL, n = 3000, seed = 1) {
  set.seed(seed); N <- nrow(resp)
  score <- rowMeans(resp, na.rm = TRUE); miss <- rowMeans(is.na(resp))
  strata <- rep("ordinary", N)
  strata[score <= stats::quantile(score, 0.02, na.rm = TRUE)] <- "extreme_low"
  strata[score >= stats::quantile(score, 0.98, na.rm = TRUE)] <- "extreme_high"
  if (any(miss > 0)) strata[miss >= stats::quantile(miss[miss > 0], 0.9)] <- "high_missing"
  if (!is.null(group)) for (g in unique(group))
    if (sum(group == g) < 0.05 * N) strata[group == g] <- paste0("group_", g)
  if (!is.null(pweights)) strata[pweights >= stats::quantile(pweights, 0.99)] <- "high_weight"
  idx <- integer(0); us <- unique(strata)
  for (s in us) {
    si <- which(strata == s); take <- min(length(si), max(50, ceiling(n / length(us))))
    idx <- c(idx, sample(si, take))
  }
  list(idx = idx, strata = strata[idx])
}

# One E-step at fit's parameters on a (sub)sample, full grid or pruned by `keep`.
# Returns deviance, per-person EAP, per-person second moment (D x D), expected counts.
irtc_proto_estep_at <- function(resp, dim_of, fit, Q, maxK, keep = NULL) {
  storage.mode(resp) <- "integer"
  N <- nrow(resp); I <- ncol(resp); D <- max(dim_of)
  x <- if (!is.null(fit$nodes)) fit$nodes else seq(-5, 5, length.out = Q)
  gridcoord <- as.matrix(do.call(expand.grid, rep(list(0:(Q - 1L)), D)))
  storage.mode(gridcoord) <- "integer"
  gridx <- matrix(x[gridcoord + 1L], nrow(gridcoord), D)
  dimj0 <- as.integer(dim_of - 1L)
  Sig <- if (is.list(fit$Sigma)) fit$Sigma[[1]] else fit$Sigma
  gw <- .mvn_density(gridx, Sig)
  b <- if (is.matrix(fit$b)) fit$b else matrix(fit$b, I, maxK - 1)
  probs <- numeric(I * maxK * Q)
  for (j in 1:I) {
    Pj <- irtc_proto_item_probs(fit$a[j], b[j, ], x, maxK)
    for (cc in 1:maxK) probs[((j - 1) * maxK + (cc - 1)) * Q + 1:Q] <- Pj[, cc]
  }
  if (!is.null(keep)) { gc_use <- gridcoord[keep, , drop = FALSE]; gwk <- gw[keep] }
  else                { gc_use <- gridcoord; gwk <- gw }
  E <- irtc_rcpp_proto_estep(resp, dimj0, probs, gc_use, matrix(gwk, ncol = 1),
         integer(N), rep(1, N), integer(N), 1L, x,
         as.integer(Q), as.integer(maxK), 1L, 1L)
  list(dev = E$deviance, eap = E$eap, M2 = E$M2 / sum(E$wsum), nik = E$nik)
}

# Parameter change from one shared M-step under full vs pruned expected counts.
irtc_mstep_delta <- function(nik_full, nik_pruned, fit, maxK) {
  I <- length(fit$a); x <- fit$nodes; Q <- length(x)
  af <- array(nik_full, c(Q, maxK, I)); ap <- array(nik_pruned, c(Q, maxK, I))
  b <- if (is.matrix(fit$b)) fit$b else matrix(fit$b, I, maxK - 1)
  d <- numeric(0)
  for (j in 1:I) {
    mf <- irtc_proto_mstep_item(fit$a[j], b[j, ], t(af[, , j]), x, maxK)
    mp <- irtc_proto_mstep_item(fit$a[j], b[j, ], t(ap[, , j]), x, maxK)
    d <- c(d, abs(mf$a - mp$a), abs(mf$bvec - mp$bvec))
  }
  d
}

# Stratified, fixed-seed verified-error report: full vs pruned grid at final
# parameters; per-metric quantiles; met = all p95 within their tolerances.
irtc_proto_verify <- function(resp, dim_of, fit, Q, maxK, group = NULL, pweights = NULL,
                              verify_n = 3000, verify_seed = 1, tol = list()) {
  tol <- utils::modifyList(list(deviance = 1e-3, eap = 1e-2, moment = 1e-2, par = 1e-2), tol)
  s <- irtc_verify_sample(resp, group, pweights, verify_n, verify_seed)
  rr <- resp[s$idx, , drop = FALSE]
  ef <- irtc_proto_estep_at(rr, dim_of, fit, Q, maxK, keep = NULL)         # full grid
  ep <- irtc_proto_estep_at(rr, dim_of, fit, Q, maxK, keep = fit$keep)     # pruned grid
  qq <- function(v) stats::setNames(as.numeric(stats::quantile(abs(v), c(.5, .95, 1))),
                                    c("median", "p95", "max"))
  out <- list(
    checked_n = length(s$idx), verify_seed = verify_seed, strata = unique(s$strata),
    deviance_rel = qq((ep$dev - ef$dev) / max(abs(ef$dev), 1e-8)),
    eap_abs      = qq(ep$eap - ef$eap),
    moment_abs   = qq(ep$M2 - ef$M2),
    par_change   = qq(irtc_mstep_delta(ef$nik, ep$nik, fit, maxK)),
    prior_mass_dropped = 1 - fit$nodes_kept / fit$nodes_full,
    nodes_full = fit$nodes_full, nodes_kept = fit$nodes_kept, tol = tol)
  out$met <- unname(out$deviance_rel["p95"] <= tol$deviance &&
                    out$eap_abs["p95"] <= tol$eap &&
                    out$moment_abs["p95"] <= tol$moment &&
                    out$par_change["p95"] <= tol$par)
  if (!out$met)
    warning("accuracy verification did not meet tolerance; see accuracy_report.", call. = FALSE)
  if (fit$nodes_kept / fit$nodes_full > 0.7)
    message("fast mode kept >70% of nodes; speed benefit is limited.")
  out
}
