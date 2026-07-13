# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## Map the streaming-engine output (a, b, Sigma, eap) to an `irtc` object whose
## fields the existing S3 methods (summary/print/logLik/anova.irtc) consume.

# Build the irtc object. z = list(a,b,Sigma,deviance,iter,eap,EAP.rel); dim_of,
# maxK, resp, CALL supplied by the caller. (between-item structure)
irtc_proto_build_object <- function(z, dim_of, maxK, resp, CALL = NULL,
                                    irtmodel = "2PL", control = list(snodes = 0)) {
  I <- ncol(resp); N <- nrow(resp); D <- max(dim_of)
  a <- z$a; b <- z$b; Sigma <- z$Sigma

  # B slope array [I, maxK, D]: B[j,k,dim] = (k-1)*a_j (GPCM scoring; 2PL: k=2 -> a_j)
  B <- array(0, dim = c(I, maxK, D))
  for (j in 1:I) for (k in 1:maxK) B[j, k, dim_of[j]] <- (k - 1) * a[j]

  # xsi intercepts: per item per step. xsi_{j,k} = a_j * cumsum(b_j)[k]  (k=1..maxK-1)
  xsi_vec <- c(); xsi_names <- c()
  for (j in 1:I) {
    cb <- cumsum(b[j, ])
    for (k in seq_len(maxK - 1)) {
      xsi_vec <- c(xsi_vec, a[j] * cb[k]); xsi_names <- c(xsi_names, paste0("I", j, "_Cat", k))
    }
  }
  xsi <- data.frame(xsi = xsi_vec, se.xsi = NA_real_, row.names = xsi_names)

  # information criteria
  npar_item <- I * (1 + (maxK - 1))          # slope + (maxK-1) thresholds per item
  npar_cov  <- D * (D - 1) / 2               # correlations (unit variances fixed)
  Npars <- npar_item + npar_cov
  dev <- z$deviance; loglike <- -dev / 2
  ic <- list(n = N, deviance = dev, loglike = loglike, logprior = 0, logpost = loglike,
             Nparsxsi = I * (maxK - 1), NparsB = I, Nparsbeta = 0, Nparscov = npar_cov,
             np = Npars, Npars = Npars,
             AIC = dev + 2 * Npars, AIC3 = dev + 3 * Npars,
             BIC = dev + log(N) * Npars, aBIC = dev + log((N + 2) / 24) * Npars,
             CAIC = dev + (log(N) + 1) * Npars, AICc = dev + 2 * Npars +
               2 * Npars * (Npars + 1) / (N - Npars - 1), GHP = NA)

  # item summary table
  item <- data.frame(item = paste0("I", 1:I), N = colSums(!is.na(resp)),
                     M = colMeans(resp, na.rm = TRUE), slope = a)

  # person (EAP) table
  eap <- z$eap; if (is.null(eap)) eap <- matrix(NA_real_, N, D)
  person <- data.frame(pid = seq_len(N), case = seq_len(N), pweight = 1,
                       score = rowSums(resp, na.rm = TRUE), max = rowSums(!is.na(resp)))
  for (d in 1:D) person[[paste0("EAP.Dim", d)]] <- eap[, d]
  EAP.rel <- z$EAP.rel; if (is.null(EAP.rel)) EAP.rel <- rep(NA_real_, D)

  res <- list(xsi = xsi, beta = matrix(0, 1, D), variance = Sigma, item = item,
              item_irt = NULL, person = person, EAP.rel = EAP.rel,
              A = NULL, B = B, AXsi = NULL, nitems = I, maxK = maxK, nstud = N,
              ndim = D, deviance = dev, ic = ic, control = control,
              irtmodel = irtmodel, iter = z$iter, printxsi = FALSE, G = 1L,
              groups = 1L, formulaA = NULL, CALL = CALL, nnodes = NA, YSD = FALSE)
  class(res) <- "irtc"
  res
}

# Convenience: run the engine and build the object.
irtc_proto_run_and_build <- function(resp, dim_of, maxK = 2L, Q = 21L,
        nodes = seq(-6, 6, length.out = Q), irtmodel = "2PL", n_threads = 2L,
        maxiter = 80L, conv = 1e-4, squarem = TRUE, adaptive = FALSE,
        adaptive_threshold = 1e-6, reg = NULL, Y = NULL, group = NULL, pweights = NULL,
        group_structure = "full", fast = FALSE, mass_budget = 1e-3, burnin = 3L,
        verify = "stratified", verify_n = 3000, verify_seed = 1, refine = FALSE,
        tol = list(), CALL = NULL, control = list(snodes = 0)) {
  n_threads <- max(1L, min(as.integer(n_threads)[1L], 2L))
  run_fit <- function(mb)
    irtc_mml_fast_proto(resp, dim_of, maxK = maxK, Q = Q, nodes = nodes,
        n_threads = n_threads, maxiter = maxiter, conv = conv, squarem = squarem,
        adaptive = adaptive, adaptive_threshold = adaptive_threshold,
        fast = fast, mass_budget = mb, burnin = burnin,
        reg = reg, Y = Y, group = group, pweights = pweights,
        group_structure = group_structure, want_eap = TRUE)
  z <- run_fit(mass_budget)
  report <- NULL
  if (fast && !isFALSE(verify)) {
    report <- irtc_proto_verify(resp, dim_of, z, Q = Q, maxK = maxK, group = group,
                pweights = pweights, verify_n = verify_n, verify_seed = verify_seed, tol = tol)
    tries <- 0L
    while (isTRUE(refine) && !report$met && tries < 3L) {   # refine = re-FIT with tighter budget
      mass_budget <- mass_budget / 4; tries <- tries + 1L
      z <- run_fit(mass_budget)
      report <- irtc_proto_verify(resp, dim_of, z, Q = Q, maxK = maxK, group = group,
                  pweights = pweights, verify_n = verify_n, verify_seed = verify_seed, tol = tol)
    }
  }
  obj <- irtc_proto_build_object(z, dim_of, maxK, resp, CALL = CALL,
                                 irtmodel = irtmodel, control = control)
  obj$a <- z$a                                  # keep engine-natural slopes for checks
  obj$regularization <- z$regularization
  obj$beta <- z$beta; obj$n_eff <- z$n_eff
  obj$gmean <- z$gmean; obj$G <- z$G
  obj$accuracy_report <- report
  obj
}
