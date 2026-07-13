# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: summary_irtc.R

summary_irtc <- function(object, file=NULL, ...)
{
    irtc_osink(file=file)

    is_latent_regression <- inherits(object, "irtc.latreg")
    if (is_latent_regression) {
        object$irtmodel <- "irtc.latreg"
    }

    separator <- irtc_summary_display()
    cat(separator)
    irtc_print_package_rsession(pack="IRTC")
    irtc_print_computation_time(object=object)

    cat("Multidimensional Item Response Model in IRTC \n\n")
    model_name <- object$irtmodel
    cat("IRT Model:", model_name)
    irtc_print_call(object$CALL)

    cat(separator)
    cat("Number of iterations", "=", object$iter, "\n")

    control <- object$control
    if (control$snodes == 0) {
        cat("Numeric integration with", dim(object$theta)[1], "integration points\n")
    } else {
        if (control$QMC) {
            cat("Quasi Monte Carlo integration with", dim(object$theta)[1], "integration points\n")
        } else {
            cat("Monte Carlo integration with", dim(object$theta)[1], "integration points\n")
        }
    }

    likelihood_digits <- 2
    cat("\nDeviance", "=", round(object$deviance, likelihood_digits), "\n")
    cat("Log likelihood", "=", round(object$ic$loglike, likelihood_digits), "\n")
    cat("Number of persons", "=", object$nstud, "\n")
    cat("Number of persons used", "=", object$ic$n, "\n")

    if (!is_latent_regression) {
        if (!is.null(object$formulaA)) {
            cat("Number of generalized items", "=", object$nitems, "\n")
            cat("Number of items", "=", ncol(object$resp_orig), "\n")
        } else {
            cat("Number of items", "=", object$nitems, "\n")
        }
    }

    cat("Number of estimated parameters", "=", object$ic$Npars, "\n")
    if (!is_latent_regression) {
        cat("    Item threshold parameters", "=", object$ic$Nparsxsi, "\n")
        cat("    Item slope parameters", "=", object$ic$NparsB, "\n")
    }
    cat("    Regression parameters", "=", object$ic$Nparsbeta, "\n")
    cat("    Variance/covariance parameters", "=", object$ic$Nparscov, "\n\n")

    irtc_summary_print_ic(object=object, digits_values=likelihood_digits)

    cat(separator)
    cat("EAP Reliability\n")
    print(round(object$EAP.rel, 3))

    cat(separator)
    cat("Covariances and Variances\n")
    variance <- object$variance
    if (object$G > 1) {
        grouped_variance <- stats::aggregate(variance, list(object$group), mean)
        variance <- grouped_variance[, 2]
    }
    displayed_variance <- round(variance, 3)
    if (object$G > 1) {
        names(displayed_variance) <- paste0("Group", object$groups)
    }
    print(displayed_variance)

    cat(separator)
    cat("Correlations and Standard Deviations (in the diagonal)\n")
    if (object$G > 1) {
        correlation_display <- sqrt(variance)
        names(correlation_display) <- paste0("Group", object$groups)
    } else {
        correlation_display <- stats::cov2cor(variance)
        diag(correlation_display) <- sqrt(diag(variance))
    }
    irtc_round_data_frame_print(obji=correlation_display, digits=3)

    cat(separator)
    cat("Regression Coefficients\n")
    irtc_round_data_frame_print(obji=object$beta, digits=5)
    summary_irtc_print_latreg_stand(object=object, digits_stand=4)

    if (!is_latent_regression) {
        cat(separator)
        cat("Item Parameters -A*Xsi\n")
        irtc_round_data_frame_print(
            obji=object$item,
            from=2,
            to=ncol(object$item),
            digits=3,
            rownames_null=TRUE
        )

        if (!is.null(object$formulaA)) {
            cat("\nItem Facet Parameters Xsi\n")
            if (sum(object$xsi == 99) > 0) {
                cat("\nSome item xsi parameters are not estimable ")
                cat(" which is indicated by values of 99\n\n")
            }
            if (object$PSF) {
                cat("\nA pseudo facet 'psf' with zero effects with all zero effects\n")
                cat("was created because of non-unique person-facet combinations.\n\n")
            }
            irtc_round_data_frame_print(obji=object$xsi.facets, from=3, digits=3)
        }
        if (object$maxK > 2 || object$printxsi) {
            cat("\nItem Parameters Xsi\n")
            irtc_round_data_frame_print(obji=object$xsi, from=1, digits=3)
        }
        if (!is.null(object$item_irt)) {
            cat("\nItem Parameters in IRT parameterization\n")
            irtc_round_data_frame_print(obji=object$item_irt, from=2, digits=3)
        }

        if (object$irtmodel == "efa") {
            cat(separator)
            cat("\nStandardized Factor Loadings Oblimin Rotation\n")
            print(object$efa.oblimin)
        }

        if (object$irtmodel %in% c("bifactor1", "bifactor2", "efa")) {
            cat(separator)
            if (model_name == "efa") {
                cat("\nStandardized Factor Loadings (Schmid Leimann transformation)\n")
                loadings <- object$B.SL
            } else {
                cat("\nStandardized Factor Loadings (Bifactor Model)\n")
                loadings <- object$B.stand
            }
            irtc_round_data_frame_print(obji=loadings, digits=3)
            measures <- object$meas
            cat("\nDimensionality/Reliability Statistics\n\n")
            cat("ECV", "=", round(measures["ECV"], 3), "\n")
            cat("Omega Asymptotical", "=", round(measures["omega_a"], 3), "\n")
            cat("Omega Total", "=", round(measures["omega_t"], 3), "\n")
            cat("Omega Hierarchical", "=", round(measures["omega_h"], 3), "\n")
            if (object$maxK == 2) {
                cat("Omega Total (GY)", "=", round(measures["omega_tot_diff"], 3), "\n")
                cat("  Omega Total GY (Green & Yang, 2009) includes item difficulties\n")
                cat("  and estimates the reliability of the sum score.\n")
            }
        }
    }

    irtc_csink(file=file)
}

summary.irtc <- summary_irtc
