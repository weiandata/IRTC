# Basic usage of the IRTC package.
# Run from the repository root after installing the package:
#   Rscript examples/basic-usage.R

library(IRTC)

## 1. Unidimensional Rasch model on bundled simulated data -------------------
data(data.sim.rasch)
mod_rasch <- irtc.mml(resp = data.sim.rasch)
summary(mod_rasch)

# Item parameters and EAP person ability estimates
head(mod_rasch$item)
head(mod_rasch$person)

## 2. Partial credit model on polytomous data --------------------------------
data(data.gpcm)
mod_pcm <- irtc.mml(resp = data.gpcm, irtmodel = "PCM")
summary(mod_pcm)

## 3. Two-parameter logistic (2PL) model --------------------------------------
mod_2pl <- irtc.mml.2pl(resp = data.sim.rasch, irtmodel = "2PL")
summary(mod_2pl)

## 4. Model comparison: Rasch vs 2PL ------------------------------------------
anova(mod_rasch, mod_2pl)

## 5. Information criteria -----------------------------------------------------
logLik(mod_rasch)
mod_rasch$ic
