# IRTC
# Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
# SPDX-License-Identifier: GPL-2.0-or-later
# See inst/COPYRIGHTS for licensing details.

## File Name: irtc_acceleration_inits.R


irtc_acceleration_inits <- function(acceleration, G, xsi, variance, B=NULL,
        irtmodel=NULL, gammaslope=NULL, guess=NULL, ind.guess=NULL, delta=NULL)
{
    B_acceleration <- NULL
    gammaslope_acceleration <- NULL
    guess_acceleration <- NULL
    delta_acceleration <- NULL

    #************
    #--- xsi
    xsi_acceleration <- irtc_acceleration_inits_create_list(acceleration=acceleration, parm=xsi)
    #--- variance
    acceleration1 <- acceleration
    if (G>1){
        acceleration1 <- "none"
    }
    variance_acceleration <- irtc_acceleration_inits_create_list(acceleration=acceleration1,
                                    parm=as.vector(variance) )
    #--- B
    if (! is.null(B) ){
        acceleration1 <- acceleration
        if (irtmodel=="GPCM.design" ){
            acceleration1 <- "none"
        }
        B_acceleration <- irtc_acceleration_inits_create_list(acceleration=acceleration1,
                                    parm=as.vector(B) )
    }
    #--- gammaslope
    if ( ! is.null(gammaslope) ){
        gammaslope_acceleration <- irtc_acceleration_inits_create_list(acceleration=acceleration,
                                        parm=gammaslope)
    }
    #--- guessing parameter
    if ( ! is.null(guess) ){
        guess_acceleration <- irtc_acceleration_inits_create_list(acceleration=acceleration,
                                        parm=guess)
        guess_acceleration$ind.guess <- ind.guess
    }
    #--- delta
    if ( ! is.null(delta) ){
        delta_acceleration <- irtc_acceleration_inits_create_list(acceleration=acceleration,
                                        parm=as.vector(delta) )
    }
    #--- OUTPUT
    res <- list( xsi_acceleration=xsi_acceleration,
                    variance_acceleration=variance_acceleration,
                    B_acceleration=B_acceleration,
                    gammaslope_acceleration=gammaslope_acceleration,
                    guess_acceleration=guess_acceleration,
                    delta_acceleration=delta_acceleration
                    )
    return(res)
}
