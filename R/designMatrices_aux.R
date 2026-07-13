# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: designMatrices_aux.R

print.designMatrices <- function( x, ... ){
    slope_columns <- x$flatB
    colnames(slope_columns) <- paste0("B_", colnames(slope_columns))
    displayed <- cbind(x$flatA, slope_columns)
    meaningful_rows <- !apply(x$flatA, 1, function(values) all(is.na(values)))
    displayed <- displayed[meaningful_rows, ]
    print(displayed)
    invisible(displayed)
}

rownames.design <- function(X){
    numeric_columns <- apply(X, 2, as.numeric)
    labels <- sapply(seq_len(ncol(numeric_columns)), function(column) {
        largest_value <- max(as.numeric(numeric_columns[, column]))
        width <- ceiling(log(largest_value, 10))
        paste0(
            colnames(numeric_columns)[column],
            add.lead(numeric_columns[, column], width)
        )
    })
    rownames(X) <- apply(labels, 1, paste, collapse="-")
    X
}

rownames.design2 <- function(X){
    numeric_columns <- apply(X, 2, as.numeric)
    labels <- sapply(seq_len(ncol(numeric_columns)), function(column) {
        paste0(
            colnames(numeric_columns)[column],
            add.lead(numeric_columns[, column], 1)
        )
    })
    rownames(X) <- apply(labels, 1, paste, collapse="-")
    X
}

.A.PCM2 <- function( resp, Kitem=NULL, constraint="cases", Q=NULL ){
    if (is.null(Kitem)) {
        Kitem <- apply(resp, 2, max, na.rm=TRUE) + 1
    }

    n_items <- ncol(resp)
    largest_category_count <- max(Kitem)
    n_parameters <- sum(Kitem) - n_items
    design <- array(0, dim=c(n_items, largest_category_count, n_parameters))

    for (item_index in seq_len(n_items)) {
        count <- Kitem[item_index]
        scores <- seq_len(count - 1)
        design[item_index, scores + 1, item_index] <- -scores
        if (count < largest_category_count) {
            design[item_index, (count + 1):largest_category_count, ] <- NA
        }
    }

    next_parameter <- n_items + 1
    for (item_index in seq_len(n_items)) {
        count <- Kitem[item_index]
        if (count > 2) {
            for (threshold_category in seq.int(2, count - 1)) {
                design[
                    item_index,
                    threshold_category:(count - 1),
                    next_parameter
                ] <- -1
                next_parameter <- next_parameter + 1
            }
        }
    }

    dimnames(design)[[1]] <- colnames(resp)
    parameter_names <- colnames(resp)
    unidimensional <- is.null(Q) || ncol(Q) == 1
    label_item_count <- n_items

    if (constraint == "items") {
        if (unidimensional) {
            reference <- matrix(
                -design[n_items, , n_items],
                nrow=dim(design)[2], ncol=n_items - 1, byrow=FALSE
            )
            design[n_items, , seq.int(1, n_items - 1)] <- reference
            design <- design[, , -n_items]
            parameter_names <- parameter_names[-n_items]
        } else {
            removed <- integer(0)
            for (dimension in seq_len(ncol(Q))) {
                linked_items <- which(Q[, dimension] != 0)
                reference_item <- linked_items[length(linked_items)]
                reference <- matrix(
                    -design[reference_item, , reference_item],
                    nrow=dim(design)[2], ncol=length(linked_items) - 1,
                    byrow=FALSE
                )
                design[reference_item, , linked_items[-length(linked_items)]] <- reference
                removed <- c(removed, reference_item)
                label_item_count <- reference_item
            }
            parameter_names <- parameter_names[-removed]
            design <- design[, , -removed]
        }
    }

    step_items <- (seq_len(label_item_count))[Kitem > 2]
    step_names <- unlist(lapply(step_items, function(item_index) {
        paste0(colnames(resp)[item_index], "_step", seq_len(Kitem[item_index] - 2))
    }))
    dimnames(design)[[3]] <- c(parameter_names, step_names)
    design
}
