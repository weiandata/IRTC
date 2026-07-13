# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: anova_irtc.R

anova_irtc <- function(object, ...)
{
    models <- list(object, ...)
    if (length(models) != 2) {
        stop("anova method can only be applied for comparison of two models.\n")
    }
    labels <- paste(match.call())[-1]
    model_row <- function(model, label) {
        log_likelihood <- model$deviance / -2
        data.frame(
            Model=label,
            loglike=log_likelihood,
            Deviance=-2 * log_likelihood,
            Npars=sum(model$ic$Npars),
            AIC=model$ic$AIC,
            BIC=model$ic$BIC
        )
    }

    comparison <- rbind(
        model_row(models[[1]], labels[1]),
        model_row(models[[2]], labels[2])
    )
    comparison <- comparison[order(comparison$Npars), ]
    comparison$Chisq <- NA
    comparison$df <- NA
    comparison$p <- NA

    comparison[1, "Chisq"] <- comparison[1, "Deviance"] - comparison[2, "Deviance"]
    comparison[1, "df"] <- abs(comparison[1, "Npars"] - comparison[2, "Npars"])
    comparison[1, "p"] <- round(
        stats::pchisq(
            comparison[1, "Chisq"],
            df=comparison[1, "df"],
            lower.tail=FALSE
        ),
        5
    )

    irtc_round_data_frame_print(
        obji=comparison, from=2, digits=5, rownames_null=TRUE
    )
    invisible(comparison)
}

anova.irtc <- anova_irtc
