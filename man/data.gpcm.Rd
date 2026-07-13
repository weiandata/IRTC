% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd. GPL-2.0-or-later.
\name{data.gpcm}
\alias{data.gpcm}
\docType{data}
\title{Simulated Polytomous Item Response Data}
\description{
A simulated dataset of polytomous item responses suitable for fitting partial
credit and generalised partial credit models, provided as an example dataset
for \pkg{IRTC}.
}
\usage{data(data.gpcm)}
\format{
A data frame with 392 persons (rows) and 3 polytomously scored items
(columns \code{Comfort}, \code{Work}, \code{Benefit}), each scored in four
ordered categories \code{0}, \code{1}, \code{2}, \code{3}.
}
\details{
The data were simulated from a partial credit model with three step
parameters per item. The generating script is \file{scripts/gen_data.R} in
the package sources.
}
\source{Simulated by IRTC. See \file{scripts/gen_data.R} in the package
sources for the reproducible generating code.}
\keyword{datasets}
