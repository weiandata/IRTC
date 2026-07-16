# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc.R
## Part of the IRTC package
## One-stop estimation entry point for non-specialists and automated
## callers: read -> clean -> score -> check -> estimate -> enrich.
## Professional users keep full control through '...' which is passed to
## irtc.mml() / irtc.mml.2pl() unchanged.

irtc <- function(data, model, key=NULL, rules=NULL, q=NULL,
    on_mismatch=c("warn", "error"), id=NULL, weights=NULL,
    sheet=1, missing_codes=c(-9, -99, 99, 999), check=TRUE, quality=TRUE,
    verbose=TRUE, ...)
{
    ## --- model argument ---------------------------------------------------
    model_map <- c(
        "1pl"="1PL", "rasch"="1PL", "pcm"="PCM", "pcm2"="PCM2",
        "rsm"="RSM", "2pl"="2PL", "gpcm"="GPCM"
    )
    if (missing(model) || is.null(model)) {
        irtc_stop(code="E406",
            en=paste0("The 'model' argument is required. Choose one of: ",
                "\"1PL\" (or \"Rasch\"), \"2PL\", \"PCM\", \"PCM2\", ",
                "\"RSM\", \"GPCM\"."),
            zh=paste0("\u5fc5\u987b\u6307\u5b9a 'model' \u53c2\u6570\u3002\u53ef\u9009\uff1a\"1PL\"\uff08\u6216 ",
                "\"Rasch\"\uff09\u3001\"2PL\"\u3001\"PCM\"\u3001\"PCM2\"\u3001\"RSM\"\u3001",
                "\"GPCM\"\u3002"),
            fix_en=paste0("Rule of thumb: right/wrong items -> \"1PL\" or ",
                "\"2PL\"; partial-credit or rating items -> \"PCM\" or ",
                "\"GPCM\"."),
            fix_zh=paste0("\u7ecf\u9a8c\u6cd5\u5219\uff1a\u5bf9\u9519\u9898\u7528 \"1PL\" \u6216 \"2PL\"\uff1b",
                "\u591a\u7ea7\u8ba1\u5206/\u91cf\u8868\u9898\u7528 \"PCM\" \u6216 \"GPCM\"\u3002"),
            class="irtc_error_input")
    }
    model_key <- tolower(trimws(as.character(model)[1L]))
    if (!(model_key %in% names(model_map))) {
        irtc_stop(code="E406",
            en=paste0("Unknown model '", model, "'. Choose one of: \"1PL\"",
                " (or \"Rasch\"), \"2PL\", \"PCM\", \"PCM2\", \"RSM\", ",
                "\"GPCM\"."),
            zh=paste0("\u672a\u77e5\u7684\u6a21\u578b '", model, "'\u3002\u53ef\u9009\uff1a\"1PL\"\uff08\u6216 ",
                "\"Rasch\"\uff09\u3001\"2PL\"\u3001\"PCM\"\u3001\"PCM2\"\u3001\"RSM\"\u3001",
                "\"GPCM\"\u3002"),
            fix_en="Check the spelling of the 'model' argument.",
            fix_zh="\u8bf7\u68c0\u67e5 'model' \u53c2\u6570\u7684\u62fc\u5199\u3002",
            class="irtc_error_input", data=list(model=model))
    }
    model <- model_map[[model_key]]

    ## --- read and clean ----------------------------------------------------
    if (inherits(data, "irtc_data")) {
        data_obj <- data
    } else {
        data_obj <- irtc_read(data, sheet=sheet, id=id, weights=weights,
            missing_codes=missing_codes, verbose=FALSE)
    }

    ## --- score raw responses ------------------------------------------------
    if (!is.null(key) || !is.null(rules)) {
        data_obj <- irtc_score(data_obj, key=key, rules=rules)
    }

    ## --- Q matrix: read and align against the data ---------------------------
    qobj <- NULL
    if (!is.null(q)) {
        on_mismatch <- match.arg(on_mismatch)
        qobj <- if (inherits(q, "irtc_qmatrix")) q else irtc_read_q(q)
        aligned <- irtc_align_q(data_obj, qobj, on_mismatch=on_mismatch)
        data_obj <- aligned$data
        qobj <- aligned$q

        ## consistency between the Q partial-credit declaration and the
        ## scoring actually applied
        if (!is.null(data_obj$score_info)) {
            si <- data_obj$score_info
            q_items <- rownames(qobj$Q)
            declared <- names(qobj$partial)[qobj$partial]
            scored_items <- intersect(si$scored_items, q_items)
            multi <- intersect(si$partial_items, q_items)
            w423 <- setdiff(intersect(declared, scored_items), multi)
            if (length(w423) > 0L) {
                irtc_warn(code="W423",
                    en=paste0("Item(s) declared as partial credit in the Q",
                        " matrix but scored right/wrong only (no partial ",
                        "answer or rules given): ",
                        paste(w423, collapse=", "), "."),
                    zh=paste0("\u4ee5\u4e0b\u9898\u76ee\u5728 Q \u77e9\u9635\u4e2d\u58f0\u660e\u4e3a\u5206\u90e8\u8ba1\u5206\uff0c\u4f46\u8ba1\u5206\u65f6\u672a\u63d0\u4f9b\u90e8\u5206\u6b63\u786e\u7b54\u6848\u6216\u8ba1\u5206\u89c4\u5219\uff0c\u5df2\u6309\u5bf9/\u9519\u8ba1\u5206\uff1a",
                        paste(w423, collapse="\u3001"), "\u3002"),
                    fix_en=paste0("Add a partial_answer column to the key ",
                        "file, or supply 'rules' for these items."),
                    fix_zh=paste0("\u8bf7\u5728\u7b54\u6848\u952e\u4e2d\u6dfb\u52a0\u90e8\u5206\u6b63\u786e\u7b54\u6848\u5217\uff0c\u6216\u4e3a\u8fd9\u4e9b\u9898\u76ee\u63d0\u4f9b 'rules' \u8ba1\u5206\u89c4\u5219\u3002"),
                    class="irtc_warning_scoring", data=list(items=w423))
            }
            w424 <- setdiff(multi, declared)
            if (length(w424) > 0L) {
                irtc_warn(code="W424",
                    en=paste0("Item(s) scored with partial credit but not ",
                        "declared as partial credit in the Q matrix: ",
                        paste(w424, collapse=", "), "."),
                    zh=paste0("\u4ee5\u4e0b\u9898\u76ee\u6309\u5206\u90e8\u8ba1\u5206\u8ba1\u5206\uff0c\u4f46 Q \u77e9\u9635\u672a\u58f0\u660e\u5176\u4e3a\u5206\u90e8\u8ba1\u5206\uff1a",
                        paste(w424, collapse="\u3001"), "\u3002"),
                    fix_en=paste0("Update the partial-credit column of the ",
                        "Q matrix if the scoring is intended."),
                    fix_zh=paste0("\u5982\u8ba1\u5206\u65b9\u5f0f\u65e0\u8bef\uff0c\u8bf7\u540c\u6b65\u66f4\u65b0 Q \u77e9\u9635\u7684\u5206\u90e8\u8ba1\u5206\u5217\u3002"),
                    class="irtc_warning_scoring", data=list(items=w424))
            }
        }
    }

    ## --- pre-estimation check ----------------------------------------------
    check_obj <- irtc_check_data(data_obj, key=NULL, verbose=FALSE)
    if (check && !check_obj$ok) {
        err <- check_obj$issues[check_obj$issues$severity == "error", ]
        irtc_stop(code="E407",
            en=paste0("The data cannot be estimated yet. ",
                nrow(err), " error(s) found: ",
                paste(paste0("[", err$code, "] ", err$message_en),
                    collapse=" "), ""),
            zh=paste0("\u6570\u636e\u5c1a\u4e0d\u80fd\u7528\u4e8e\u4f30\u8ba1\uff0c\u53d1\u73b0 ", nrow(err),
                " \u4e2a\u9519\u8bef\uff1a",
                paste(paste0("[", err$code, "] ", err$message_zh),
                    collapse=" ")),
            fix_en=paste0("Run irtc_check_data(your_data) to see all issues",
                " with fixes."),
            fix_zh=paste0("\u8bf7\u8fd0\u884c irtc_check_data(\u4f60\u7684\u6570\u636e) \u67e5\u770b\u5168\u90e8\u95ee\u9898",
                "\u548c\u5904\u7406\u5efa\u8bae\u3002"),
            class="irtc_error_data_check", data=list(check=check_obj))
    }

    ## --- drop unusable items (no responses / zero variance) -----------------
    resp <- data_obj$resp
    bad_items <- unique(check_obj$issues$where[
        check_obj$issues$code %in% c("W307", "W310")])
    bad_items <- bad_items[nzchar(bad_items)]
    if (length(bad_items) > 0L) {
        resp <- resp[, setdiff(colnames(resp), bad_items), drop=FALSE]
        data_obj$log <- irtc_log_add(data_obj$log, "estimate", "W410",
            en=paste0("Removed ", length(bad_items), " unusable item(s) ",
                "before estimation: ", paste(bad_items, collapse=", "), "."),
            zh=paste0("\u4f30\u8ba1\u524d\u5254\u9664\u65e0\u6cd5\u4f7f\u7528\u7684\u9898\u76ee ", length(bad_items),
                " \u4e2a\uff1a", paste(bad_items, collapse="\u3001"), "\u3002"))
        ## always warn (independently of 'verbose'): silently dropping
        ## items would surprise both humans and automated callers
        irtc_warn(code="W410",
            en=paste0("Removed unusable item(s): ",
                paste(bad_items, collapse=", "), "."),
            zh=paste0("\u5df2\u5254\u9664\u65e0\u6cd5\u4f7f\u7528\u7684\u9898\u76ee\uff1a",
                paste(bad_items, collapse="\u3001"), "\u3002"),
            fix_en="See irtc_check_data() for the reasons.",
            fix_zh="\u539f\u56e0\u89c1 irtc_check_data() \u7684\u8f93\u51fa\u3002",
            class="irtc_warning_estimation")
    }
    if (ncol(resp) < 2L) {
        irtc_stop(code="E302",
            en="Fewer than 2 usable items remain; estimation is impossible.",
            zh="\u53ef\u7528\u9898\u76ee\u4e0d\u8db3 2 \u4e2a\uff0c\u65e0\u6cd5\u4f30\u8ba1\u3002",
            fix_en="Check the data quality issues reported above.",
            fix_zh="\u8bf7\u5148\u5904\u7406\u524d\u9762\u62a5\u544a\u7684\u6570\u636e\u8d28\u91cf\u95ee\u9898\u3002",
            class="irtc_error_data_check")
    }

    ## --- estimate ------------------------------------------------------------
    pid <- data_obj$pid
    fit_fun <- if (model %in% c("2PL", "GPCM")) irtc.mml.2pl else irtc.mml
    fit_args <- c(list(resp=resp, irtmodel=model, pid=pid, verbose=verbose),
        list(...))
    if (!is.null(qobj)) {
        if ("Q" %in% names(fit_args)) {
            irtc_warn(code="W419",
                en=paste0("Both 'q' and an explicit 'Q' argument were ",
                    "supplied; using 'Q' and ignoring 'q'."),
                zh=paste0("\u540c\u65f6\u63d0\u4f9b\u4e86 'q' \u548c\u663e\u5f0f\u7684 'Q' \u53c2\u6570\uff1b\u5c06\u4f7f\u7528 'Q'\uff0c\u5ffd\u7565 'q'\u3002"),
                fix_en="Supply only one of the two.",
                fix_zh="\u8bf7\u53ea\u63d0\u4f9b\u5176\u4e2d\u4e00\u4e2a\u3002",
                class="irtc_warning_estimation")
        } else {
            ## items dropped just above must leave the Q matrix as well
            fit_args$Q <- qobj$Q[colnames(resp), , drop=FALSE]
        }
    }
    if (!is.null(data_obj$weights)) {
        if ("pweights" %in% names(fit_args)) {
            irtc_warn(code="W418",
                en=paste0("Both a weights column (from the data) and an ",
                    "explicit 'pweights' argument were supplied; using ",
                    "'pweights' and ignoring the weights column."),
                zh=paste0("\u6570\u636e\u4e2d\u5e26\u6709\u6743\u91cd\u5217\uff0c\u540c\u65f6\u53c8\u663e\u5f0f\u63d0\u4f9b\u4e86 'pweights' \u53c2\u6570\uff1b\u5c06\u4f7f\u7528 'pweights'\uff0c\u5ffd\u7565\u6743\u91cd\u5217\u3002"),
                fix_en="Supply only one of the two.",
                fix_zh="\u8bf7\u53ea\u63d0\u4f9b\u5176\u4e2d\u4e00\u79cd\u6743\u91cd\u3002",
                class="irtc_warning_estimation")
        } else {
            fit_args$pweights <- data_obj$weights
        }
    }
    mod <- tryCatch(
        do.call(fit_fun, fit_args),
        error=function(e) {
            if (inherits(e, "irtc_error")) stop(e)
            irtc_stop(code="E408",
                en=paste0("Estimation failed: ", conditionMessage(e)),
                zh=paste0("\u6a21\u578b\u4f30\u8ba1\u5931\u8d25\uff1a", conditionMessage(e)),
                fix_en=paste0("Typical causes: too few persons, extreme ",
                    "items, or non-convergence. Try irtc_check_data() ",
                    "first; for convergence issues increase ",
                    "control=list(maxiter=...)."),
                fix_zh=paste0("\u5e38\u89c1\u539f\u56e0\uff1a\u6837\u672c\u592a\u5c11\u3001\u9898\u76ee\u8fc7\u4e8e\u6781\u7aef\u6216\u4e0d\u6536\u655b\u3002",
                    "\u8bf7\u5148\u8fd0\u884c irtc_check_data()\uff1b\u82e5\u4e3a\u6536\u655b\u95ee\u9898\uff0c\u53ef\u589e\u5927 ",
                    "control=list(maxiter=...)\u3002"),
                class="irtc_error_estimation",
                data=list(parent_message=conditionMessage(e)))
        }
    )

    ## --- enrich with usability results ---------------------------------------
    usability <- list(model=model, data_log=data_obj$log,
        check=check_obj, removed_items=bad_items, q=qobj)
    if (quality) {
        usability$ctt <- tryCatch(irtc_ctt(resp), error=function(e) NULL)
        usability$itemfit <- tryCatch(irtc_itemfit(mod, resp=resp),
            error=function(e) NULL)
        usability$quality <- tryCatch(irtc_quality(mod, resp=resp),
            error=function(e) NULL)
    }
    mod$usability <- usability
    mod
}
