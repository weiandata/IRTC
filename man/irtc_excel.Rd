% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_excel}
\alias{irtc_excel}
\alias{irtc_param_table}
\alias{irtc_person_table}
\title{Export Three Excel Result Workbooks}
\description{
One call writes three separate \code{.xlsx} files (requires the optional
\pkg{openxlsx} package):

\enumerate{
\item \code{<prefix>_item_quality.xlsx} - a plain-language item quality
    table (score rate, difficulty label, discrimination, fit, colour-coded
    overall rating, reasons and advice) plus a notes sheet explaining every
    column, for judging item quality without statistical training.
\item \code{<prefix>_item_parameters.xlsx} - the IRT difficulty /
    discrimination table with a frozen column schema
    (\code{schema_version}, \code{analysis_id}, \code{model},
    \code{item_id}, \code{n_obs}, \code{p_value}, \code{slope_a},
    \code{difficulty_b}, \code{se_b}, \code{tau_k}), designed for
    cross-year anchor-item linking: files from different administrations
    can be merged directly on \code{item_id}.
\item \code{<prefix>_person_ability.xlsx} - a flat person ability table
    (ID, number answered, raw score, EAP, standard error, percentile,
    T score) whose rows stay in input order so it can be pasted next to a
    master sample sheet.
}
}
\usage{
irtc_excel(mod, dir = ".", prefix = "IRTC", lang = irtc_lang(),
    resp = NULL, overwrite = FALSE, verbose = TRUE)

irtc_param_table(mod, resp = NULL, weights = NULL)

irtc_person_table(mod, lang = irtc_lang())
}
\arguments{
\item{mod}{A fitted \code{irtc} model object.}
\item{dir}{Output directory (created if necessary).}
\item{prefix}{File name prefix.}
\item{lang}{Language of headers and notes, \code{"zh"} or \code{"en"}.
    The linking schema of file 2 is language-independent.}
\item{resp}{The response data; only needed when the model object does not
    store it (streaming engine).}
\item{weights}{Optional case (sampling) weights, one per person, used for
    the \code{p_value} column so it shares the basis of the weighted IRT
    parameters beside it. Defaults to the case weights stored on the model.}
\item{overwrite}{Logical: overwrite existing files? Otherwise an error of
    class \code{irtc_error_export} (code \code{E501}) is raised.}
\item{verbose}{Logical: print a completion message?}
}
\value{
\code{irtc_excel} invisibly returns a named character vector with the
three file paths (\code{quality}, \code{parameters}, \code{ability}).
\code{irtc_param_table} and \code{irtc_person_table} return the underlying
data frames and work without \pkg{openxlsx}.

For a multidimensional model \code{irtc_param_table} adds a
\code{dimension} column naming the latent dimension each item loads on
(from the Q-matrix column headers when available), and \code{n_loadings},
the number of dimensions the item loads on. \code{slope_a} and
\code{difficulty_b} are read from that dimension. An item loading on
several dimensions at once (within-item structure) has no single slope:
\code{slope_a} is then the sum of its loadings and \code{n_loadings} is
above 1, flagging the value as a composite.

Note that the person-level \code{percentile} and \code{t_score} columns
of \code{irtc_person_table} are always computed on the unweighted sample,
so they describe the respondents themselves rather than the weighted
population.
}
\seealso{\code{\link{irtc}}, \code{\link{irtc_report}},
\code{\link{irtc_results}}}
\examples{
set.seed(1)
theta <- rnorm(150)
resp <- as.data.frame(sapply(seq(-1, 1, length.out = 5), function(b) {
    as.numeric(runif(150) < plogis(theta - b))
}))
mod <- irtc(resp, model = "1PL", verbose = FALSE)

## data frames behind the workbooks (no extra packages needed)
irtc_param_table(mod)
head(irtc_person_table(mod, lang = "en"))

if (requireNamespace("openxlsx", quietly = TRUE)) {
    out <- irtc_excel(mod, dir = tempdir(), overwrite = TRUE,
        verbose = FALSE)
    basename(out)
}
}
