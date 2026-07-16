% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_lang}
\alias{irtc_lang}
\title{Output Language of the IRTC Usability Layer}
\description{
Returns the current output language, \code{"zh"} (Chinese, the default) or
\code{"en"} (English). Set it globally with
\code{options(irtc.lang = "en")}. The language affects user-facing text
(messages, printed summaries, Excel headers, reports); machine-readable
schemas (\code{\link{irtc_results}}, the linking table of
\code{\link{irtc_excel}}) never depend on it.
}
\usage{
irtc_lang()
}
\value{\code{"zh"} or \code{"en"}.}
\examples{
old <- options(irtc.lang = "en")
irtc_lang()
options(old)
}
