% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_results}
\alias{irtc_results}
\alias{irtc_json}
\alias{print.irtc_results}
\title{Machine-Readable Results with a Stable Schema}
\description{
Extracts fitted-model results as tidy data frames with a stable,
documented schema aimed at automated callers (pipelines, AI agents).
Column names are fixed English snake_case identifiers and never depend on
the language option. \code{irtc_json} exports the same content as JSON
(requires the optional \pkg{jsonlite} package).

Schema v1.0 components: \code{model_info} (one row: schema and package
version, model, sizes, deviance, AIC/BIC, EAP reliability, iterations),
\code{items} (per item: parameters, classical statistics, fit, quality
rating and bilingual reasons/advice), \code{persons} (per person: ID,
number answered, raw score, EAP, SE, percentile, T score),
\code{cleaning_log} and \code{check_issues} (present when the model was
fitted via \code{\link{irtc}}). See the package file \code{inst/llms.txt}
for the full schema reference.
}
\usage{
irtc_results(mod, resp = NULL)

irtc_json(mod, file = NULL, resp = NULL, pretty = TRUE)

\method{print}{irtc_results}(x, lang = irtc_lang(), \dots)
}
\arguments{
\item{mod}{A fitted \code{irtc} model object; \code{irtc_json} also
    accepts an \code{irtc_results} object.}
\item{resp}{The response data; only needed when the model object does not
    store it (streaming engine).}
\item{file}{Optional path; when given, the JSON is written there (UTF-8)
    and the path is returned invisibly.}
\item{pretty}{Logical: pretty-print the JSON?}
\item{x}{An \code{irtc_results} object.}
\item{lang}{Output language, \code{"zh"} or \code{"en"}.}
\item{\dots}{Ignored.}
}
\value{
\code{irtc_results} returns an object of class \code{irtc_results}, a list
of data frames as described above. \code{irtc_json} returns a JSON string,
or invisibly the file path when \code{file} is given.
}
\seealso{\code{\link{irtc}}, \code{\link{irtc_excel}}}
\examples{
set.seed(1)
theta <- rnorm(150)
resp <- as.data.frame(sapply(seq(-1, 1, length.out = 5), function(b) {
    as.numeric(runif(150) < plogis(theta - b))
}))
mod <- irtc(resp, model = "1PL", verbose = FALSE)

res <- irtc_results(mod)
res$model_info
head(res$items)

if (requireNamespace("jsonlite", quietly = TRUE)) {
    json <- irtc_json(mod)
    substr(json, 1, 80)
}
}
