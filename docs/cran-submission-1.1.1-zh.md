# CRAN 提交实战记录：1.1.0 被拒与 1.1.1 重投

> 本文记录 IRTC 首次提交 CRAN 被自动检查退回的**真实经过**：CRAN 报了什么、根因是什么、怎么修的、怎么验证的。
>
> 流程性的操作步骤见 [CRAN 提交指南](cran-submission-guide-zh.md)，本文只记录这一次的事实与结论。

## 时间线

| 时间（2026-07-17） | 事件 |
| --- | --- |
| 10:56 | 提交 `IRTC_1.1.0.tar.gz`，进入 CRAN incoming 自动预检 |
| 11:13 | 预检退回：Windows 2 ERROR / 1 WARNING / 1 NOTE，Debian 2 ERROR / 1 WARNING / 2 NOTE |
| — | 定位根因、修复、版本号升至 1.1.1 |
| — | win-builder R-devel 复验：1 NOTE，tests 与 PDF 手册均 OK |
| — | 提交 `IRTC_1.1.1.tar.gz` 至 CRAN 人工审核 |

对应提交记录：`fix(cran): resolve 1.1.0 incoming pre-test errors; bump to 1.1.1`。

## 一句话结论

**包代码没有问题，一行都没改。** 两个 ERROR 和一个 WARNING 全部来自文档源文件和两个写得过死的测试断言；剩下的 NOTE 是误报。

## 问题一：tests ERROR（Windows + Debian）

### 现象

```text
── Failure ('test-print-session.R:16:5'): package and session helpers report runtime identity ──
Expected `session` to match regexp "^R version .* \| nodename="
Actual text:
✖ │ R Under development (unstable) (2026-07-16 r90264 ucrt) x86_64, mingw32 | nodename=CRANWIN3 | login=CRAN
```

### 根因

`tests/testthat/test-print-session.R` 把 `"R version"` 作为字面量写进了断言。这个措辞对**正式版 R** 成立，但对 **r-devel 不成立**——r-devel 的 `R.version.string` 开头是 `"R Under development (unstable)"`。

被测代码 `irtc_rsessinfo()` 直接取用 `sessionInfo()$R.version$version.string`，行为始终正确；**是测试对 R 自身的措辞做了错误假设**。

### 为什么本地测不出来

CRAN 的检查矩阵包含 r-devel，而本地开发机和仓库的 GitHub Actions 跑的都是 R release。这类失败**只在 r-devel 上复现**，在正式版 R 上无论跑多少次都是绿的。

### 修复

断言改为与 `R.version.string` 自身比对，不再假设措辞：

```r
expect_true(startsWith(session, R.version.string))
expect_match(session, " \\| nodename=")
expect_match(combined, R.version.string, fixed = TRUE)
```

## 问题二：PDF 手册 WARNING + ERROR

### 现象

```text
Check: PDF version of manual, Result: WARNING
  LaTeX errors when creating PDF version.
  ! LaTeX Error: Unicode character 缺 (U+7F3A) not set up for use with LaTeX.
  ! LaTeX Error: Unicode character 题 (U+9898) not set up for use with LaTeX.
  ...

Check: PDF version of manual without index, Result: ERROR
```

Debian 上额外的那条 NOTE（check 目录残留 `IRTC-manual.tex`）是同一根因的**副产物**：LaTeX 编译失败导致中间文件没被清理。

### 根因

`irtc_read.Rd`、`irtc_read_q.Rd`、`irtc_score.Rd` 把可识别的中文列名别名（`题目`、`权重`、`答案` 等）以**字面汉字**写在 Rd 里。构建参考手册用的 LaTeX 编码里没有这些 CJK 字形的定义，于是每个汉字都报一个 LaTeX 错误。

注意 `Encoding: UTF-8` 和 `\encoding{UTF-8}` **解决不了这个问题**——它们声明的是源文件编码，与 LaTeX 能否排版该字形无关。

### 为什么本地测不出来

`scripts/verify-release-1.1.R` 第 85 行调用的是：

```r
rcmdcheck::rcmdcheck(args = c("--as-cran", "--no-manual"), ...)
```

**`--no-manual` 会跳过 PDF 手册构建**，因此这个 LaTeX 错误在本地验证中根本不会被触发。1.1.0 发布记录里那句「0 WARNING」对 `--no-manual` 而言是真实的，但它**没有对手册做出任何断言**。

> 待办：发布验证脚本应在提交前至少跑一次**不带 `--no-manual`** 的完整检查，或单独跑 `R CMD Rd2pdf`。否则同类问题仍会漏到 CRAN 才暴露。

### 取舍

最省事的做法是把中文从文档里删掉，但这些别名是给中文用户看的**有效信息**（告诉他们 Excel 表头可以直接写 `题目`），删掉等于降低可用性。

因此采用的方案是：**信息保留，只让 LaTeX 拿到 ASCII**。

### 修复

分两处处理：

1. **`\usage` 段**（不能放宏，因为要作为 R 代码被解析）：默认参数改写成 `\uxxxx` 转义。

   ```text
   na_strings = c("", "NA", "N/A", "n/a", ".", "*",
       "\u7f3a\u5931", "\u65e0", "\u7a7a"),
   ```

   `"缺失"` 与 `"\u7f3a\u5931"` 在 R 里是**完全相同的字符串**，所以 `checking for code/documentation mismatches`（codoc）依然通过——这一点已实测确认。

2. **正文散文**：新增 Rd 宏 `man/macros/irtc.Rd`。

   ```text
   \newcommand{\zh}{\ifelse{latex}{\code{"#2"}}{\code{"#1"}}}
   ```

   调用形如 `\zh{题目}{\\u9898\\u76ee}`，效果是：

   | 输出目标 | 显示 |
   | --- | --- |
   | HTML 帮助、终端 `?irtc_read` | `"题目"` |
   | LaTeX / PDF 参考手册 | `"\u9898\u76ee"` |

   即中文用户在实际会看的地方仍然看到汉字，只有 PDF 退化为等价的转义写法。

### 排除过的方案

- **`\enc{题目}{timu}`**——无效。实测 `Rd2latex` 对 `\enc{}{}` 输出的是**第一个**参数，ASCII 替代仅用于编码不受支持的场合，CJK 照样进 LaTeX。
- **全局改用 `\uxxxx`**——可行但 HTML 帮助里也会变成转义，中文用户可读性下降。

## 问题三：拼写 NOTE（误报，未修改）

```text
Possibly misspelled words in DESCRIPTION:
  MML (10:58)  Rasch (12:5)  pre (20:53)  unidimensional (11:5)
```

四个词全部拼写正确，属 aspell 词典缺失导致的误报，**不做修改**：

- `MML` — marginal maximum likelihood，本包核心方法缩写
- `Rasch` — Georg Rasch，模型以其姓氏命名
- `unidimensional` — 标准 IRT 术语
- `pre` — 连字符复合词 `pre-estimation` 的前缀

处理方式是在 `cran-comments.md` 中逐条说明理由，供人工审核参考。

## 附带修复：DESCRIPTION 缺 `Date` 字段

排查过程中发现检查日志里的包标识打印成 `IRTC 1.1.0 ()`——空括号。原因是 `DESCRIPTION` 没有 `Date` 字段，而 `irtc_packageinfo()` 会打印它。

补上 `Date: 2026-07-17` 后变为 `IRTC 1.1.1 (2026-07-17)`。

值得记录的是：**有一个测试早已把这个缺陷固化成了断言**。`R/zzz.R` 的 `version()` 用 `paste()` 拼接，Date 缺失时被当作空串，产生两个连续空格；而 `test-progress-lifecycle.R` 的断言恰好就是 `"^IRTC [^ ]+  "`（两个空格）。补上字段后该测试立即失败——它保护的不是正确行为，而是那个缺陷。

两处断言均已改为要求真实日期，使 `Date` 字段今后再丢失能被测试捕获，而不是默默打印空括号：

```r
expect_match(package, "^IRTC [^ ]+ \\(\\d{4}-\\d{2}-\\d{2}\\)$")   # test-print-session.R
expect_match(info, "^IRTC [^ ]+ \\d{4}-\\d{2}-\\d{2} ")            # test-progress-lifecycle.R
```

## 验证结果

### 本地（macOS，R 4.6.0 aarch64）

`R CMD check --as-cran`：**0 ERROR / 0 WARNING**。

- `checking tests` OK
- `checking PDF version of manual` OK
- `checking for code/documentation mismatches` OK（确认 `\uxxxx` 转义与形参一致）
- `checking for non-standard things in the check directory` OK（`IRTC-manual.tex` 残留消失）
- 生成的 PDF 中 CJK 字符数为 **0**；HTML 帮助中 `题目 题号 代数 分部计分 满分 是 否` 等全部保留

### win-builder R-devel（`R Under development (unstable) (2026-07-16 r90264 ucrt)`）

**Status: 1 NOTE**，即上文的 new submission + 拼写误报。

- `checking tests`：`Running 'testthat.R' [326s] OK`
- `checking PDF version of manual`：`[20s] OK`

这一步是**关键**：tests 那个 ERROR 只在 r-devel 上复现，本地无法验证，必须靠 win-builder 的 R-devel 通道确认。

## 经验教训

1. **本地全绿 ≠ CRAN 全绿，这次是结构性的。** 两个 ERROR 各自对应验证流程的一个盲区：`--no-manual` 跳过了 PDF 手册（漏掉 LaTeX 错误），只跑 R release 覆盖不到 r-devel（漏掉测试失败）。提交前必须跑 **win-builder R-devel**，并至少完整构建一次手册。
2. **不要把 R 自身的输出措辞写死在测试里。** 版本串、错误消息等会随 R 版本变化。应与 `R.version.string` 这类变量比对，而非字面量。
3. **Rd 里的非 ASCII 字符要考虑 LaTeX 能否排版。** UTF-8 声明只管源文件编码，不管字形定义。CJK 进 Rd 必然炸 PDF 手册。
4. **测试可能在保护缺陷。** 加 `Date` 字段时暴露的那个两空格断言就是典型：它把 bug 的表现写成了期望值。改动后有测试失败时，先判断它保护的是正确行为还是既有缺陷。
5. **构建提交产物应从干净的 git 导出。** 本次用 `git archive HEAD` 导出后再 `R CMD build`，确保 tar.gz 与仓库状态逐字节对应，不夹带未跟踪文件。

## 复现命令

```bash
# 从 git HEAD 干净导出并构建（避免夹带本地未跟踪文件）
git archive --format=tar HEAD | tar -x -C /tmp/irtc-src
R CMD build /tmp/irtc-src
R CMD check --as-cran IRTC_1.1.1.tar.gz

# 单独验证 PDF 手册可编译、且不含 CJK
R CMD Rd2pdf --no-preview --force --output=/tmp/m.pdf .
pdftotext /tmp/m.pdf - | grep -c '[一-鿿]'   # 期望 0
```
