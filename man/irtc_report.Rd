% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_report}
\alias{irtc_report}
\title{Generate a Word or HTML Analysis Report}
\description{
Writes an analysis report with figures (Wright map, ability distribution,
item quality summary, item characteristic curves) and tables. Three
audience layouts are available: \code{"decision"} (a short executive
summary with recommendations), \code{"survey"} (a plain-language full
report) and \code{"stat"} (a complete technical report including item
parameters, item fit and model information).

HTML reports are fully self-contained single files (images embedded);
Word reports require the optional \pkg{officer} package.
}
\usage{
irtc_report(mod, file, format = NULL,
    audience = c("survey", "decision", "stat"), lang = irtc_lang(),
    resp = NULL, title = NULL, overwrite = FALSE, verbose = TRUE)
}
\arguments{
\item{mod}{A fitted \code{irtc} model object.}
\item{file}{Output file path ending in \code{.docx} or \code{.html}.}
\item{format}{\code{"docx"} or \code{"html"}; inferred from \code{file}
    when \code{NULL}.}
\item{audience}{Report layout; see Description.}
\item{lang}{Output language, \code{"zh"} or \code{"en"}.}
\item{resp}{The response data; only needed when the model object does not
    store it (streaming engine).}
\item{title}{Report title; a bilingual default is used when \code{NULL}.}
\item{overwrite}{Logical: overwrite an existing file?}
\item{verbose}{Logical: print a completion message?}
}
\value{Invisibly, the output file path.}
\seealso{\code{\link{irtc}}, \code{\link{plain_summary}},
\code{\link{irtc_excel}}, \code{\link{plot.irtc}}}
\examples{
set.seed(1)
theta <- rnorm(150)
resp <- as.data.frame(sapply(seq(-1, 1, length.out = 5), function(b) {
    as.numeric(runif(150) < plogis(theta - b))
}))
mod <- irtc(resp, model = "1PL", verbose = FALSE)

file <- tempfile(fileext = ".html")
irtc_report(mod, file, audience = "decision", lang = "en",
    verbose = FALSE)
file.exists(file)
unlink(file)
}
