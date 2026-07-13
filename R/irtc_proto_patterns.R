# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## SP5.2 helpers: case-weight prep, unique (mu, group) pattern building, GLS beta.

# Validate & normalize case weights; return list(w, n_eff).
irtc_proto_prep_weights <- function(pweights, N) {
  if (is.null(pweights)) return(list(w = rep(1, N), n_eff = N))
  if (length(pweights) != N || any(!is.finite(pweights)) || any(pweights < 0) ||
      sum(pweights) <= 0)
    stop("pweights must be non-negative, finite, length N, not all zero.", call. = FALSE)
  w <- pweights * N / sum(pweights)                 # normalize to sum = N
  n_eff <- sum(w)^2 / sum(w^2)                       # Kish effective sample size
  if (max(w) / mean(w) > 50) warning("extreme case weights (max/mean > 50).", call. = FALSE)
  list(w = w, n_eff = n_eff)
}

# Build unique (mu, group) patterns. mu = N x D person means; group 0-based.
# Returns pattern (0-based length N) + the unique mu rows and groups.
irtc_proto_build_patterns <- function(mu, group, tol = 1e-8) {
  key <- paste(do.call(paste, c(as.data.frame(round(mu / tol) * tol), sep = "_")),
               group, sep = "|")
  u <- which(!duplicated(key))
  pat <- match(key, key[u]) - 1L                     # 0-based pattern index
  list(pattern = pat, mu = mu[u, , drop = FALSE], group = group[u])
}

# Weighted GLS of E[theta] (N x D) on Y (N x P) via QR; warns on rank deficiency.
irtc_proto_gls_beta <- function(Y, Etheta, w) {
  sw <- sqrt(w)
  qrY <- qr(sw * Y)
  if (qrY$rank < ncol(Y)) {
    aliased <- setdiff(seq_len(ncol(Y)), qrY$pivot[seq_len(qrY$rank)])
    warning(sprintf("collinear covariates (columns %s) are not identified.",
                    paste(aliased, collapse = ",")), call. = FALSE)
  }
  beta <- qr.coef(qrY, sw * Etheta)                  # P x D (NA rows for aliased cols)
  beta[is.na(beta)] <- 0
  matrix(beta, ncol = ncol(Etheta))
}
