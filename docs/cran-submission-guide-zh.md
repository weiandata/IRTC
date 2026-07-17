# IRTC 上传 CRAN 全流程详细指南

> 本指南面向第一次向 CRAN 提交 R 包的作者，覆盖从准备、检查、构建、提交到收到结果后处理的**完整流程**，并列出 IRTC 的包级合规检查要求。
>
> 当前状态：1.1.1 已提交 CRAN 人工审核。最近一次完整 `R CMD check --as-cran`
> 为 0 ERROR、0 WARNING、1 NOTE（“New submission” + 拼写误报）；win-builder
> R-devel 复验同为 1 NOTE。
>
> **1.1.0 曾被 incoming 自动预检退回**（2 ERROR / 1 WARNING）。退回原因、根因分析与
> 修复方式见 [CRAN 提交实战记录：1.1.0 被拒与 1.1.1 重投](cran-submission-1.1.1-zh.md)。
> 本指南讲“该怎么做”，那篇讲“实际发生了什么”。

---

## 0. 一句话流程

> 改好 `DESCRIPTION` → `R CMD build` 生成 `.tar.gz` → `R CMD check --as-cran` 干净 → 在多平台跑一遍检查 → 写 `cran-comments.md` → 用 `devtools::submit_cran()` 或网页表单提交 → 回邮件确认 → 等 CRAN 人工/自动反馈 → 通过或按意见修改重投。

---

## 1. 提交前必须确认的事项（针对 IRTC）

### 1.1 维护者必须是你本人
CRAN 会给 `DESCRIPTION` 里 `cre`（maintainer）那个邮箱发**确认邮件**，你必须能收到并点击确认。当前已设为：

```
person("Kunxiang", "Ma", role = c("aut", "cre"), email = "makunxiang@weiandata.com")
```

姓名与邮箱已随 1.1.0 / 1.1.1 提交并由 CRAN 确认送达。如需变更，编辑仓库根目录 `DESCRIPTION` 的 `Authors@R`。维护者邮箱要长期有效，CRAN 后续所有沟通都走这个邮箱。

### 1.2 所有权、许可证与依赖边界（重要）

提交前逐项确认：

1. `DESCRIPTION` 的 `Authors@R` 与 `inst/COPYRIGHTS` 权属一致；公司为 `cph`，Kunxiang Ma 为 `aut` 和 `cre`。
2. 许可证保持 GPL (>= 2)，源码文件保留 `SPDX-License-Identifier: GPL-2.0-or-later`，分发源码包包含完整对应源码。
3. MASS、mvtnorm 和 sfsmisc 是外部运行依赖，其源码没有打包进 IRTC；依赖边界在 `inst/COPYRIGHTS` 中说明。
4. 公司联系邮箱统一为 `contact@weiandata.com`，维护者邮箱统一为 `makunxiang@weiandata.com`。
5. `R CMD check --as-cran` 必须为 0 ERROR、0 WARNING；无法消除的 NOTE 要在 `cran-comments.md` 解释。

### 1.3 包名是否冲突
提交前确认 `IRTC` 这个名字**未被占用**且不过于通用：

```r
# 在联网的 R 里查询 CRAN 现有包名
available::available("IRTC")        # 需要 install.packages("available")
# 或直接看： https://cran.r-project.org/web/packages/IRTC/  （404 即可用）
```

若已被占用或被认为太通用，需改名（见附录 A）。

---

## 2. 环境准备

```r
install.packages(c("devtools", "rhub", "spelling", "urlchecker"))
# Windows 还需 Rtools；macOS 需 Xcode 命令行工具 (xcode-select --install)
```

确认本机能编译（IRTC 含 C++）：`R CMD build` 不报编译错误即可。

---

## 3. 本地完整检查（必须全绿）

**包本身就在仓库根目录**（`DESCRIPTION` 与 `.git` 同级），没有 `IRTC/` 子目录。

```bash
cd "<repo-root>"

# 3.1 清理旧产物
find src -name '*.o' -delete; find src -name '*.so' -delete
rm -rf IRTC.Rcheck IRTC_*.tar.gz

# 3.2 构建源码包
R CMD build .
#   -> 生成 IRTC_<版本>.tar.gz

# 3.3 以 CRAN 标准检查
R CMD check IRTC_<版本>.tar.gz --as-cran
```

> **生成正式提交产物时**，建议从干净的 git 导出再构建，确保 tar.gz 与仓库状态
> 逐字节对应、不夹带本地未跟踪文件：
>
> ```bash
> git archive --format=tar HEAD | tar -x -C /tmp/irtc-src
> R CMD build /tmp/irtc-src
> ```

**期望结果**：仅 `1 NOTE`（`New submission` + DESCRIPTION 拼写误报，见第 8 节）。

> 任何 `ERROR` / `WARNING` 都必须清零才能提交。

也可用 devtools（等价、更友好）：

```r
devtools::check(".", args = "--as-cran")
```

---

## 4. 多平台检查（win-builder R-devel 为必做项）

CRAN 在多个系统上编译你的包，本机过了不代表别的平台过。

> **这不是可选项。** 1.1.0 被退回的两个 ERROR **只在 r-devel 上复现**：测试把
> `"R version"` 写死进断言，而 r-devel 的 `R.version.string` 开头是
> `"R Under development (unstable)"`。本地开发机和仓库的 GitHub Actions 跑的都是
> R release，结构上就测不到这类失败。**提交前必须跑一次 win-builder R-devel。**
> 详见 [实战记录](cran-submission-1.1.1-zh.md)。

用 R-hub v2（基于 GitHub Actions）或 win-builder：

```r
# 4.1 win-builder（最常用，免费，查 Windows 上的 R-devel 和 R-release）
devtools::check_win_devel(".")     # 结果邮件发到 maintainer 邮箱
devtools::check_win_release(".")

# 4.2 R-hub v2（多平台；需要包在 GitHub 仓库里）
rhub::rhub_setup()      # 一次性：在你的 GitHub 仓库配置 workflow
rhub::rhub_check()      # 选 linux / macos / windows 等平台

# 4.3 拼写检查
spelling::spell_check_package(".")   # 专有名词加入 inst/WORDLIST
```

至少跑 **win-builder 的 R-devel**，这是 CRAN 最常用的门槛。

---

## 5. 写 `cran-comments.md`

在仓库根目录放一个 `cran-comments.md`（本仓库已有），告诉 CRAN 你测了什么、如何解释 NOTE、以及差异化说明。模板：

```markdown
## R CMD check results
0 errors | 0 warnings | 1 note

* This is a new submission.

## Test environments
* local macOS (aarch64), R 4.6.0
* win-builder (R-devel and R-release)
* R-hub: linux, macos, windows

## Ownership and licensing
Copyright in IRTC is held by WEIAN DATA TECH (Beijing) Co., Ltd. The package is
distributed under GPL (>= 2). Ownership and external runtime dependency
boundaries are recorded in DESCRIPTION and inst/COPYRIGHTS. MASS is imported;
mvtnorm and sfsmisc are used conditionally from Suggests. Their source code is
not bundled in IRTC.

Maintainer: Kunxiang Ma <makunxiang@weiandata.com>
Company contact: contact@weiandata.com

## Downstream dependencies
There are currently no downstream dependencies (new package).
```

> `cran-comments.md` 不会进入安装包（`.Rbuildignore` 已/应忽略它），只在提交时供审稿人参考。

把它加入 `.Rbuildignore`：

```
^cran-comments\.md$
```

---

## 6. 提交

### 方式一（推荐）：devtools 自动提交
```r
devtools::release(".")
# 会：再跑一次 check -> 显示一系列确认问题 -> 自动上传到 CRAN 提交表单 ->
#     触发确认邮件。按提示逐项确认 yes。
```
或更底层：
```r
devtools::submit_cran(".")
```

### 方式二：网页表单（手动）
1. 打开 <https://cran.r-project.org/submit.html>
2. 填写包名、版本、维护者姓名与邮箱
3. 上传 `IRTC_<版本>.tar.gz`
4. 提交后，CRAN 立即给维护者邮箱发一封**确认链接**邮件——**必须点击确认**，否则提交作废。

---

## 7. 提交之后会发生什么

1. **确认邮件**：立刻到达，点链接确认。
2. **自动 incoming 检查**：CRAN 机器人在 Windows/Linux 上重新 `--as-cran` 检查。
   - 全过 → 进入 `newbies` 人工队列（首次提交一定走人工）。
3. **人工审稿**：志愿者审查。常见反馈：
   - 要求把 `Description` 里的软件包名按规范加单引号。
   - 要求方法附**带 DOI 的文献引用**：`Authors (year) <doi:...>`。
   - 要求 `\value` 文档完整、例子不要 `\dontrun` 滥用、不写临时文件到用户目录等。
   - 可能要求进一步说明包的非平凡功能、许可证或依赖边界。
4. **结果**：
   - **通过** → 几天内出现在 CRAN，自动多平台构建二进制包。
   - **要求修改** → 按邮件意见改，**提升版本号**（如 1.1.0 → 1.1.1；1.1.0 被退回后即照此处理），重跑检查，重新提交，并在 `cran-comments.md` 里写 “Resubmission” 及本次改了什么。

---

## 8. 常见被拒原因清单（提前自查）

> 标 ⚠️ 的两条是 IRTC 1.1.0 **实际被退回的原因**，见 [实战记录](cran-submission-1.1.1-zh.md)。

| 原因 | 自查/修复 |
|---|---|
| ⚠️ Rd 里有非 ASCII（尤其 CJK）字符 | PDF 手册必炸（`Unicode character ... not set up for use with LaTeX`）。`Encoding: UTF-8` **不解决**此问题。`\usage` 用 `\uxxxx` 转义；正文用 `man/macros/irtc.Rd` 的 `\zh` 宏。自查：`LC_ALL=C grep -rn '[^ -~]' man/` |
| ⚠️ 测试把 R 自身的输出措辞写死 | 版本串/错误消息随 R 版本变化，r-devel 上会挂。与 `R.version.string` 等变量比对，勿用字面量。必须跑 win-builder R-devel 才能发现 |
| `Description` 以包名或 “This package” 开头 | 已避免（以 “Self-contained …” 开头） |
| 软件/包名未加单引号 | 按 CRAN 规范检查 `Description` 中的软件包名 |
| 方法无文献引用 | 可在 `Description` 末尾加 `Adams, Wilson & Wang (1997) <doi:...>`（见附录 B） |
| 例子运行过慢（>5s）或用 `\dontrun` 掩盖 | 大计算用 `\donttest{}` 包裹；本包已用 |
| 写文件到非临时目录 | 本包不写文件；如加示例注意用 `tempdir()` |
| 改全局 `options()`/`par()` 不还原 | 本包未改；如加注意 `on.exit()` 复原 |
| 维护者邮箱无法送达 | 确认 `makunxiang@weiandata.com` 可用 |
| 与现有包功能高度重合 | 在提交说明中明确 IRTC 的非平凡功能和使用场景 |
| `LICENSE` 与协议不符 | GPL (>=2) 标准协议，无需附 `LICENSE` 文件 |

---

## 9. 提交后维护义务

- CRAN 会持续在 R-devel 上跑你的包。一旦因上游变化**报错**，你会收到邮件，须在**限期（通常 2 周）内修复**，否则包被 archive（下架）。
- 因此维护者邮箱必须长期有效、定期查看。

---

## 附录 A：若需改包名

1. 改 `DESCRIPTION` 的 `Package:` 字段。
2. 把 `IRTC-package.Rd`、`R/IRTC-package.R`（若有）、NAMESPACE 里相关引用同步改名。
3. C++ 里 `// [[Rcpp::export]]` 的函数名不必改（与包名无关），但 `RcppExports` 重新生成：`Rcpp::compileAttributes()`。
4. 重新 `R CMD build` + `--as-cran`。
5. 用 `available::available("新名")` 确认可用。

## 附录 B：给 Description 加文献引用（可选但常被要求）

在 `Description:` 末尾追加一句，例如多维 IRT 的奠基文献：

```
Methodology follows Adams, Wilson and Wang (1997) <doi:10.1177/0146621697211001>.
```

> 提交前**务必核对 DOI 真实有效**（CRAN 会检查）。不确定就不要写错的 DOI——宁可不加。

## 附录 C：关键命令速查

```bash
# 构建 + 检查
R CMD build .
R CMD check IRTC_<版本>.tar.gz --as-cran

# devtools 一条龙
Rscript -e 'devtools::check(".", args="--as-cran")'
Rscript -e 'devtools::check_win_devel(".")'
Rscript -e 'devtools::release(".")'
```
