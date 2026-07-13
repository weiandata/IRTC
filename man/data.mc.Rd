% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd. GPL-2.0-or-later.
\name{data.mc}
\alias{data.mc}
\docType{data}
\title{Simulated Multiple-Choice Item Response Data}
\description{
A simulated dataset of multiple-choice item responses provided in both raw and
scored form, provided as an example dataset for \pkg{IRTC}.
}
\usage{data(data.mc)}
\format{
A list with two components:
\describe{
\item{raw}{A character matrix (143 persons x 30 items) of raw multiple-choice
responses coded \code{"A"}--\code{"D"}, with \code{"9"} denoting an omitted or
not-reached response.}
\item{scored}{A data frame of the corresponding dichotomously scored (0/1)
responses, where 1 marks the keyed (correct) option.}
}
}
\details{
Correctness was simulated under a Rasch model; raw responses were then built
from a randomly assigned answer key with distractors drawn at random. The
generating script is \file{scripts/gen_data.R} in the package sources.
}
\source{Simulated by IRTC. See \file{scripts/gen_data.R} in the package
sources for the reproducible generating code.}
\keyword{datasets}
