% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later
\name{irtc_read}
\encoding{UTF-8}
\alias{irtc_read}
\alias{print.irtc_data}
\title{Read and Clean Item Response Data from Many Formats}
\description{
Unified data import with automatic cleaning. Supports Excel
(\code{.xlsx}, \code{.xls}; requires \pkg{readxl}), delimited text
(\code{.csv}, \code{.tsv}, \code{.txt}, \code{.dat}; delimiter and
UTF-8/GBK encoding are detected automatically), SPSS/Stata/SAS files
(\code{.sav}, \code{.por}, \code{.dta}, \code{.sas7bdat}, \code{.xpt};
requires \pkg{haven}) and in-memory data frames, matrices and tibbles.

Every cleaning action is recorded in a bilingual log attached to the
returned object, so results remain traceable.
}
\usage{
irtc_read(x, sheet = 1, id = NULL,
    missing_codes = c(-9, -99, 99, 999),
    na_strings = c("", "NA", "N/A", "n/a", ".", "*",
        "缺失", "无", "空"),
    guess_id = TRUE, clean = TRUE, recode = TRUE, verbose = TRUE)

\method{print}{irtc_data}(x, lang = irtc_lang(), \dots)
}
\arguments{
\item{x}{A file path or a data frame / matrix. For the print method: an
    \code{irtc_data} object.}
\item{sheet}{Excel sheet to read (number or name).}
\item{id}{Person identifier column(s), by name or index. The first is kept
    as the person ID; the rest are set aside. If \code{NULL} and
    \code{guess_id} is \code{TRUE}, common ID column names (\code{id},
    \code{pid}, student number, name, etc., in English and Chinese) are
    detected automatically.}
\item{missing_codes}{Numeric codes recoded to \code{NA}. Negative codes are
    always treated as missing; a positive code is only recoded in a column
    when it lies clearly above the observed response range, which protects
    e.g. a legitimate score of 99 on a 0-100 scale.}
\item{na_strings}{Strings treated as missing in text columns.}
\item{guess_id}{Logical: detect the person ID column automatically?}
\item{clean}{Logical: apply the cleaning steps (drop empty rows/columns,
    convert numeric-like text, recode missing codes)?}
\item{recode}{Logical: recode integer response categories to consecutive
    scores starting at 0 (e.g. a 1-5 Likert item becomes 0-4)?}
\item{verbose}{Logical: print the object (including the cleaning log)?}
\item{lang}{Output language, \code{"zh"} or \code{"en"}.}
\item{\dots}{Ignored.}
}
\value{
An object of class \code{irtc_data}: a list with components \code{resp}
(cleaned response data frame), \code{pid} (person IDs or \code{NULL}),
\code{dropped} (set-aside non-response columns), \code{log} (cleaning log
data frame with columns \code{step}, \code{code}, \code{message_en},
\code{message_zh}) and \code{source}.
}
\seealso{\code{\link{irtc}}, \code{\link{irtc_score}},
\code{\link{irtc_check_data}}}
\examples{
path <- tempfile(fileext = ".csv")
writeLines(c("id,i1,i2,i3", "s1,0,1,99", "s2,1,-9,1", "s3,1,0,0"), path)
d <- irtc_read(path, verbose = FALSE)
d$resp
d$pid
print(d, lang = "en")
unlink(path)
}
