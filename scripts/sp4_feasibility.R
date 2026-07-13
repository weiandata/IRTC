# Measure peak memory and per-iteration wall time of the streaming engine on
# 4-dim / 300-item GPCM data at increasing N, then extrapolate to N = 1e6.
# Run: Rscript tools/sp4_feasibility.R
suppressMessages(devtools::load_all(".", quiet = TRUE))
source("scripts/sp4_simulate.R")

measure <- function(N, adaptive = FALSE, Q = 15, iters = 3) {
  d <- sp4_simulate(N = N, I = 300, D = 4, maxK = 4, seed = 1)
  gc(reset = TRUE)
  t0 <- Sys.time()
  m <- irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 4, Q = Q, adaptive = adaptive,
                           adaptive_threshold = 1e-5, maxiter = iters, squarem = FALSE)
  sec_per_iter <- as.numeric(Sys.time() - t0, units = "secs") / iters
  g <- gc()
  peak_gb <- sum(g[, ncol(g)]) / 1024     # last column = "max used (Mb)"
  rm(d); gc()
  c(N = N, sec_per_iter = round(sec_per_iter, 2), peak_gb = round(peak_gb, 2))
}

cat(sprintf("cores: %d ;  grid nodes (Q=15, D=4): %d\n",
            parallel::detectCores(), 15^4))
cat("--- exact mode ---\n")
for (N in c(1e4, 5e4, 1e5)) print(measure(N, adaptive = FALSE, iters = 2))
cat("--- adaptive mode (thr=1e-5) ---\n")
for (N in c(1e4, 1e5)) print(measure(N, adaptive = TRUE, iters = 2))
