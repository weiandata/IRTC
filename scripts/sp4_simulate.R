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
