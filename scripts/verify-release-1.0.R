# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Release verification for IRTC 1.0.0. Run from the repository root:
#   Rscript scripts/verify-release-1.0.R
#
# Steps: (1) install optional deps used by tests, (2) run the full testthat
# suite, (3) build the tarball, (4) R CMD check --as-cran, (5) smoke-test the
# usability workflow end to end. The script stops at the first failure.

## Force untranslated base-R error messages: several legacy tests match
## them literally, so a zh_CN locale would make those tests fail. Must be
## set before any translated message is emitted (child processes inherit it).
Sys.setenv(LANGUAGE="en")

## Non-interactive Rscript sessions have no CRAN mirror set; pick one here.
## Override with e.g. IRTC_CRAN_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/CRAN
mirror <- Sys.getenv("IRTC_CRAN_MIRROR", "https://cloud.r-project.org")
options(repos=c(CRAN=mirror))

message("== 1/6 optional dependencies =========================")
opt <- c("readxl", "writexl", "haven", "openxlsx", "officer", "jsonlite",
    "mvtnorm", "sfsmisc", "testthat", "devtools", "rcmdcheck", "covr")
missing <- opt[!vapply(opt, requireNamespace, logical(1L), quietly=TRUE)]
if (length(missing) > 0L) {
    message("Installing: ", paste(missing, collapse=", "))
    install.packages(missing)
}

message("== 2/6 testthat suite ================================")
res <- devtools::test(stop_on_failure=TRUE)

message("== 3/6 coverage (targets: overall >= 90%, key >= 95%) =")
cov <- covr::package_coverage(type="tests", quiet=TRUE)
overall <- covr::percent_coverage(cov)
tal <- covr::tally_coverage(cov, by="line")
per_file <- stats::aggregate(value ~ filename, data=tal,
    FUN=function(v) round(100 * mean(v > 0), 1))
names(per_file) <- c("file", "coverage")
per_file <- per_file[order(per_file$coverage), ]
message("Files with the lowest coverage:")
print(utils::head(per_file, 20), row.names=FALSE)
message(sprintf("Overall coverage: %.1f%%", overall))

## key nodes: user-facing entry points of both API layers
key_files <- c("R/irtc.R", "R/irtc_read.R", "R/irtc_score.R",
    "R/irtc_check_data.R", "R/irtc_ctt.R", "R/irtc_itemfit.R",
    "R/irtc_quality.R", "R/irtc_excel.R", "R/irtc_results.R",
    "R/irtc.mml.R", "R/irtc.mml.2pl.R")
key <- per_file[per_file$file %in% key_files, ]
message("Key-node coverage:")
print(key, row.names=FALSE)

shortfall <- character(0)
if (overall < 90) {
    shortfall <- c(shortfall,
        sprintf("overall coverage %.1f%% is below 90%%", overall))
}
low_key <- key[key$coverage < 95, ]
if (nrow(low_key) > 0L) {
    shortfall <- c(shortfall, sprintf("%s at %.1f%% is below 95%%",
        low_key$file, low_key$coverage))
}
if (length(shortfall) > 0L) {
    if (nrow(low_key) > 0L) {
        message("Uncovered lines in key files below target:")
        uncov <- tal[tal$value == 0 & tal$filename %in% low_key$file, ]
        for (f in unique(uncov$filename)) {
            lines <- sort(unique(uncov$line[uncov$filename == f]))
            message("  ", f, ": ", paste(lines, collapse=","))
        }
    }
    stop("Coverage targets not met:\n  ",
        paste(shortfall, collapse="\n  "))
}
message("Coverage targets met.")

message("== 4/6 build =========================================")
tarball <- devtools::build()
message("Built: ", tarball)

message("== 5/6 R CMD check --as-cran =========================")
chk <- rcmdcheck::rcmdcheck(args=c("--as-cran", "--no-manual"),
    error_on="warning")
print(chk)

message("== 6/6 end-to-end smoke test =========================")
library(IRTC)
set.seed(1)
theta <- rnorm(300)
resp <- as.data.frame(sapply(seq(-1.5, 1.5, length.out=10), function(b) {
    as.numeric(runif(300) < plogis(theta - b))
}))
colnames(resp) <- paste0("I", 1:10)
csv <- tempfile(fileext=".csv")
write.csv(cbind(id=paste0("S", 1:300), resp), csv, row.names=FALSE)

mod <- irtc(csv, model="2PL", verbose=FALSE)
stopifnot(inherits(mod, "irtc"), mod$nitems == 10L)
plain_summary(mod, lang="zh")
plain_summary(mod, lang="en")

out_dir <- file.path(tempdir(), "irtc-smoke")
paths <- irtc_excel(mod, dir=out_dir, overwrite=TRUE, verbose=FALSE)
stopifnot(all(file.exists(paths)))

for (aud in c("decision", "survey", "stat")) {
    f <- file.path(out_dir, paste0("report-", aud, ".html"))
    irtc_report(mod, f, audience=aud, overwrite=TRUE, verbose=FALSE)
    stopifnot(file.exists(f))
}
f <- file.path(out_dir, "report.docx")
irtc_report(mod, f, audience="survey", overwrite=TRUE, verbose=FALSE)
stopifnot(file.exists(f))

irtc_json(mod, file.path(out_dir, "results.json"))
stopifnot(file.exists(file.path(out_dir, "results.json")))

message("All verification steps passed. Outputs in: ", out_dir)
message("Tarball ready for CRAN submission: ", tarball)
