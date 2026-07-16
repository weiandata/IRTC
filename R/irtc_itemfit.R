# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_itemfit.R
## Part of the IRTC package
## Residual-based item fit: infit and outfit mean squares with
## Wilson-Hilferty t statistics, evaluated at the EAP person estimates.
## Works for both the grid and the streaming engine (AXsi is reconstructed
## from the step parameters when the streaming engine did not store it).

irtc_itemfit <- function(mod, resp=NULL)
{
    if (!inherits(mod, "irtc")) {
        irtc_stop(code="E401",
            en="'mod' must be an irtc model object (from irtc() or irtc.mml).",
            zh="\u53c2\u6570 'mod' \u5fc5\u987b\u662f irtc \u6a21\u578b\u5bf9\u8c61\uff08\u7531 irtc() \u6216 irtc.mml \u4ea7\u751f\uff09\u3002",
            fix_en="Fit a model first, e.g. mod <- irtc(data, model=\"1PL\").",
            fix_zh="\u8bf7\u5148\u4f30\u8ba1\u6a21\u578b\uff0c\u4f8b\u5982 mod <- irtc(data, model=\"1PL\")\u3002",
            class="irtc_error_input")
    }
    if (is.null(resp)) resp <- mod$resp
    if (is.null(resp)) {
        irtc_stop(code="E402",
            en=paste0("The model object does not store the response data",
                " (streaming engine); supply it via the 'resp' argument."),
            zh=paste0("\u6a21\u578b\u5bf9\u8c61\u4e2d\u6ca1\u6709\u4fdd\u5b58\u4f5c\u7b54\u6570\u636e\uff08streaming \u5f15\u64ce\uff09\uff1b",
                "\u8bf7\u901a\u8fc7 'resp' \u53c2\u6570\u63d0\u4f9b\u3002"),
            fix_en="Call irtc_itemfit(mod, resp=your_data).",
            fix_zh="\u8bf7\u8c03\u7528 irtc_itemfit(mod, resp=\u4f60\u7684\u6570\u636e)\u3002",
            class="irtc_error_input")
    }
    resp <- as.matrix(as.data.frame(resp))
    theta <- irtc_extract_eap(mod)
    if (nrow(theta) != nrow(resp)) {
        irtc_stop(code="E403",
            en=paste0("'resp' has ", nrow(resp), " rows but the model has ",
                nrow(theta), " persons."),
            zh=paste0("'resp' \u6709 ", nrow(resp), " \u884c\uff0c\u4f46\u6a21\u578b\u4e2d\u6709 ",
                nrow(theta), " \u4e2a\u6837\u672c\u3002"),
            fix_en="Pass the same data set that the model was fitted on.",
            fix_zh="\u8bf7\u4f20\u5165\u4e0e\u6a21\u578b\u4f30\u8ba1\u65f6\u76f8\u540c\u7684\u6570\u636e\u3002",
            class="irtc_error_input")
    }
    AXsi <- irtc_extract_axsi(mod)
    B <- mod$B
    n_items <- dim(B)[1L]
    maxK <- dim(B)[2L]
    if (ncol(resp) != n_items) {
        irtc_stop(code="E403",
            en=paste0("'resp' has ", ncol(resp), " columns but the model has ",
                n_items, " items."),
            zh=paste0("'resp' \u6709 ", ncol(resp), " \u5217\uff0c\u4f46\u6a21\u578b\u4e2d\u6709 ",
                n_items, " \u4e2a\u9898\u76ee\u3002"),
            fix_en="Pass the same data set that the model was fitted on.",
            fix_zh="\u8bf7\u4f20\u5165\u4e0e\u6a21\u578b\u4f30\u8ba1\u65f6\u76f8\u540c\u7684\u6570\u636e\u3002",
            class="irtc_error_input")
    }

    outfit <- infit <- outfit_t <- infit_t <- rep(NA_real_, n_items)
    for (j in seq_len(n_items)) {
        obs <- resp[, j]
        use <- !is.na(obs)
        if (sum(use) < 2L) next
        ## categories actually defined for this item (mixed maxK data sets
        ## have NA intercepts in the unused categories)
        k_use <- which(is.finite(AXsi[j, ]))
        if (length(k_use) < 2L) next
        scores <- k_use - 1L
        ## category logits at each person's EAP: AXsi[j,k] + B[j,k,] . theta
        eta <- matrix(AXsi[j, k_use], nrow=sum(use), ncol=length(k_use),
            byrow=TRUE)
        for (d in seq_len(dim(B)[3L])) {
            eta <- eta + outer(theta[use, d], B[j, k_use, d])
        }
        eta <- eta - apply(eta, 1L, max)
        prob <- exp(eta)
        prob <- prob / rowSums(prob)
        e1 <- as.vector(prob %*% scores)
        e2 <- as.vector(prob %*% scores^2)
        e4 <- as.vector(prob %*% scores^4)
        w <- pmax(e2 - e1^2, 1e-10)
        ## kurtosis term C = E[(X - E)^4]
        e3 <- as.vector(prob %*% scores^3)
        cvar <- e4 - 4 * e1 * e3 + 6 * e1^2 * e2 - 3 * e1^4
        z2 <- (obs[use] - e1)^2 / w
        n_use <- sum(use)
        outfit[j] <- mean(z2)
        infit[j] <- sum((obs[use] - e1)^2) / sum(w)
        ## Wilson-Hilferty transformation to approximate t statistics
        q2_out <- sum(cvar / w^2 - 1) / n_use^2
        q2_in <- sum(cvar - w^2) / sum(w)^2
        if (is.finite(q2_out) && q2_out > 0) {
            q <- sqrt(q2_out)
            outfit_t[j] <- (outfit[j]^(1 / 3) - 1) * (3 / q) + (q / 3)
        }
        if (is.finite(q2_in) && q2_in > 0) {
            q <- sqrt(q2_in)
            infit_t[j] <- (infit[j]^(1 / 3) - 1) * (3 / q) + (q / 3)
        }
    }

    out <- data.frame(
        item=colnames(resp),
        N=colSums(!is.na(resp)),
        outfit=round(outfit, 4),
        outfit_t=round(outfit_t, 3),
        infit=round(infit, 4),
        infit_t=round(infit_t, 3),
        stringsAsFactors=FALSE, row.names=NULL
    )
    class(out) <- c("irtc_itemfit", "data.frame")
    out
}

## Extract the person EAP estimates as an N x D matrix.
irtc_extract_eap <- function(mod)
{
    person <- mod$person
    eap_cols <- grep("^EAP(\\.Dim[0-9]+)?$", colnames(person), value=TRUE)
    if (length(eap_cols) == 0L) {
        eap_cols <- grep("^EAP", colnames(person), value=TRUE)
        eap_cols <- eap_cols[!grepl("^SD\\.", eap_cols)]
    }
    if (length(eap_cols) == 0L) {
        irtc_stop(code="E404",
            en="No EAP columns found in the model's person table.",
            zh="\u6a21\u578b\u7684 person \u8868\u4e2d\u627e\u4e0d\u5230 EAP \u5217\u3002",
            fix_en="Refit the model; person estimates may have been disabled.",
            fix_zh="\u8bf7\u91cd\u65b0\u4f30\u8ba1\u6a21\u578b\uff1b\u53ef\u80fd\u5173\u95ed\u4e86\u4e2a\u4eba\u80fd\u529b\u4f30\u8ba1\u3002",
            class="irtc_error_input")
    }
    as.matrix(person[, eap_cols, drop=FALSE])
}

## AXsi matrix (items x categories); reconstruct it from the step parameters
## when the streaming engine did not store it.
irtc_extract_axsi <- function(mod)
{
    if (!is.null(mod$AXsi)) {
        return(as.matrix(mod$AXsi))
    }
    n_items <- mod$nitems
    maxK <- mod$maxK
    xsi <- mod$xsi$xsi
    if (is.null(xsi) || length(xsi) != n_items * (maxK - 1L)) {
        irtc_stop(code="E405",
            en="Cannot reconstruct item intercepts (AXsi) from this model.",
            zh="\u65e0\u6cd5\u4ece\u8be5\u6a21\u578b\u5bf9\u8c61\u91cd\u5efa\u9898\u76ee\u622a\u8ddd\uff08AXsi\uff09\u3002",
            fix_en="Refit with the default grid engine (engine=\"grid\").",
            fix_zh="\u8bf7\u4f7f\u7528\u9ed8\u8ba4 grid \u5f15\u64ce\u91cd\u65b0\u4f30\u8ba1\uff08engine=\"grid\"\uff09\u3002",
            class="irtc_error_input")
    }
    AXsi <- matrix(0, nrow=n_items, ncol=maxK)
    for (j in seq_len(n_items)) {
        idx <- ((j - 1L) * (maxK - 1L) + 1L):(j * (maxK - 1L))
        AXsi[j, 2L:maxK] <- -xsi[idx]
    }
    AXsi
}

print.irtc_itemfit <- function(x, lang=irtc_lang(), ...)
{
    cat(irtc_tr("Item fit statistics (infit/outfit at EAP estimates)",
        "\u9898\u76ee\u62df\u5408\u7edf\u8ba1\uff08\u57fa\u4e8e EAP \u7684 infit/outfit\uff09", lang), "\n", sep="")
    print.data.frame(x, row.names=FALSE)
    invisible(x)
}
