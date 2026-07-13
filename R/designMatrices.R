# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: designMatrices.R

designMatrices <- function( modeltype=c( "PCM", "RSM" ),
            maxKi=NULL, resp=resp, ndim=1, A=NULL, B=NULL, Q=NULL, R=NULL,
            constraint="cases", ... )
{
    supplied_A <- A
    modeltype <- match.arg(modeltype)

    if (!is.null(A)) {
        constraint <- "cases"
    }

    if (is.null(maxKi)) {
        if (!is.null(resp)) {
            response_copy <- resp
            response_copy[is.na(response_copy)] <- 0
            maxKi <- apply(response_copy, 2, max, na.rm=TRUE)
        } else if (!is.null(A)) {
            encoded_scores <- -colSums(A)
            repeated_positions <- which(encoded_scores > 1)
            omitted <- repeated_positions + encoded_scores[repeated_positions] - 1
            maxKi <- encoded_scores[-omitted]
        } else {
            return(warning("Not enough information to generate design matrices"))
        }
    }

    zero_score_items <- names(maxKi)[maxKi == 0]
    if (length(zero_score_items) > 0) {
        cat("Items with maximum score of 0:", paste(zero_score_items, collapse=" "))
    }

    n_items <- length(maxKi)
    largest_score <- max(maxKi)
    item <- rep(seq_len(n_items), maxKi + 1)

    if (modeltype %in% c("PCM", "RSM")) {
        category <- unlist(lapply(maxKi, function(top) seq.int(0, top)))
        n_parameters <- sum(maxKi)

        if (is.null(Q)) {
            loading_map <- matrix(0, nrow=n_items, ncol=ndim)
            chosen_dimension <- sample(seq_len(ndim), n_items, replace=TRUE)
            loading_map[cbind(seq_len(n_items), chosen_dimension)] <- 1
        } else {
            loading_map <- Q
        }
        ndim <- ncol(loading_map)

        if (is.null(B)) {
            B_work <- array(
                0,
                dim=c(n_items, largest_score + 1, ndim),
                dimnames=list(
                    colnames(resp),
                    paste("Cat", 0:largest_score, sep=""),
                    paste("Dim", ifelse(seq_len(ndim) < 10, "0", ""),
                          seq_len(ndim), sep="")
                )
            )
            dimensions_to_fill <- if (is.null(Q)) ndim else seq_len(ndim)
            for (dimension in dimensions_to_fill) {
                category_slopes <- outer(
                    loading_map[, dimension], 0:largest_score, `*`
                )
                if (is.null(Q)) {
                    valid_category <- outer(maxKi, 0:largest_score, `>=`)
                    category_slopes[!valid_category] <- 0
                }
                B_work[, , dimension] <- category_slopes
            }
        } else {
            B_work <- B
        }

        if (!is.null(Q)) {
            for (dimension in seq_len(ncol(Q))) {
                B_work[, , dimension] <- outer(Q[, dimension], 0:largest_score, `*`)
            }
        }

        if (is.null(A) || length(dim(A)) < 3) {
            A_work <- array(
                0,
                dim=c(n_items, largest_score + 1, n_parameters),
                dimnames=list(
                    paste("Item", ifelse(seq_len(n_items) < 10, "0", ""),
                          seq_len(n_items), sep=""),
                    paste("Category", 0:largest_score, sep=""),
                    NULL
                )
            )

            parameter_start <- c(0, cumsum(maxKi))[seq_len(n_items)]
            for (item_index in seq_len(n_items)) {
                top <- maxKi[item_index]
                own_parameters <- parameter_start[item_index] + seq_len(top)
                for (score in seq_len(top)) {
                    A_work[item_index, score + 1, own_parameters[seq_len(score)]] <- -1
                }
                if (top < largest_score) {
                    A_work[item_index, (top + 2):(largest_score + 1), ] <- NA
                }
            }

            step_number <- unlist(lapply(maxKi, function(top) seq.int(1, top)))
            parameter_labels <- paste(
                rep(colnames(resp), maxKi), "_Cat", step_number, sep=""
            )
            if (largest_score == 1) {
                parameter_labels <- colnames(resp)
            }
            dimnames(A_work)[[3]] <- parameter_labels
        } else {
            A_work <- A
        }
    }

    unidimensional <- is.null(Q) || ncol(Q) == 1
    if (constraint == "items") {
        if (largest_score == 1 && unidimensional) {
            parameter_count <- dim(A_work)[3]
            A_work[parameter_count, 2, ] <- 1
            A_work <- A_work[, , seq.int(1, parameter_count - 1)]
        }
        if (largest_score == 1 && !unidimensional) {
            reference_parameters <- integer(0)
            for (dimension in seq_len(ncol(Q))) {
                linked_items <- which(Q[, dimension] != 0)
                reference_item <- linked_items[length(linked_items)]
                reference_parameters <- c(reference_parameters, reference_item)
                A_work[reference_item, 2, linked_items] <- 1
            }
            A_work <- A_work[, , -reference_parameters]
        }
    }

    if (modeltype == "RSM") {
        category_count <- maxKi + 1
        rsm_parameters <- n_items + largest_score - 1
        rsm_A <- array(0, dim=c(n_items, largest_score + 1, rsm_parameters))

        for (item_index in seq_len(n_items)) {
            last_category <- category_count[item_index]
            rsm_A[item_index, 2:last_category, item_index] <- -(seq.int(2, last_category) - 1)
            if (last_category <= largest_score) {
                rsm_A[item_index, (last_category + 1):(largest_score + 1), ] <- NA
            }
        }

        common_category_count <- largest_score + 1
        for (item_index in seq_len(n_items)) {
            if (common_category_count > 2) {
                for (step in seq_len(common_category_count - 2)) {
                    affected <- 1 + seq.int(step, common_category_count - 2)
                    rsm_A[item_index, affected, n_items + step] <- -1
                }
            }
        }

        dimnames(rsm_A)[[1]] <- colnames(resp)
        dimnames(rsm_A)[[3]] <- c(
            colnames(resp), paste0("Cat", seq_len(largest_score - 1))
        )

        if (constraint == "items" && unidimensional) {
            reference_profile <- rsm_A[n_items, , n_items]
            rsm_A[n_items, , seq_len(n_items - 1)] <- -reference_profile
            rsm_A <- rsm_A[, , -n_items]
        }
        A_work <- rsm_A
    }

    if (!is.null(supplied_A) && modeltype != "RSM") {
        A_work <- A
    }

    flatA <- matrix(aperm(A_work, c(2, 1, 3)), ncol=dim(A_work)[3])
    colnames(flatA) <- dimnames(A_work)[[3]]
    flatB <- matrix(aperm(B_work, c(2, 1, 3)), ncol=dim(B_work)[3])
    colnames(flatB) <- dimnames(B_work)[[3]]
    row_labels <- t(outer(
        dimnames(B_work)[[1]], dimnames(B_work)[[2]], paste, sep="."
    ))
    rownames(flatA) <- row_labels
    rownames(flatB) <- row_labels

    result <- list(
        "item"=item, "maxKi"=maxKi, "cat"=category,
        "A"=A_work, "flatA"=flatA, "B"=B_work,
        "flatB"=flatB, "Q"=Q, "R"=R
    )
    class(result) <- "designMatrices"
    result
}
