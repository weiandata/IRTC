# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_mml_person_posterior.R

irtc_mml_person_posterior <- function(pid, nstud, pweights,
    resp, resp.ind, snodes, hwtE, hwt, ndim, theta )
{
    person <- data.frame("pid"=pid, "case"=1:nstud, "pweight"=pweights)
    if (!is.null(resp)) {
        person$score <- rowSums(resp * resp.ind)
        person$max <- irtc_mml_person_maxscore(resp=resp, resp.ind=resp.ind)
    }

    hwtE <- hwt
    if (ndim == 1) {
        person$EAP <- irtc_mml_person_EAP(hwt=hwtE, theta=theta[, 1])
        person$SD.EAP <- irtc_mml_person_SD_EAP(
            hwt=hwtE, theta=theta[, 1], EAP=person$EAP
        )
        EAP.rel <- irtc_mml_person_EAP_rel(
            EAP=person$EAP, SD.EAP=person$SD.EAP, pweights=pweights
        )
    } else {
        EAP.rel <- rep(0, ndim)
        names(EAP.rel) <- paste("Dim", 1:ndim, sep="")

        for (dimension in 1:ndim) {
            person$EAP <- irtc_mml_person_EAP(
                hwt=hwtE, theta=theta[, dimension]
            )
            person$SD.EAP <- irtc_mml_person_SD_EAP(
                hwt=hwtE, theta=theta[, dimension], EAP=person$EAP
            )
            EAP.rel[dimension] <- irtc_mml_person_EAP_rel(
                EAP=person$EAP, SD.EAP=person$SD.EAP,
                pweights=pweights
            )

            current_names <- colnames(person)
            colnames(person)[which(current_names == "EAP")] <- paste(
                "EAP.Dim", dimension, sep=""
            )
            colnames(person)[which(current_names == "SD.EAP")] <- paste(
                "SD.EAP.Dim", dimension, sep=""
            )
        }
    }

    SD <- M <- rep(NA, ndim)
    post <- hwtE
    person_count <- nrow(post)
    for (dimension in 1L:ndim) {
        dimension_nodes <- theta[, dimension]
        node_matrix <- matrix(
            dimension_nodes, nrow=person_count,
            ncol=length(dimension_nodes), byrow=TRUE
        )
        M[dimension] <- sum(node_matrix * post * pweights) / sum(pweights)
        second_moment <- sum(node_matrix^2 * post * pweights) / sum(pweights)
        SD[dimension] <- sqrt(second_moment - M[dimension]^2)
    }

    list(person=person, EAP.rel=EAP.rel, M_post=M, SD_post=SD)
}
