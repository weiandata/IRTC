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

# Guard the grid path against an allocation that cannot succeed. The grid engine
# materialises an N x nodes^D posterior matrix and keeps a few same-sized working
# copies alive, so a large multidimensional model walks into R's
# "vector memory limit ... reached" -- an error that says nothing about what to do
# instead. Predict the allocation first and stop with an actionable message.
# (method="auto" already routes such models to the streaming engine; this guard
# is what catches an explicit method="grid".)
irtc_grid_memory_guard <- function(N, nnodes, D, streaming_possible=FALSE,
    budget_gb=NULL, copies=3)
{
    if (!is.finite(N) || !is.finite(nnodes) || N <= 0 || nnodes <= 0) {
        return(invisible(NULL))
    }
    posterior_gb <- N * nnodes * 8 / 1024^3
    need_gb <- copies * posterior_gb
    if (is.null(budget_gb)) {
        budget_gb <- irtc_memory_budget_gb()
    }
    if (need_gb <= budget_gb) {
        return(invisible(NULL))
    }
    fix_en <- if (streaming_possible) {
        paste0("Use method=\"streaming\", which keeps memory bounded for ",
            "between-item (simple-structure) multidimensional models, or ",
            "reduce the number of quadrature nodes via ",
            "control=list(nodes=seq(-6, 6, length.out=15)).")
    } else {
        paste0("Reduce the number of quadrature nodes via ",
            "control=list(nodes=seq(-6, 6, length.out=15)), reduce the number ",
            "of dimensions, or raise the limit with mem.maxVSize().")
    }
    fix_zh <- if (streaming_possible) {
        "\u8bf7\u6539\u7528 method=\"streaming\"\uff08\u9898\u95f4\u7ef4\u5ea6\u7684\u7b80\u5355\u7ed3\u6784\u6a21\u578b\u5728\u8be5\u5f15\u64ce\u4e0b\u5185\u5b58\u6709\u754c\uff09\uff0c\u6216\u901a\u8fc7 control=list(nodes=seq(-6, 6, length.out=15)) \u51cf\u5c11\u79ef\u5206\u8282\u70b9\u6570\u3002"
    } else {
        "\u8bf7\u901a\u8fc7 control=list(nodes=seq(-6, 6, length.out=15)) \u51cf\u5c11\u79ef\u5206\u8282\u70b9\u6570\u3001\u964d\u4f4e\u7ef4\u5ea6\u6570\uff0c\u6216\u7528 mem.maxVSize() \u63d0\u9ad8\u5185\u5b58\u4e0a\u9650\u3002"
    }
    irtc_stop(code="E409",
        en=paste0("The grid engine is predicted to need about ",
            format(round(need_gb, 1)), " GB (", N, " persons x ", nnodes,
            " quadrature nodes over ", D, " dimension(s), and the E-step holds ",
            "about ", copies, " matrices of that size), above the ",
            format(round(budget_gb, 1)), " GB available to this session."),
        zh=paste0("\u7f51\u683c\u6cd5\u9884\u8ba1\u9700\u8981\u7ea6 ", format(round(need_gb, 1)), " GB \u5185\u5b58\uff08",
            N, " \u4e2a\u6837\u672c \u00d7 ", nnodes, " \u4e2a\u79ef\u5206\u8282\u70b9\uff0c\u5171 ", D, " \u4e2a\u7ef4\u5ea6\uff0cE \u6b65\u9700\u8981\u7ea6 ", copies, " \u4efd\u540c\u7b49\u5927\u5c0f\u7684\u77e9\u9635\uff09\uff0c\u8d85\u8fc7\u4e86\u5f53\u524d\u4f1a\u8bdd\u53ef\u7528\u7684 ",
            format(round(budget_gb, 1)), " GB\u3002"),
        fix_en=fix_en, fix_zh=fix_zh,
        class="irtc_error_estimation",
        data=list(required_gb=need_gb, posterior_gb=posterior_gb,
            budget_gb=budget_gb, streaming_possible=streaming_possible))
}

# Memory this session may spend on the posterior matrix. mem.maxVSize() reports
# R's vector memory limit in MB (Inf when unlimited); fall back to a conservative
# default when there is no limit to read.
irtc_memory_budget_gb <- function(default_gb=8)
{
    limit_mb <- tryCatch(mem.maxVSize(), error=function(e) NA_real_)
    if (!is.finite(limit_mb) || limit_mb <= 0) {
        return(default_gb)
    }
    limit_mb / 1024
}
