# =============================================================================
# gen_reference.R -- Generate numerical regression fixtures for IRTC.
#
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
#
# The fixtures are the maximum-likelihood parameter estimates that IRTC's
# estimation engine produces on IRTC's own bundled example datasets. They are
# numerical facts determined by the statistical model and serve as a
# self-contained regression oracle (no third-party package is involved).
#
# Regenerate after changing the bundled datasets (scripts/gen_data.R) or when
# deliberately re-baselining the estimation engine:
#
#   Rscript scripts/gen_reference.R
# =============================================================================

suppressMessages(devtools::load_all(".", quiet = TRUE))
dir.create("tests/testthat/fixtures", recursive = TRUE, showWarnings = FALSE)

load("data/data.sim.rasch.rda")
m1 <- irtc.mml(resp = data.sim.rasch, verbose = FALSE)
saveRDS(list(xsi = as.numeric(m1$xsi$xsi), beta = as.numeric(m1$beta),
             variance = as.numeric(m1$variance), deviance = as.numeric(m1$deviance)),
        "tests/testthat/fixtures/ref_rasch.rds")

load("data/data.gpcm.rda")
m2 <- irtc.mml(resp = data.gpcm, irtmodel = "PCM", verbose = FALSE)
saveRDS(list(xsi = as.numeric(m2$xsi$xsi), deviance = as.numeric(m2$deviance)),
        "tests/testthat/fixtures/ref_pcm.rds")

load("data/data.sim.rasch.rda")
m3 <- irtc.mml.2pl(resp = data.sim.rasch, irtmodel = "2PL", verbose = FALSE)
saveRDS(list(xsi = as.numeric(m3$xsi$xsi), B = as.numeric(m3$B),
             beta = as.numeric(m3$beta), deviance = as.numeric(m3$deviance)),
        "tests/testthat/fixtures/ref_2pl.rds")

load("data/data.gpcm.rda")
m4 <- irtc.mml.2pl(resp = data.gpcm, irtmodel = "GPCM", verbose = FALSE)
saveRDS(list(xsi = as.numeric(m4$xsi$xsi), B = as.numeric(m4$B),
             deviance = as.numeric(m4$deviance)),
        "tests/testthat/fixtures/ref_gpcm2pl.rds")

cat("REFERENCES WRITTEN (IRTC", as.character(utils::packageVersion("IRTC")), ")\n")
