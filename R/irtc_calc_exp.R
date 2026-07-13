# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_calc_exp.R

irtc_calc_exp <- function(rprobs, A, np, est.xsi.index, itemwt,
    indexIP.no, indexIP.list2, Avector)
{
    category_count <- dim(rprobs)[[2]]
    node_count <- dim(rprobs)[[3]]
    parameter_count <- dim(A)[[3]]
    item_count <- dim(A)[[1]]

    probability_vector <- irtc_rcpp_calc_exp_redefine_vector_na(
        A=as.vector(rprobs), val=0
    )

    irtc_rcpp_calc_exp(
        NP=np, rprobs=probability_vector, A=Avector,
        INDEXIPNO=indexIP.no, INDEXIPLIST2=indexIP.list2,
        ESTXSIINDEX=est.xsi.index, C=category_count,
        ITEMWT=itemwt, NR=item_count * category_count, TP=node_count
    )
}

calc_exp_TK3 <- irtc_calc_exp
