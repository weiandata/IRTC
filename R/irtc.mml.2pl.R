# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc.mml.2pl.R
## Part of the IRTC package

irtc.mml.2pl <- function( resp, Y=NULL, group=NULL,  irtmodel="2PL",
                 formulaY=NULL, dataY=NULL,
                 ndim=1, pid=NULL,
                 xsi.fixed=NULL,  xsi.inits=NULL,
                 beta.fixed=NULL, beta.inits=NULL,
                 variance.fixed=NULL, variance.inits=NULL,
                 est.variance=FALSE,
                 A=NULL, B=NULL, B.fixed=NULL,
                 Q=NULL, est.slopegroups=NULL, E=NULL,
                 gamma.init=NULL,
                 pweights=NULL,
                 userfct.variance=NULL, variance.Npars=NULL,
                 item.elim=TRUE,     verbose=TRUE,
                 method=c("auto","grid","streaming"),
                 control=list()
                 )
{
    started_at <- Sys.time()
    CALL <- match.call()
    display_rule <- "....................................................\n"

    increment.factor <- progress <- nodes <- snodes <- ridge <- xsi.start0 <- QMC <- NULL
    maxiter <- conv <- convD <- min.variance <- max.increment <- Msteps <- convM <- NULL
    R <- trim_increment <- n_threads <- fast <- fast_threshold <- NULL
    fac.oldxsi <- acceleration <- NULL

    args_CALL <- as.list(sys.call())
    if (!irtc_in_names_list(list=control, variable="progress")) {
        control$progress <- verbose
    }
    printxsi <- !is.null(A)

    control_environment <- environment()
    control_result <- irtc_mml_control_list_define(
        control=control, envir=control_environment,
        irtc_fct="irtc.mml.2pl"
    )
    con <- control_result$con
    con1a <- control_result$con1a

    resp <- as.matrix(resp)
    resp0 <- resp <- add.colnames.resp(resp)

    method <- match.arg(method)
    routing_people <- nrow(resp)
    routing_items <- ncol(resp)
    routing_maxK <- max(resp, na.rm=TRUE) + 1L
    routing_nodes <- length(con$nodes)
    advanced_specification <- (
        !is.null(A) || !is.null(B) || !is.null(B.fixed) ||
        !is.null(est.slopegroups) || !is.null(E) || !is.null(xsi.fixed) ||
        !is.null(variance.fixed)
    )
    has_covariates <- !is.null(Y) || !is.null(group) || !is.null(pweights)
    model_supported_by_streaming <- irtmodel %in% c("2PL", "GPCM")

    if (!is.null(Q)) {
        routing_dimensions <- ncol(Q)
        nonzero_dimensions <- rowSums(Q != 0)
        simple_structure <- (
            all(nonzero_dimensions == 1) && model_supported_by_streaming &&
            !advanced_specification
        )
        dimension_of_item <- if (simple_structure) {
            apply(Q != 0, 1, which.max)
        } else {
            NULL
        }
    } else {
        routing_dimensions <- ndim
        simple_structure <- (
            ndim == 1 && model_supported_by_streaming && !advanced_specification
        )
        dimension_of_item <- if (simple_structure) {
            rep(1L, routing_items)
        } else {
            NULL
        }
    }

    pattern_count <- 1L
    if (has_covariates && simple_structure) {
        routing_Y <- if (!is.null(Y)) {
            round(as.matrix(Y), 6)
        } else {
            matrix(0, routing_people, 1)
        }
        routing_group <- if (!is.null(group)) group else rep(0L, routing_people)
        pattern_count <- nrow(unique(cbind(routing_Y, routing_group)))
    }

    grid_routing <- irtc_route_decide(
        method, routing_people, routing_items, routing_dimensions,
        routing_nodes, routing_maxK, simple_structure, has_covariates,
        n_patterns=pattern_count
    )

    if (grid_routing$engine == "streaming") {
        if (!is.null(Y) && anyNA(Y)) {
            stop(
                "Y contains missing values; resolve them before estimation.",
                call.=FALSE
            )
        }
        if (!is.null(group) && anyNA(group)) {
            stop(
                "group contains missing values; resolve them before estimation.",
                call.=FALSE
            )
        }
        if (!is.null(pweights) && anyNA(pweights)) {
            stop(
                "pweights contains missing values; resolve them before estimation.",
                call.=FALSE
            )
        }

        streaming_tolerance <- list()
        for (metric in c("deviance", "eap", "moment", "par")) {
            tolerance_name <- paste0("tol_", metric)
            if (!is.null(con[[tolerance_name]])) {
                streaming_tolerance[[metric]] <- con[[tolerance_name]]
            }
        }

        result <- irtc_proto_run_and_build(
            resp, dimension_of_item, maxK=routing_maxK, Q=routing_nodes,
            nodes=con$nodes, irtmodel=irtmodel, n_threads=con$n_threads,
            squarem=TRUE, adaptive=FALSE, fast=isTRUE(con$fast),
            mass_budget=if (is.null(con$mass_budget)) 1e-3 else con$mass_budget,
            burnin=if (is.null(con$burnin)) 3L else con$burnin,
            verify=if (is.null(con$verify)) "stratified" else con$verify,
            verify_n=if (is.null(con$verify_n)) 3000 else con$verify_n,
            verify_seed=if (is.null(con$verify_seed)) 1 else con$verify_seed,
            refine=isTRUE(con$refine), tol=streaming_tolerance,
            Y=Y, group=group, pweights=pweights,
            group_structure=if (is.null(con$group_structure)) {
                "full"
            } else {
                con$group_structure
            },
            reg=con$reg, CALL=CALL, control=con
        )
        result$routing <- grid_routing
        if (verbose) {
            cat(sprintf(
                "[irtc] engine: %s (%s)\n",
                grid_routing$engine, grid_routing$reason
            ))
        }
        return(result)
    }

    if (progress) {
        cat(display_rule)
        cat("Processing Data     ", paste(Sys.time()), "\n")
        utils::flush.console()
    }
    if (!is.null(group)) {
        con1a$QMC <- QMC <- FALSE
        con1a$snodes <- snodes <- 0
    }
    if (irtmodel == "PCM2" && is.null(A)) {
        A <- .A.PCM2(resp)
    }
    if (!is.null(variance.fixed)) {
        est.variance <- TRUE
    }

    nitems <- ncol(resp)
    nstud <- nrow(resp)
    nstud100 <- sum(1 * (rowSums(1 - is.na(resp)) > 0))
    if (is.null(pweights)) {
        pweights <- rep(1, nstud)
    }
    if (progress) {
        cat("    * Response Data:", nstud, "Persons and ", nitems, "Items \n")
        utils::flush.console()
    }
    if (is.null(pid)) {
        pid <- seq(1, nstud)
    }

    pweights0 <- pweights
    pweights <- nstud * pweights / sum(pweights)
    pweightsM <- outer(pweights, rep(1, nitems))

    if (!is.null(B)) {
        ndim <- dim(B)[3]
    }
    if (!is.null(Q)) {
        ndim <- dim(Q)[2]
    }

    betaConv <- FALSE
    varConv <- FALSE
    nnodes <- length(nodes)^ndim
    if (snodes > 0) {
        nnodes <- snodes
    }
    irtc_mml_progress_proc_nodes(
        progress=progress, snodes=snodes, nnodes=nnodes,
        skillspace="normal", QMC=QMC
    )

    maxK <- max(resp, na.rm=TRUE) + 1
    maxKi <- NULL
    if (!item.elim) {
        maxKi <- rep(maxK - 1, ncol(resp))
    }

    design_result <- designMatrices(
        modeltype="PCM", maxKi=maxKi, resp=resp,
        A=A, B=B, Q=Q, R=R, ndim=ndim
    )
    A <- design_result$A
    B <- design_result$B
    cA <- design_result$flatA
    cA[is.na(cA)] <- 0
    if (progress) {
        cat("    * Created Design Matrices   (", paste(Sys.time()), ")\n")
        utils::flush.console()
    }
    design_result <- NULL

    B_orig <- B
    np <- dim(A)[[3]]
    xsi_index_result <- irtc_mml_proc_est_xsi_index(A, xsi.inits, xsi.fixed)
    np <- xsi_index_result$np
    xsi <- xsi_index_result$xsi
    est.xsi.index0 <- est.xsi.index <- xsi_index_result$est.xsi.index

    variance_result <- irtc_mml_inits_variance(
        variance.inits=variance.inits, ndim=ndim,
        variance.fixed=variance.fixed
    )
    variance <- variance_result$variance

    group_result <- irtc_mml_inits_groups(group=group)
    G <- group_result$G
    groups <- group_result$groups
    group <- group_result$group
    var.indices <- group_result$var.indices

    regression_result <- irtc_mml_inits_beta(
        Y=Y, formulaY=formulaY, dataY=dataY, G=G, group=group,
        groups=groups, nstud=nstud, pweights=pweights, ridge=ridge,
        beta.fixed=beta.fixed, xsi.fixed=xsi.fixed, constraint="cases",
        ndim=ndim, beta.inits=beta.inits
    )
    Y <- regression_result$Y
    nullY <- regression_result$nullY
    formulaY <- regression_result$formulaY
    nreg <- regression_result$nreg
    W <- regression_result$W
    YYinv <- regression_result$YYinv
    beta.fixed <- regression_result$beta.fixed
    beta <- regression_result$beta

    response_result <- irtc_mml_proc_response_indicators(
        resp=resp, nitems=nitems
    )
    resp <- response_result$resp
    resp.ind <- response_result$resp.ind
    resp.ind.list <- response_result$resp.ind.list
    nomiss <- response_result$nomiss

    AXsi <- matrix(0, nrow=nitems, ncol=maxK)
    parameter_index_result <- irtc_mml_proc_xsi_parameter_index_A(A=A, np=np)
    indexIP <- parameter_index_result$indexIP
    indexIP.list <- parameter_index_result$indexIP.list
    indexIP.list2 <- parameter_index_result$indexIP.list2
    indexIP.no <- parameter_index_result$indexIP.no

    statistic_result <- irtc_mml_sufficient_statistics(
        nitems=nitems, maxK=maxK, resp=resp, resp.ind=resp.ind,
        pweights=pweights, cA=cA, progress=progress
    )
    ItemScore <- statistic_result$ItemScore
    cResp <- statistic_result$cResp
    col.index <- statistic_result$col.index

    xsi_result <- irtc_mml_inits_xsi(
        A=A, resp.ind=resp.ind, ItemScore=ItemScore, xsi.inits=xsi.inits,
        xsi.fixed=xsi.fixed, est.xsi.index=est.xsi.index,
        pweights=pweights, xsi.start0=xsi.start0, xsi=xsi, resp=resp
    )
    xsi <- xsi_result$xsi
    personMaxA <- xsi_result$personMaxA
    ItemMax <- xsi_result$ItemMax
    equal.categ <- xsi_result$equal.categ

    xsi.min.deviance <- xsi
    beta.min.deviance <- beta
    variance.min.deviance <- variance

    node_result <- irtc_mml_create_nodes(
        snodes=snodes, nodes=nodes, ndim=ndim, QMC=QMC
    )
    theta <- node_result$theta
    theta2 <- node_result$theta2
    thetawidth <- node_result$thetawidth
    theta0.samp <- node_result$theta0.samp
    thetasamp.density <- node_result$thetasamp.density

    deviance <- 0
    deviance.history <- irtc_deviance_history_init(maxiter=maxiter)
    iter <- 0
    a02 <- a1 <- 999
    a4 <- 999
    basispar <- NULL

    if (irtmodel == "GPCM.design") {
        slope_basis_count <- ncol(E)
        basispar <- matrix(1, slope_basis_count, ndim)
        initial_basis <- solve(t(E) %*% E, t(E) %*% rep(1, nitems))
        if (!is.null(gamma.init)) {
            initial_basis <- gamma.init
        }
        for (dimension in 1:ndim) {
            basispar[, dimension] <- initial_basis
        }
    }

    slope_models <- c("2PL", "GPCM", "GPCM.design", "2PL.groups", "GPCM.groups")
    if (irtmodel %in% slope_models && !is.null(B.fixed)) {
        B[B.fixed[, 1:3, drop=FALSE]] <- B.fixed[, 4]
        B_orig[B.fixed[, 1:3, drop=FALSE]] <- 0
    }

    simplify_result <- irtc_mml_proc_unidim_simplify(
        Y=Y, A=A, G=G, beta.fixed=beta.fixed
    )
    unidim_simplify <- simplify_result$unidim_simplify
    YSD <- simplify_result$YSD
    Avector <- simplify_result$Avector

    acceleration_result <- irtc_acceleration_inits(
        acceleration=acceleration, G=G, xsi=xsi,
        variance=variance, B=B, irtmodel=irtmodel
    )
    xsi_acceleration <- acceleration_result$xsi_acceleration
    variance_acceleration <- acceleration_result$variance_acceleration
    B_acceleration <- acceleration_result$B_acceleration

    irtc_mml_warning_message_multiple_group_models(ndim=ndim, G=G)
    maxcat <- irtc_rcpp_mml_maxcat(A=as.vector(A), dimA=dim(A))
    se.xsi <- 0 * xsi
    se.B <- 0 * B

    hwt.min <- 0
    rprobs.min <- 0
    AXsi.min <- 0
    B.min <- 0
    deviance.min <- 1E100
    itemwt.min <- 0
    se.xsi.min <- se.xsi
    se.B.min <- se.B
    B_change <- 0
    mpr <- round(seq(1, np, len=10))

    while (((!betaConv | !varConv) | ((a1 > conv) | (a4 > conv) |
            (a02 > convD))) & (iter < maxiter)) {
        iter <- iter + 1
        irtc_mml_progress_em0(progress=progress, iter=iter, disp=display_rule)

        if (snodes > 0) {
            stochastic_result <- irtc_mml_update_stochastic_nodes(
                theta0.samp=theta0.samp, variance=variance,
                snodes=snodes, beta=beta, theta=theta
            )
            theta <- stochastic_result$theta
            theta2 <- stochastic_result$theta2
            thetasamp.density <- stochastic_result$thetasamp.density
        }
        olddeviance <- deviance

        probability_result <- irtc_mml_calc_prob(
            iIndex=1:nitems, A=A, AXsi=AXsi, B=B, xsi=xsi,
            theta=theta, nnodes=nnodes, maxK=maxK, recalc=TRUE,
            maxcat=maxcat, use_rcpp=TRUE
        )
        rprobs <- probability_result$rprobs
        AXsi <- probability_result$AXsi

        gwt <- irtc_stud_prior(
            theta=theta, Y=Y, beta=beta, variance=variance,
            nstud=nstud, nnodes=nnodes, ndim=ndim, YSD=YSD,
            unidim_simplify=unidim_simplify, snodes=snodes
        )
        res.hwt <- irtc_calc_posterior(
            rprobs=rprobs, gwt=gwt, resp=resp, nitems=nitems,
            resp.ind.list=resp.ind.list, normalization=TRUE,
            thetasamp.density=thetasamp.density, snodes=snodes,
            resp.ind=resp.ind, avoid.zerosum=TRUE, n_threads=n_threads,
            fast=fast, fast_threshold=fast_threshold
        )
        hwt <- res.hwt$hwt

        mstep_regression <- irtc_mml_mstep_regression(
            resp=resp, hwt=hwt, resp.ind=resp.ind,
            pweights=pweights, pweightsM=pweightsM, Y=Y,
            theta=theta, theta2=theta2, YYinv=YYinv, ndim=ndim,
            nstud=nstud, beta.fixed=beta.fixed, variance=variance,
            Variance.fixed=variance.fixed, group=group, G=G,
            snodes=snodes, thetasamp.density=thetasamp.density,
            nomiss=nomiss, iter=iter, min.variance=min.variance,
            userfct.variance=userfct.variance,
            variance_acceleration=variance_acceleration,
            est.variance=est.variance, beta=beta
        )
        beta <- mstep_regression$beta
        variance <- mstep_regression$variance
        itemwt <- mstep_regression$itemwt
        variance_acceleration <- mstep_regression$variance_acceleration
        variance_change <- mstep_regression$variance_change
        beta_change <- mstep_regression$beta_change
        if (beta_change < conv) {
            betaConv <- TRUE
        }
        if (variance_change < conv) {
            varConv <- TRUE
        }

        slope_statistics <- irtc_mml_2pl_sufficient_statistics_item_slope(
            hwt=hwt, theta=theta, cResp=cResp, pweights=pweights,
            maxK=maxK, nitems=nitems, ndim=ndim
        )
        thetabar <- slope_statistics$thetabar
        cB_obs <- slope_statistics$cB_obs
        B_obs <- slope_statistics$B_obs

        intercept_result <- irtc_mml_mstep_intercept(
            A=A, xsi=xsi, AXsi=AXsi, B=B, theta=theta,
            nnodes=nnodes, maxK=maxK, Msteps=Msteps, rprobs=rprobs,
            np=np, est.xsi.index0=est.xsi.index0, itemwt=itemwt,
            indexIP.no=indexIP.no, indexIP.list2=indexIP.list2,
            Avector=Avector, max.increment=max.increment,
            xsi.fixed=xsi.fixed, fac.oldxsi=fac.oldxsi,
            ItemScore=ItemScore, convM=convM, progress=progress,
            nitems=nitems, iter=iter, increment.factor=increment.factor,
            xsi_acceleration=xsi_acceleration,
            trim_increment=trim_increment, maxcat=maxcat
        )
        xsi <- intercept_result$xsi
        se.xsi <- intercept_result$se.xsi
        max.increment <- intercept_result$max.increment
        xsi_acceleration <- intercept_result$xsi_acceleration
        xsi_change <- intercept_result$xsi_change

        if (irtmodel %in% slope_models) {
            slope_result <- irtc_mml_2pl_mstep_slope(
                B_orig=B_orig, B=B, B_obs=B_obs, B.fixed=B.fixed,
                max.increment=max.increment, nitems=nitems, A=A,
                AXsi=AXsi, xsi=xsi, theta=theta, nnodes=nnodes,
                maxK=maxK, itemwt=itemwt, Msteps=Msteps, ndim=ndim,
                convM=convM, irtmodel=irtmodel, progress=progress,
                est.slopegroups=est.slopegroups, E=E, basispar=basispar,
                se.B=se.B, equal.categ=equal.categ,
                B_acceleration=B_acceleration,
                trim_increment=trim_increment, iter=iter,
                maxcat=maxcat, use_rcpp=TRUE, use_rcpp_calc_prob=TRUE,
                n_threads=n_threads
            )
            B <- slope_result$B
            se.B <- slope_result$se.B
            basispar <- slope_result$basispar
            B_acceleration <- slope_result$B_acceleration
            a4 <- B_change <- slope_result$B_change
        }

        deviance_result <- irtc_mml_compute_deviance(
            loglike_num=res.hwt$rfx, loglike_sto=res.hwt$rfx,
            snodes=snodes, thetawidth=thetawidth, pweights=pweights,
            deviance=deviance, deviance.history=deviance.history,
            iter=iter
        )
        deviance <- deviance_result$deviance
        deviance.history <- deviance_result$deviance.history
        a01 <- rel_deviance_change <- deviance_result$rel_deviance_change
        a02 <- deviance_change <- deviance_result$deviance_change
        if (con$dev_crit == "relative") {
            a02 <- a01
        }

        if (deviance < deviance.min) {
            xsi.min.deviance <- xsi
            beta.min.deviance <- beta
            variance.min.deviance <- variance
            hwt.min <- hwt
            AXsi.min <- AXsi
            B.min <- B
            deviance.min <- deviance
            itemwt.min <- itemwt
            se.xsi.min <- se.xsi
            se.B.min <- se.B
        }

        a1 <- xsi_change
        a2 <- beta_change
        a3 <- variance_change
        devch <- -(deviance - olddeviance)
        irtc_mml_progress_em(
            progress=progress, deviance=deviance,
            deviance_change=deviance_change, iter=iter,
            rel_deviance_change=rel_deviance_change,
            xsi_change=xsi_change, beta_change=beta_change,
            variance_change=variance_change, B_change=B_change,
            devch=devch
        )
    }

    xsi <- xsi.min.deviance
    beta <- beta.min.deviance
    variance <- variance.min.deviance
    hwt <- hwt.min
    AXsi <- AXsi.min
    B <- B.min
    deviance <- deviance.min
    itemwt <- itemwt.min
    se.xsi <- se.xsi.min
    se.B <- se.B.min

    AXsi <- irtc_mml_include_NA_AXsi(
        AXsi=AXsi, maxcat=maxcat, A=A, xsi=xsi
    )
    xsi.fixed.estimated <- irtc_generate_xsi_fixed_estimated(xsi=xsi, A=A)
    B.fixed.estimated <- irtc_generate_B_fixed_estimated(B=B)
    se.AXsi <- irtc_mml_se_AXsi(AXsi=AXsi, A=A, se.xsi=se.xsi, maxK=maxK)

    ic <- irtc_mml_ic(
        nstud=nstud100, deviance=deviance, xsi=xsi,
        xsi.fixed=xsi.fixed, beta=beta, beta.fixed=beta.fixed,
        ndim=ndim, variance.fixed=variance.fixed, G=G,
        irtmodel=irtmodel, B_orig=B_orig, B.fixed=B.fixed, E=E,
        est.variance=est.variance, resp=resp,
        est.slopegroups=est.slopegroups,
        variance.Npars=variance.Npars, group=group, AXsi=AXsi,
        pweights=pweights, resp.ind=resp.ind, B=B
    )

    count_result <- irtc_calc_counts(
        resp=resp, theta=theta, resp.ind=resp.ind, group=group,
        maxK=maxK, pweights=pweights, hwt=hwt
    )
    n.ik <- count_result$n.ik
    pi.k <- count_result$pi.k
    item1 <- irtc_itempartable(
        resp=resp, maxK=maxK, AXsi=AXsi, B=B, ndim=ndim,
        resp.ind=resp.ind, rprobs=rprobs, n.ik=n.ik,
        pi.k=pi.k, pweights=pweights
    )
    item_irt <- irtc_irt_parameterization(
        resp=resp, maxK=maxK, B=B, AXsi=AXsi,
        irtmodel=irtmodel, irtc_function="irtc.mml.2pl"
    )

    person_result <- irtc_mml_person_posterior(
        pid=pid, nstud=nstud, pweights=pweights,
        resp=resp, resp.ind=resp.ind, snodes=snodes,
        hwtE=hwt, hwt=hwt, ndim=ndim, theta=theta
    )
    person <- person_result$person
    EAP.rel <- person_result$EAP.rel

    finished_at <- Sys.time()
    if (is.null(dimnames(A)[[3]])) {
        dimnames(A)[[3]] <- paste0("Xsi", 1:dim(A)[3])
    }
    item <- data.frame(
        "xsi.index"=1:np, "xsi.label"=dimnames(A)[[3]], "est"=xsi
    )

    if (progress) {
        cat(display_rule)
        cat("Item Parameters\n")
        item2 <- item
        item2[, "est"] <- round(item2[, "est"], 4)
        print(item2)
        cat("...................................\n")
        cat("Regression Coefficients\n")
        print(beta, 4)
        cat("\nVariance:\n")
        if (G == 1) {
            varianceM <- matrix(variance, nrow=ndim, ncol=ndim)
            print(varianceM, 4)
        } else {
            print(variance[var.indices], 4)
        }
        if (ndim > 1) {
            cat("\nCorrelation Matrix:\n")
            print(stats::cov2cor(varianceM), 4)
        }
        cat("\n\nEAP Reliability:\n")
        print(round(EAP.rel, 3))
        cat("\n-----------------------------")
        devmin <- which.min(deviance.history[, 2])
        if (devmin < iter) {
            cat(paste(
                "\n\nMinimal deviance at iteration ", devmin,
                " with deviance ", round(deviance.history[devmin, 2], 3),
                sep=""
            ), "\n")
            cat("The corresponding estimates are\n")
            cat("  xsi.min.deviance\n  beta.min.deviance \n  variance.min.deviance\n\n")
        }
        cat("\nStart: ", paste(started_at))
        cat("\nEnd: ", paste(finished_at), "\n")
        print(finished_at - started_at)
        cat("\n")
    }

    xsi_frame <- data.frame("xsi"=xsi, "se.xsi"=se.xsi)
    rownames(xsi_frame) <- dimnames(A)[[3]]
    xsi <- xsi_frame

    res.hwt <- irtc_calc_posterior(
        rprobs=rprobs, gwt=1 + 0 * gwt, resp=resp,
        nitems=nitems, resp.ind.list=resp.ind.list,
        normalization=FALSE, thetasamp.density=thetasamp.density,
        snodes=snodes, resp.ind=resp.ind, n_threads=n_threads
    )
    res.like <- res.hwt[["hwt"]]
    latreg_stand <- irtc_latent_regression_standardized_solution(
        variance=variance, beta=beta, Y=Y
    )

    deviance.history <- deviance.history[1:iter, ]
    result <- list(
        "xsi"=xsi,
        "beta"=beta, "variance"=variance,
        "item"=item1, item_irt=item_irt,
        "person"=person, pid=pid, "EAP.rel"=EAP.rel,
        "post"=hwt, "rprobs"=rprobs, "itemweight"=itemwt,
        "theta"=theta,
        "n.ik"=n.ik, "pi.k"=pi.k,
        "Y"=Y, "resp"=resp0,
        "resp.ind"=resp.ind, "group"=group,
        "G"=if (is.null(group)) { 1 } else { length(unique(group)) },
        "groups"=if (is.null(group)) { 1 } else { groups },
        "formulaY"=formulaY, "dataY"=dataY,
        "pweights"=pweights0,
        "time"=c(started_at, finished_at), "A"=A, "B"=B,
        "se.B"=se.B,
        "nitems"=nitems, "maxK"=maxK, "AXsi"=AXsi,
        "AXsi_"=-AXsi,
        "se.AXsi"=se.AXsi,
        "nstud"=nstud, "resp.ind.list"=resp.ind.list,
        "hwt"=hwt, "like"=res.like,
        "ndim"=ndim,
        "xsi.fixed"=xsi.fixed,
        "xsi.fixed.estimated"=xsi.fixed.estimated,
        "beta.fixed"=beta.fixed, "Q"=Q,
        "B.fixed"=B.fixed,
        "B.fixed.estimated"=B.fixed.estimated,
        "est.slopegroups"=est.slopegroups, "E"=E,
        "basispar"=basispar,
        "variance.fixed"=variance.fixed,
        "nnodes"=nnodes, "deviance"=deviance,
        "ic"=ic, thetasamp.density=thetasamp.density,
        "deviance.history"=deviance.history,
        "control"=con1a, "irtmodel"=irtmodel,
        "iter"=iter,
        "printxsi"=printxsi, "YSD"=YSD, CALL=CALL,
        latreg_stand=latreg_stand
    )
    result$routing <- grid_routing
    class(result) <- "irtc"
    result
}
