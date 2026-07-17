% Copyright (C) 2026 WEIAN DATA TECH (Beijing) Co., Ltd.
% SPDX-License-Identifier: GPL-2.0-or-later

% \zh{<chinese>}{<escapes>} renders a recognised Chinese column-name alias.
% HTML and text help show the Chinese characters (#1); the LaTeX/PDF manual
% shows the equivalent ASCII \\uxxxx escape sequence (#2), because the CJK
% glyphs have no definition in the LaTeX encoding used to build the manual.
% Both forms denote the same R string.
\newcommand{\zh}{\ifelse{latex}{\code{"#2"}}{\code{"#1"}}}
