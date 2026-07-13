# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

# Decide grid vs streaming by predicted wall time (NOT by memory).
# Returns list(engine, reason, predicted_mem_gb, predicted_speedup, fell_back).
irtc_route_decide <- function(method, N, I, D, Q, maxK, simple_structure,
                              has_covariates = FALSE, n_patterns = 1, mem_budget_gb = 6) {
  nnodes <- Q^D
  grid_mem_gb <- N * nnodes * 8 / 1024^3
  supported <- simple_structure && (D >= 1)        # covariates/groups/weights now supported
  if (method == "grid")
    return(list(engine = "grid", reason = "user: grid",
                predicted_mem_gb = grid_mem_gb, predicted_speedup = NA_real_,
                fell_back = FALSE))
  if (method == "streaming") {
    if (!supported)
      stop("method='streaming' unsupported for this model ",
           "(within-item / non-simple structure); use method='grid'.", call. = FALSE)
    return(list(engine = "streaming", reason = "user: streaming",
                predicted_mem_gb = grid_mem_gb, predicted_speedup = NA_real_,
                fell_back = FALSE))
  }
  # auto
  if (!supported)
    return(list(engine = "grid",
                reason = "unsupported model (within-item structure) -> grid",
                predicted_mem_gb = grid_mem_gb, predicted_speedup = NA_real_,
                fell_back = TRUE))
  # cost model (per iteration): streaming adds a per-pattern density term
  t_grid   <- N * I * nnodes
  t_stream <- N * I * Q + N * nnodes * D + n_patterns * nnodes * D
  speedup  <- t_grid / t_stream
  if (grid_mem_gb > mem_budget_gb)
    return(list(engine = "streaming", reason = "grid won't fit memory -> streaming",
                predicted_mem_gb = grid_mem_gb, predicted_speedup = speedup,
                fell_back = FALSE))
  if (speedup > 1.5)                       # margin: only switch when clearly faster
    return(list(engine = "streaming",
                reason = sprintf("streaming faster (pred %.1fx)", speedup),
                predicted_mem_gb = grid_mem_gb, predicted_speedup = speedup,
                fell_back = FALSE))
  list(engine = "grid", reason = sprintf("grid as fast (pred speedup %.2fx)", speedup),
       predicted_mem_gb = grid_mem_gb, predicted_speedup = speedup, fell_back = FALSE)
}
