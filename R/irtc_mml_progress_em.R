# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_progress_em.R

irtc_mml_progress_em <- function(progress, deviance, deviance_change, iter,
        rel_deviance_change, xsi_change, beta_change, variance_change, B_change,
        is_latreg=FALSE, is_mml_3pl=FALSE, guess_change=0,
        skillspace="normal", delta_change=0, digits_pars=6, devch,
        penalty_xsi=0, is_np=FALSE, np_change=NULL, par_reg_penalty=NULL,
        n_reg=NULL, AIC=NULL, n_est=NULL, n_reg_max=NULL)
{
    if (!progress) return(invisible(NULL))

    objective_label <- if (penalty_xsi == 0) "Deviance" else "Log posterior"
    cat(paste("\n ", objective_label, "=", round(deviance, 4)))

    is_group_lasso <- !is.null(par_reg_penalty)
    if (!is_group_lasso) {
        if (iter > 1) {
            cat(" | Absolute change:", round(devch, 4))
            cat(" | Relative change:", round(rel_deviance_change, 8))
            if (devch < 0) {
                cat("\n!!! Deviance increases!                                        !!!!")
                cat("\n!!! Choose maybe fac.oldxsi > 0 and/or increment.factor > 1    !!!!")
            }
        }
    } else {
        penalty_value <- sum(par_reg_penalty)
        cat("\n  Number of estimated parameters:", n_est)
        cat("\n  Penalty function value:", round(penalty_value, digits_pars))
        cat("\n  Number of regularized parameters:", sum(n_reg))
        cat(paste0(" (out of ", n_reg_max, ")"))
        cat(
            "\n  Optimization function value:",
            round(sum(deviance + penalty_value), digits_pars)
        )
        cat("\n  AIC:", sum(AIC))
    }

    if (!is_latreg) {
        cat(
            "\n  Maximum item intercept parameter change:",
            round(xsi_change, digits_pars)
        )
        cat(
            "\n  Maximum item slope parameter change:",
            round(B_change, digits_pars)
        )
    }
    if (is_mml_3pl) {
        cat(
            "\n  Maximum item guessing parameter change:",
            round(guess_change, digits_pars)
        )
    }
    if (is_np) {
        cat("\n  Maximum item parameter change:", round(np_change, digits_pars))
    }
    if (skillspace == "normal") {
        cat(
            "\n  Maximum regression parameter change:",
            round(beta_change, digits_pars)
        )
        cat(
            "\n  Maximum variance parameter change:",
            round(variance_change, digits_pars)
        )
    } else {
        cat("\n  Maximum delta parameter change:", round(delta_change, digits_pars))
    }
    cat("\n")
    utils::flush.console()
}
