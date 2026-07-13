# Simulate simple-structure (between-item) multidimensional 2PL/GPCM data.
# Each item loads exactly one dimension. theta ~ MVN(0, Sigma).
sp4_simulate <- function(N, I, D, Q_nodes = 21, maxK = 2, Sigma = NULL, seed = 1) {
  set.seed(seed)
  if (is.null(Sigma)) {                      # mild positive correlations
    Sigma <- matrix(0.3, D, D); diag(Sigma) <- 1
  }
  dim_of <- rep(1:D, length.out = I)         # item -> dimension
  a <- runif(I, 0.7, 1.8)                    # slopes
  # thresholds b[item, 1..maxK-1] increasing
  b <- t(apply(matrix(rnorm(I * (maxK - 1)), I, maxK - 1), 1, sort))
  if (maxK == 2) b <- matrix(b, I, 1)
  L <- chol(Sigma)
  theta <- matrix(rnorm(N * D), N, D) %*% L   # N x D abilities
  resp <- matrix(0L, N, I)
  for (j in 1:I) {
    th <- theta[, dim_of[j]]
    # GPCM category probabilities
    eta <- sapply(0:(maxK - 1), function(k) {
      if (k == 0) rep(0, N) else rowSums(matrix(a[j] * (th - b[j, 1:k]), N, k))
    })
    P <- exp(eta); P <- P / rowSums(P)
    cum <- t(apply(P, 1, cumsum)); u <- runif(N)
    resp[, j] <- max.col(-(cum < u), ties.method = "first") - 1L
  }
  list(resp = resp, dim_of = dim_of, a = a, b = b, Sigma = Sigma, maxK = maxK)
}

# Pathological-input variants for robustness testing.
sp4_simulate_pathology <- function(kind, N = 3000, seed = 1) {
  set.seed(seed)
  if (kind == "empty_cat") {
    d <- sp4_simulate(N = N, I = 12, D = 2, maxK = 4, seed = seed)
    d$resp[d$resp == 2L] <- 1L                       # category 2 never observed
    return(d)
  }
  if (kind == "extreme_item") {
    d <- sp4_simulate(N = N, I = 12, D = 2, maxK = 2, seed = seed)
    d$resp[, 1] <- rbinom(N, 1, 0.02)                # ~all 0
    return(d)
  }
  if (kind == "low_disc") {
    d <- sp4_simulate(N = N, I = 12, D = 2, maxK = 2, seed = seed)
    d$resp[, 1] <- rbinom(N, 1, 0.5)                 # item 1 ~ noise (a ~ 0)
    return(d)
  }
  if (kind == "high_disc") {
    d <- sp4_simulate(N = N, I = 12, D = 2, maxK = 2, seed = seed)
    th <- rnorm(N); d$resp[, 1] <- as.integer(th > 0)# near-perfect (separation)
    return(d)
  }
  if (kind == "corr_thresh") {
    return(sp4_simulate(N = N, I = 12, D = 2, maxK = 4, seed = seed))
  }
  if (kind == "sparse_region") {
    d <- sp4_simulate(N = N, I = 12, D = 2, maxK = 2, seed = seed)
    keep <- rowSums(d$resp) > stats::quantile(rowSums(d$resp), 0.3)
    d$resp <- d$resp[keep, , drop = FALSE]; return(d)
  }
  if (kind == "bad_init") {
    return(sp4_simulate(N = N, I = 12, D = 2, maxK = 2, seed = seed))
  }
  if (kind == "weak_dim") {
    d <- sp4_simulate(N = N, I = 12, D = 2, maxK = 2, seed = seed)
    dim2 <- which(d$dim_of == 2)
    for (j in dim2[-(1:2)]) d$dim_of[j] <- 1L        # leave dim 2 with 2 weak items
    d$resp[, dim2[1:2]] <- matrix(rbinom(N * 2, 1, 0.5), N, 2)
    return(d)
  }
  stop("unknown pathology")
}
