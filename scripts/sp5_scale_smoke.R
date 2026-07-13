suppressMessages(devtools::load_all(".", quiet = TRUE))
source("scripts/sp4_simulate.R")
d <- sp4_simulate(N = 50000, I = 60, D = 3, maxK = 4, seed = 1)
Q <- matrix(0, 60, 3); for (j in 1:60) Q[j, d$dim_of[j]] <- 1
gc(reset = TRUE); t0 <- Sys.time()
m <- irtc.mml.2pl(resp = d$resp, irtmodel = "GPCM", Q = Q, verbose = FALSE)
g <- gc()
cat("engine:", m$routing$engine, "| reason:", m$routing$reason,
    "| time:", round(as.numeric(Sys.time() - t0, units = "secs"), 1),
    "s | peak GB:", round(sum(g[, ncol(g)]) / 1024, 2), "\n")
stopifnot(m$routing$engine == "streaming", inherits(m, "irtc"))
cat("SCALE SMOKE OK\n")
