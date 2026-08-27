# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Release verification for IRTC 1.1.2. Run from the repository root:
#   Rscript scripts/verify-release-1.1.2.R
#
# Steps: (1) optional deps, (2) testthat suite, (3) coverage, (4) build,
# (5) R CMD check --as-cran WITH the PDF manual, (6) PDF manual is ASCII,
# (7) end-to-end smoke test, (8) regression guards for the 1.1.2 defects.
# The script stops at the first failure.
#
# WHY THIS SCRIPT EXISTS SEPARATELY FROM verify-release-1.1.R
#
# That script ran `rcmdcheck` with `--as-cran` AND `--no-manual`, which skips
# building the PDF reference manual. CRAN's incoming pre-tests do build it,
# and they rejected 1.1.0 on a LaTeX failure that was therefore invisible
# locally: "0 WARNING" was true for --no-manual and said nothing about the
# manual. This script never passes --no-manual, and additionally asserts that
# the generated manual is free of CJK characters, which is the specific
# condition that failed.
#
# STILL NOT COVERED BY THIS SCRIPT: r-devel. The other 1.1.0 rejection was a
# test that matched the released-R wording "R version", which does not hold on
# r-devel. That reproduces on no released-R flavor, so a win-builder r-devel
# run remains a required manual step before submission. See step 9.

## Force untranslated base-R error messages: several legacy tests match
## them literally, so a zh_CN locale would make those tests fail. Must be
## set before any translated message is emitted (child processes inherit it).
Sys.setenv(LANGUAGE="en")

## Non-interactive Rscript sessions have no CRAN mirror set; pick one here.
## Override with e.g. IRTC_CRAN_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/CRAN
mirror <- Sys.getenv("IRTC_CRAN_MIRROR", "https://cloud.r-project.org")
options(repos=c(CRAN=mirror))

EXPECTED_VERSION <- "1.1.2"

message("== 1/9 optional dependencies =========================")
opt <- c("readxl", "writexl", "haven", "openxlsx", "officer", "jsonlite",
    "mvtnorm", "sfsmisc", "testthat", "devtools", "rcmdcheck", "covr")
missing <- opt[!vapply(opt, requireNamespace, logical(1L), quietly=TRUE)]
if (length(missing) > 0L) {
    message("Installing: ", paste(missing, collapse=", "))
    install.packages(missing)
}

## The PDF manual cannot be built without LaTeX, and silently skipping it is
## exactly the failure mode this script exists to prevent.
if (nzchar(Sys.which("pdflatex")) == FALSE) {
    stop("pdflatex not found. The PDF reference manual must be built as part\n",
         "  of verification -- skipping it is what let the 1.1.0 LaTeX failure\n",
         "  reach CRAN. Install TeX Live / MacTeX and re-run.")
}

message("== 2/9 testthat suite ================================")
res <- devtools::test(stop_on_failure=TRUE)

message("== 3/9 coverage (targets: overall >= 90%, key >= 95%) =")
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
    "R/irtc_qmatrix.R", "R/irtc_rare_categories.R",
    "R/irtc_check_data.R", "R/irtc_ctt.R", "R/irtc_itemfit.R",
    "R/irtc_quality.R", "R/irtc_excel.R", "R/irtc_results.R",
    "R/irtc_report.R", "R/irtc.mml.R", "R/irtc.mml.2pl.R",
    "R/irtc_audit.R", "R/irtc_weighted_stats.R")
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

message("== 4/9 build =========================================")
tarball <- devtools::build()
message("Built: ", tarball)
if (!grepl(paste0("IRTC_", EXPECTED_VERSION, ".tar.gz"), tarball, fixed=TRUE)) {
    stop("Tarball is not version ", EXPECTED_VERSION, ": ", tarball,
         "\n  Update DESCRIPTION (Version and Date) before verifying.")
}

message("== 5/9 R CMD check --as-cran (PDF manual INCLUDED) ===")
## Deliberately no --no-manual. See the header note.
## check_dir is set explicitly so step 6 knows where to find the built manual.
check_dir <- file.path(tempdir(), "irtc-check")
unlink(check_dir, recursive=TRUE)
dir.create(check_dir, recursive=TRUE, showWarnings=FALSE)
chk <- rcmdcheck::rcmdcheck(tarball, args="--as-cran", check_dir=check_dir,
    error_on="warning")
print(chk)

## Notes that are this machine's toolchain rather than the package. Anything
## else must be looked at before submitting: a real NOTE is a real finding
## now that "New submission" no longer applies.
local_toolchain <- c("HTML Tidy", "math rendering", "package 'V8'")
real_notes <- Filter(function(nt)
    !any(vapply(local_toolchain, grepl, logical(1L), x=nt, fixed=TRUE)),
    chk$notes)
if (length(real_notes) > 0L) {
    message("NOTEs that are NOT explained by this machine's toolchain:")
    for (nt in real_notes) message("  ", nt)
    stop("Resolve the NOTEs above, or record why each is acceptable in\n",
         "  cran-comments.md, before submitting.")
}
message("check: 0 errors, 0 warnings, no package-level notes.")

message("== 6/9 PDF reference manual is ASCII =================")
## The 1.1.0 rejection was CJK characters reaching LaTeX. The \zh macro keeps
## them out of the PDF; assert that it still does, now and after any Rd edit.
pdf <- file.path(check_dir, "IRTC.Rcheck", "IRTC-manual.pdf")
if (!file.exists(pdf)) {
    found <- list.files(check_dir, pattern="IRTC-manual[.]pdf$",
        recursive=TRUE, full.names=TRUE)
    if (length(found) == 0L) {
        stop("IRTC-manual.pdf was not produced under ", check_dir,
             "\n  The PDF manual must be built during verification: check that\n",
             "  --no-manual was not passed and that LaTeX is installed.")
    }
    pdf <- found[1L]
}
message("Manual: ", pdf, " (", round(file.size(pdf) / 1024), " KB)")
if (nzchar(Sys.which("pdftotext"))) {
    txt <- suppressWarnings(system2("pdftotext", c(shQuote(pdf), "-"),
        stdout=TRUE, stderr=FALSE))
    cjk <- sum(vapply(strsplit(paste(txt, collapse=""), "")[[1]],
        function(ch) {
            cp <- utf8ToInt(ch)
            isTRUE(cp >= 0x4E00 && cp <= 0x9FFF)
        }, logical(1L)))
    if (cjk > 0L) {
        stop("The PDF manual contains ", cjk, " CJK character(s).\n",
             "  Rd sources reaching LaTeX must stay ASCII: wrap Chinese text\n",
             "  in the \\zh macro (man/macros/irtc.Rd), which renders the\n",
             "  characters in HTML/text help and a \\uxxxx escape in the PDF.")
    }
    message("PDF manual contains 0 CJK characters.")
} else {
    message("NOTE: pdftotext not installed; could not verify the manual is ",
        "ASCII.\n  Install poppler (brew install poppler) for this check.")
}

message("== 7/9 end-to-end smoke test =========================")
library(IRTC)
stopifnot(identical(as.character(utils::packageVersion("IRTC")),
    EXPECTED_VERSION))
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

## --- GPCM workflow: weighted csv + Q matrix + partial-credit key ---
message("-- GPCM end-to-end (weights + Q matrix + partial key) --")
set.seed(2)
n <- 400
theta <- rnorm(n)
gen_item <- function(shift) {
    u <- plogis(theta - shift)
    r <- runif(n)
    ifelse(r < u * 0.5, "A", ifelse(r < u, "B",
        sample(c("C", "D"), n, replace=TRUE)))
}
raw <- data.frame(
    id = paste0("S", seq_len(n)),
    Q1 = gen_item(0), Q2 = gen_item(0.4), Q3 = gen_item(-0.4),
    Q4 = gen_item(0.8), Q5 = gen_item(-0.2), Q6 = gen_item(0.2),
    weight = runif(n, 0.5, 2), stringsAsFactors = FALSE)
data_csv <- tempfile(fileext = ".csv")
write.csv(raw, data_csv, row.names = FALSE)

key_csv <- tempfile(fileext = ".csv")
write.csv(data.frame(item = paste0("Q", 1:6), answer = rep("A", 6),
    partial_answer = rep("B", 6)), key_csv, row.names = FALSE)

q_csv <- tempfile(fileext = ".csv")
write.csv(data.frame(item = paste0("Q", 1:6),
    reasoning = c(1, 1, 1, 0, 0, 0), fluency = c(0, 0, 0, 1, 1, 1),
    partial = rep(1, 6)), q_csv, row.names = FALSE)

for (mode in c("collapse", "prior")) {
    modg <- suppressWarnings(irtc(data_csv, model = "GPCM", key = key_csv,
        q = q_csv, rare_categories = mode, verbose = FALSE,
        control = list(maxiter = 60)))
    stopifnot(inherits(modg, "irtc"))
    res <- irtc_results(modg)
    stopifnot(res$model_info$schema_version == "1.2",
        !is.null(res$model_info$dimension_names),
        any(grepl("reasoning", colnames(res$persons))))
    tbl <- irtc_param_table(modg)
    stopifnot(any(c("b_partial", "b_full") %in% colnames(tbl)))
    gdir <- file.path(out_dir, paste0("gpcm-", mode))
    irtc_report(modg, file.path(gdir, "report-stat.html"),
        audience = "stat", overwrite = TRUE, verbose = FALSE)
    stopifnot(file.exists(file.path(gdir, "report-stat.html")))
}

## extreme data: unobserved middle category + a nobody-answered item
set.seed(3)
ext <- data.frame(
    E1 = 2 * as.numeric(runif(200) < plogis(rnorm(200))),   # 0/2 only
    E2 = as.numeric(runif(200) < 0.5),
    E3 = as.numeric(runif(200) < 0.5),
    E4 = rep(1, 200))                                        # zero variance
extd <- irtc_read(ext, recode = FALSE, verbose = FALSE)
modx <- suppressWarnings(irtc(extd, model = "PCM", verbose = FALSE,
    control = list(maxiter = 60)))
resx <- irtc_results(modx)
stopifnot("E4" %in% resx$items$item_id,
    resx$items$status[resx$items$item_id == "E4"] == "dropped_no_response")

message("== 8/9 regression guards for the 1.1.2 defects =======")
## The testthat suite covers these in detail; these are the release-level
## smoke versions, so a broken build cannot ship even if a test file is
## accidentally skipped.
sim2d <- function(n = 500, J = 6, seed = 11) {
    set.seed(seed)
    Q <- matrix(0, J, 2)
    Q[seq(1, J, 2), 1] <- 1
    Q[seq(2, J, 2), 2] <- 1
    th <- MASS::mvrnorm(n, c(0, 0), matrix(c(1, .5, .5, 1), 2))
    a0 <- runif(J, .8, 1.6); b0 <- rnorm(J)
    thj <- sapply(seq_len(J), function(j) th[, which(Q[j, ] == 1)])
    r <- matrix(rbinom(n * J, 1, plogis(t(a0 * (t(thj) - b0)))), n, J)
    colnames(r) <- paste0("I", seq_len(J))
    list(resp = r, Q = Q)
}
d <- sim2d()

## S1-01 NA in the streaming engine must not crash the session
holed <- d$resp; holed[1, 1] <- NA; holed[5, 3] <- NA
mna <- irtc.mml.2pl(resp = holed, irtmodel = "GPCM", ndim = 2, Q = d$Q,
    verbose = FALSE, method = "streaming")
stopifnot(is.finite(mna$ic$deviance))

## S1-02 the reported log-likelihood is a log-probability and does not
## depend on the node count; the two engines agree on the same model
lls <- vapply(c(21, 31), function(nq) {
    m <- irtc.mml.2pl(resp = d$resp, irtmodel = "GPCM", ndim = 2, Q = d$Q,
        verbose = FALSE, method = "streaming",
        control = list(nodes = seq(-6, 6, length.out = nq)))
    m$ic$loglike
}, numeric(1))
stopifnot(all(lls < 0), abs(diff(lls)) < 1)
uni <- sim2d(n = 600, J = 8, seed = 13)$resp
g <- irtc.mml.2pl(resp = uni, irtmodel = "2PL", ndim = 1, verbose = FALSE,
    method = "grid")
st <- irtc.mml.2pl(resp = uni, irtmodel = "2PL", ndim = 1, verbose = FALSE,
    method = "streaming")
stopifnot(abs(g$ic$deviance - st$ic$deviance) / abs(g$ic$deviance) < 1e-4)

## S2-04/05, S3-07 multidimensional parameters, ids, weights and SEs
set.seed(17); wt <- runif(nrow(d$resp), .5, 3)
Qn <- d$Q; dimnames(Qn) <- list(colnames(d$resp), c("DimA", "DimB"))
dd <- data.frame(pid = seq_len(nrow(d$resp)) + 90000L, d$resp, wt = wt)
m2 <- suppressWarnings(irtc(dd, model = "GPCM", q = Qn, ndim = 2,
    id = "pid", weights = "wt", verbose = FALSE))
pt <- irtc_param_table(m2)
stopifnot(!any(pt$slope_a == 0), !anyNA(pt$difficulty_b),
    identical(pt$item_id, colnames(d$resp)),
    identical(pt$dimension, colnames(Qn)[apply(Qn != 0, 1, which.max)]),
    identical(as.character(irtc_results(m2)$persons$person_id),
        as.character(dd$pid)),
    isTRUE(all.equal(m2$person$pweight,
        wt * nrow(d$resp) / sum(wt), tolerance = 1e-8)),
    all(c("SD.EAP.Dim1", "SD.EAP.Dim2") %in% colnames(m2$person)))

## S2-06 weights reach the classical statistics and the person norms, and
## constant weights reproduce the unweighted values exactly
ct <- irtc_ctt(as.data.frame(d$resp), weights = wt)
stopifnot(isTRUE(all.equal(ct$items$pvalue,
    round(as.numeric(apply(d$resp, 2, function(x) sum(wt * x) / sum(wt))), 4))))
stopifnot(isTRUE(all.equal(
    irtc_ctt(as.data.frame(d$resp), weights = rep(2, nrow(d$resp)))$items,
    irtc_ctt(as.data.frame(d$resp))$items)))
pw <- IRTC:::irtc_prep_case_weights(m2$pweights, nrow(m2$person))
tsc <- irtc_results(m2)$persons[[grep("^t_score", 
    names(irtc_results(m2)$persons))[1]]]
stopifnot(abs(sum(pw * tsc) / sum(pw) - 50) < 0.05)

## S1-10 an answer key is written in the data file's own category coding
set.seed(19); nk <- 200
kraw <- data.frame(pid = seq_len(nk),
    Q1 = sample(1:4, nk, TRUE), Q2 = sample(1:4, nk, TRUE),
    Q3 = sample(1:3, nk, TRUE), Q4 = sample(1:3, nk, TRUE))
kcsv <- tempfile(fileext = ".csv")
write.csv(kraw, kcsv, row.names = FALSE)
mk <- irtc(kcsv, model = "2PL", key = c(Q1 = 2, Q2 = 4, Q3 = 1, Q4 = 2),
    id = "pid", verbose = FALSE)
stopifnot(isTRUE(all.equal(as.numeric(colMeans(mk$resp)),
    as.numeric(c(mean(kraw$Q1 == 2), mean(kraw$Q2 == 4),
        mean(kraw$Q3 == 1), mean(kraw$Q4 == 2))))))
stopifnot(irtc_audit_scoring(mk)$status == "ok_fixed")
archived <- mk; archived$usability$package_version <- "1.1.1"
stopifnot(irtc_audit_scoring(archived)$status == "affected",
    length(irtc_audit_scoring(archived)$affected_items) == 4L)

## S3-08 the grid engine refuses a hopeless allocation with advice
e409 <- tryCatch(IRTC:::irtc_grid_memory_guard(N = 85035, nnodes = 21^3,
    D = 3, streaming_possible = TRUE, budget_gb = 16),
    error = function(e) e)
stopifnot(inherits(e409, "irtc_error"), e409$code == "E409")

message("All 1.1.2 regression guards passed.")

message("== 9/9 remaining manual step =========================")
message("")
message("  win-builder R-devel has NOT been run by this script.")
message("")
message("  It is required before submission. The 1.1.0 rejection included a")
message("  test failure that reproduces on r-devel only, because r-devel's")
message("  R.version.string reads 'R Under development (unstable)' rather")
message("  than 'R version'. No released-R flavor can catch that class of")
message("  problem, so a local green run does not imply a CRAN green run.")
message("")
message("  Submit the tarball at https://win-builder.r-project.org/upload.aspx")
message("  to R-devel, and wait for the emailed result before proceeding.")
message("")
message("Tarball: ", tarball)
message("Check outputs: ", check_dir)
message("Smoke-test outputs: ", out_dir)
