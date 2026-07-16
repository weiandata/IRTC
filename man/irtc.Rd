% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc}
\alias{irtc}
\title{One-Stop Item Response Model Estimation}
\description{
Reads data from a file or R object, cleans it, optionally scores raw
multiple-choice responses against an answer key, checks it, estimates the
requested item response model and enriches the result with classical item
statistics, item fit and plain-language quality ratings.

Designed for non-specialists and automated callers; professional users keep
full control because all additional arguments are passed unchanged to
\code{\link{irtc.mml}} (for \code{"1PL"}, \code{"PCM"}, \code{"PCM2"},
\code{"RSM"}) or \code{\link{irtc.mml.2pl}} (for \code{"2PL"},
\code{"GPCM"}).
}
\usage{
irtc(data, model, key = NULL, rules = NULL, q = NULL,
    on_mismatch = c("warn", "error"), id = NULL, weights = NULL,
    sheet = 1, missing_codes = c(-9, -99, 99, 999), check = TRUE,
    quality = TRUE, verbose = TRUE, ...)
}
\arguments{
\item{data}{A file path (\code{.xlsx}, \code{.xls}, \code{.csv},
    \code{.tsv}, \code{.txt}, \code{.dat}, \code{.sav}, \code{.por},
    \code{.dta}, \code{.sas7bdat}, \code{.xpt}), a data frame, a matrix, or
    an object returned by \code{\link{irtc_read}}.}
\item{model}{Required. One of \code{"1PL"} (alias \code{"Rasch"}),
    \code{"2PL"}, \code{"PCM"}, \code{"PCM2"}, \code{"RSM"},
    \code{"GPCM"}. Case-insensitive.}
\item{key}{An optional answer key for raw responses: a named vector or
    a key-file path (optionally with a partial-answer column); see
    \code{\link{irtc_score}}.}
\item{rules}{An optional partial-credit scoring table or a path to one;
    see \code{\link{irtc_score}}.}
\item{q}{An optional Q (item-by-dimension) matrix: a file path, data
    frame, matrix, or an object from \code{\link{irtc_read_q}}. The Q
    matrix is aligned with the data via \code{\link{irtc_align_q}} and
    passed to the estimation as \code{Q}; its dimension names label the
    person-level output. If \code{Q} is also supplied through
    \code{\dots}, the explicit \code{Q} wins and a warning (\code{W419})
    is raised.}
\item{on_mismatch}{How to handle items that differ between the Q matrix
    and the data; see \code{\link{irtc_align_q}}.}
\item{id}{An optional person identifier column (name or index); passed to
    \code{\link{irtc_read}}.}
\item{weights}{An optional sampling weight column (name or index); passed
    to \code{\link{irtc_read}}. Common weight column names are also
    detected automatically. The weights are used as \code{pweights} in the
    estimation; if \code{pweights} is also supplied through \code{\dots},
    the explicit \code{pweights} wins and a warning (\code{W418}) is
    raised.}
\item{sheet}{Excel sheet to read (number or name).}
\item{missing_codes}{Numeric values recoded to \code{NA} during cleaning;
    see \code{\link{irtc_read}}.}
\item{check}{Logical: stop with a structured error if
    \code{\link{irtc_check_data}} finds any error-level issue?}
\item{quality}{Logical: attach CTT statistics, item fit and quality
    ratings to the result?}
\item{verbose}{Logical: print estimation progress?}
\item{\dots}{Further arguments passed to \code{\link{irtc.mml}} or
    \code{\link{irtc.mml.2pl}} (e.g. \code{group}, \code{pweights},
    \code{Q}, \code{control}).}
}
\value{
An object of class \code{irtc} (see \code{\link{irtc.mml}}) with an
additional list component \code{usability} containing \code{model},
\code{data_log} (cleaning log), \code{check} (the
\code{\link{irtc_check_data}} result), \code{removed_items},
\code{ctt}, \code{itemfit} and \code{quality}.
}
\details{
Items without any observed responses or without variance are removed
before estimation (with a warning of class \code{irtc_warning_estimation}).
All errors raised by the usability layer are structured conditions with
fields \code{code}, \code{reason} and \code{fix}; see the package file
\code{inst/llms.txt} for the full list of codes.

The language of user-facing output is controlled by
\code{options(irtc.lang = "zh")} (default) or \code{"en"}.
}
\seealso{
\code{\link{irtc_read}}, \code{\link{irtc_check_data}},
\code{\link{plain_summary}}, \code{\link{irtc_excel}},
\code{\link{irtc_report}}, \code{\link{irtc_results}}
}
\examples{
set.seed(1)
theta <- rnorm(150)
resp <- as.data.frame(sapply(seq(-1, 1, length.out = 5), function(b) {
    as.numeric(runif(150) < plogis(theta - b))
}))
colnames(resp) <- paste0("I", 1:5)

mod <- irtc(resp, model = "1PL", verbose = FALSE)
plain_summary(mod, lang = "en")
mod$usability$quality
}
