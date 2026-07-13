# =============================================================================
# gen_data.R -- Generate IRTC's bundled example datasets by simulation.
#
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# (惟安数据科技（北京）有限公司)
#
# These datasets are simulated from scratch by IRTC for use in examples and
# tests. They are original, independently generated data and are NOT derived
# from any third-party package. Re-run this script to reproduce them exactly:
#
#   Rscript scripts/gen_data.R
#
# Produces (overwrites) under data/:
#   data.sim.rasch  2000 x 40 binary matrix           (Rasch)
#   data.gpcm        392 x  3 polytomous data.frame    (partial credit, 0..3)
#   data.mc          list(raw, scored), 143 x 30       (multiple choice)
# =============================================================================

dir.create("data", showWarnings = FALSE)

# ---- 1. data.sim.rasch : 2000 persons x 40 dichotomous items ----------------
set.seed(20260713L)
n_p   <- 2000L
n_i   <- 40L
theta <- rnorm(n_p, mean = 0, sd = 1)
b     <- seq(-2.2, 2.2, length.out = n_i)              # item difficulties
prob  <- plogis(outer(theta, b, "-"))                  # P(x = 1)
data.sim.rasch <- matrix(rbinom(n_p * n_i, 1L, prob),
                         nrow = n_p, ncol = n_i)
colnames(data.sim.rasch) <- paste0("I", seq_len(n_i))
save(data.sim.rasch, file = "data/data.sim.rasch.rda", compress = "xz")

# ---- 2. data.gpcm : 392 persons x 3 polytomous items (categories 0..3) ------
# Simulated from a partial credit model (PCM) with 3 steps per item.
set.seed(20260714L)
n_p   <- 392L
items <- c("Comfort", "Work", "Benefit")
# per-item step difficulties (3 thresholds -> 4 ordered categories 0..3)
thr   <- list(Comfort = c(-1.4, -0.2, 1.1),
              Work    = c(-1.0,  0.3, 1.5),
              Benefit = c(-1.8, -0.5, 0.9))
theta <- rnorm(n_p, mean = 0, sd = 1)
pcm_probs <- function(th, taus) {
  # cumulative category "score" 0..K; unnormalised log-prob of category k is
  # sum_{s<=k} (th - tau_s), with category 0 having value 0.
  num <- c(0, cumsum(th - taus))
  num <- num - max(num)
  exp(num) / sum(exp(num))
}
data.gpcm <- sapply(items, function(it) {
  taus <- thr[[it]]
  vapply(theta, function(th) {
    sample.int(length(taus) + 1L, size = 1L,
               prob = pcm_probs(th, taus)) - 1L
  }, integer(1))
})
data.gpcm <- as.data.frame(data.gpcm)
names(data.gpcm) <- items
save(data.gpcm, file = "data/data.gpcm.rda", compress = "xz")

# ---- 3. data.mc : 143 persons x 30 multiple-choice items --------------------
# Raw responses use options A-D (with a small fraction of omitted "9" codes);
# scored is the 0/1 correctness matrix under a Rasch model.
set.seed(20260715L)
n_p   <- 143L
n_i   <- 30L
opts  <- c("A", "B", "C", "D")
key   <- sample(opts, n_i, replace = TRUE)             # answer key per item
theta <- rnorm(n_p, mean = 0, sd = 1)
b     <- seq(-1.8, 1.8, length.out = n_i)
correct <- matrix(rbinom(n_p * n_i, 1L, plogis(outer(theta, b, "-"))),
                  nrow = n_p, ncol = n_i)
raw <- matrix("", nrow = n_p, ncol = n_i)
for (j in seq_len(n_i)) {
  wrong <- setdiff(opts, key[j])
  for (i in seq_len(n_p)) {
    if (correct[i, j] == 1L) {
      raw[i, j] <- key[j]
    } else if (runif(1) < 0.03) {
      raw[i, j] <- "9"                                 # omitted / not reached
    } else {
      raw[i, j] <- sample(wrong, 1L)
    }
  }
}
scored <- (raw == matrix(key, nrow = n_p, ncol = n_i, byrow = TRUE)) * 1L
colnames(raw) <- colnames(scored) <- sprintf("I%02d", seq_len(n_i))
data.mc <- list(raw = raw,
                scored = as.data.frame(scored))
save(data.mc, file = "data/data.mc.rda", compress = "xz")

cat("DATASETS WRITTEN:\n",
    " data.sim.rasch", paste(dim(data.sim.rasch), collapse = "x"), "\n",
    " data.gpcm     ", paste(dim(data.gpcm), collapse = "x"), "\n",
    " data.mc$raw   ", paste(dim(data.mc$raw), collapse = "x"), "\n")
