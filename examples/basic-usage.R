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

## 6. One-stop workflow (usability layer, new in 1.0.0) -----------------------
# Read from any common format, clean, check, estimate and enrich in one call.
mod_easy <- irtc(data.sim.rasch, model = "1PL", verbose = FALSE)

# Layered plain-language summary (conclusion first). lang: "zh" or "en".
plain_summary(mod_easy, lang = "en")

# Pre-flight data check with concrete fixes (also machine readable)
chk <- irtc_check_data(data.sim.rasch, verbose = FALSE)
chk$ok

# Item quality ratings, classical statistics, item fit
mod_easy$usability$quality
irtc_ctt(data.sim.rasch)$alpha
irtc_itemfit(mod_easy)

## 7. Scoring raw multiple-choice responses ----------------------------------
raw <- data.frame(Q1 = c("A", "b", "C"), Q2 = c("c", "C", "D"),
    stringsAsFactors = FALSE)
irtc_score(raw, key = c(Q1 = "A", Q2 = "C"))

## 8. Exports and reports ------------------------------------------------------
# Three Excel workbooks (requires openxlsx):
#   irtc_excel(mod_easy, dir = "results")
# Audience-specific reports (html is dependency-free; docx needs officer):
#   irtc_report(mod_easy, "report.html", audience = "decision")
#   irtc_report(mod_easy, "report.docx", audience = "stat")
# Machine-readable results for pipelines/AI agents (json needs jsonlite):
res <- irtc_results(mod_easy)
str(res$model_info)
#   irtc_json(mod_easy, "results.json")

## 9. Diagnostic plots ---------------------------------------------------------
# plot(mod_easy, type = "wright")
# plot(mod_easy, type = "icc", items = 1:6)
