% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd. GPL-2.0-or-later.
\name{data.sim.rasch}
\alias{data.sim.rasch}
\docType{data}
\title{Simulated Dichotomous Rasch Data}
\description{
A simulated dataset of dichotomous (0/1) item responses generated under the
Rasch model, provided as an example dataset for \pkg{IRTC}.
}
\usage{data(data.sim.rasch)}
\format{
A matrix with 2000 persons (rows) and 40 dichotomous items (columns), with
entries coded 0 or 1.
}
\details{
The data were simulated with person abilities drawn from a standard normal
distribution and item difficulties spread evenly over \eqn{[-2.2, 2.2]}.
The generating script is \file{scripts/gen_data.R} in the package sources.
}
\source{Simulated by IRTC. See \file{scripts/gen_data.R} in the package
sources for the reproducible generating code.}
\keyword{datasets}
