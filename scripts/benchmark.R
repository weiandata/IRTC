# Reproducible benchmark for the multidim 2PL EM hotpath.
suppressMessages(devtools::load_all(".", quiet = TRUE))
load("data/data.sim.rasch.rda")
set.seed(1)
resp <- data.sim.rasch[sample(seq_len(nrow(data.sim.rasch)), 2000), 1:30]
Q <- matrix(0, 30, 3); for (i in 1:30) Q[i, ((i - 1) %% 3) + 1] <- 1
ctrl <- function(nt, fast = FALSE) list(nodes = seq(-5, 5, len = 15),
                                        n_threads = nt, fast = fast)
bench <- function(nt, fast = FALSE) {
  t0 <- Sys.time()
  m <- irtc.mml.2pl(resp = resp, irtmodel = "2PL", Q = Q,
                    control = ctrl(nt, fast), verbose = FALSE)
  as.numeric(Sys.time() - t0, units = "secs")
}
cat(sprintf("cores detected: %d\n", parallel::detectCores()))
cat(sprintf("exact  1 thread : %.2f s\n", bench(1)))
cat(sprintf("exact  4 threads: %.2f s\n", bench(4)))
cat(sprintf("exact  allcores : %.2f s\n", bench(parallel::detectCores())))
cat(sprintf("fast   allcores : %.2f s\n", bench(parallel::detectCores(), fast = TRUE)))
