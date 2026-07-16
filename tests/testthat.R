# Base R error messages are matched literally in several legacy tests;
# force untranslated (English) messages so the suite is locale-independent
# (e.g. when the maintainer machine runs in a zh_CN locale).
Sys.setenv(LANGUAGE="en")

library(testthat)
library(IRTC)
test_check("IRTC")
