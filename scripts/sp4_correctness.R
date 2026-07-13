# Validate the experimental streaming engine against the production irtc.mml.2pl
# on a small simple-structure 2-dim 2PL dataset. Primary criterion: both engines
# recover the known simulated slopes; secondary: engine-vs-engine agreement.
suppressMessages(devtools::load_all(".", quiet = TRUE))
source("scripts/sp4_simulate.R")

d <- sp4_simulate(N = 5000, I = 16, D = 2, maxK = 2, seed = 7)
Q <- matrix(0, 16, 2); for (j in 1:16) Q[j, d$dim_of[j]] <- 1

# production engine (estimate the latent covariance too, to match the proto model)
ref <- irtc.mml.2pl(resp = d$resp, irtmodel = "2PL", Q = Q, est.variance = TRUE,
                    control = list(nodes = seq(-5, 5, len = 21)), verbose = FALSE)
ref_a <- apply(ref$B, 1, function(z) z[which.max(abs(z))])   # the one nonzero loading

# experimental streaming engine
m <- irtc_mml_fast_proto(d$resp, d$dim_of, maxK = 2, Q = 21, maxiter = 80,
                         squarem = TRUE)

cat(sprintf("proto recovers truth : slope ratio %.3f  (corr %.3f)\n",
            mean(m$a / d$a), cor(m$a, d$a)))
cat(sprintf("ref   recovers truth : slope ratio %.3f  (corr %.3f)\n",
            mean(ref_a / d$a), cor(ref_a, d$a)))
cat(sprintf("proto vs ref slopes  : corr %.3f  max|diff| %.3f\n",
            cor(m$a, ref_a), max(abs(m$a - ref_a))))
cat(sprintf("latent corr  true=%.2f  proto=%.3f  ref=%.3f\n",
            d$Sigma[1, 2], m$Sigma[1, 2], stats::cov2cor(ref$variance)[1, 2]))
