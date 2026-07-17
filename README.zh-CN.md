# IRTC

[English](README.md) | **简体中文**

[![R CMD check](https://github.com/weiandata/IRTC/actions/workflows/r-check.yml/badge.svg)](https://github.com/weiandata/IRTC/actions/workflows/r-check.yml)
[![License: GPL v2+](https://img.shields.io/badge/License-GPL%20%3E%3D%202-blue.svg)](https://www.gnu.org/licenses/gpl-2.0)

R 语言的项目反应理论（IRT）分析包：**从一张表格直接到一份能读懂的报告**，不需要你是统计程序员。

市面上的 IRT 软件包默认你已经把数据整理成了干净的数值矩阵，也默认你能自己从模型对象里把结果抠出来。IRTC 把这一头一尾也做完了，同时完整保留底层的专业接口。

> **当前状态**：已提交 CRAN，等待审核。通过前请从 GitHub 安装（见[安装](#安装)）。
> 接口已稳定，1.1.x 向后兼容 1.0。

## 实际效果

一行代码从数据到模型，摘要是给人读的大白话，而不是一堆系数。下面这段用内置示例数据可直接运行：

```r
library(IRTC)
data(data.sim.rasch)
mod <- irtc(data.sim.rasch, model = "1PL")   # 传文件路径用法完全相同
plain_summary(mod)
```

```text
------------------------------------------------------------
总体结论
------------------------------------------------------------
本次测验共 2000 人作答 40 个题目。分数信度为 0.87（良好）。40 个题目中有 40 个质量为“好”或“可用”。

------------------------------------------------------------
题目质量
------------------------------------------------------------
题目质量分布：好 40 个，可用 0 个，需检查 0 个，建议修改 0 个。
内部一致性（Cronbach's alpha）：0.8658。

------------------------------------------------------------
样本能力分布
------------------------------------------------------------
能力平均值 0，离散程度（标准差）0.93，范围 -2.92 至 3.14。
能力值为 logit 量尺；0 代表群体平均水平，数值越大能力越强。

------------------------------------------------------------
下一步
------------------------------------------------------------
导出三个 Excel 结果表：irtc_excel(mod)。
生成分析报告：irtc_report(mod, "report.docx")。
查看完整技术结果：summary(mod)。
```

上面是节选，实际还会打印“分析概况”一节。

> 上面是 `options(irtc.lang = "zh")`（默认）下的中文输出；设为 `"en"` 即为英文。

`irtc()` 可读取 Excel/CSV/TSV/SPSS/Stata/SAS 文件或 R 对象，自动清洗数据（并留下可追溯的日志）、按答案键给 A/B/C/D 原始作答评分、做数据检查，然后估计模型。所有专业参数都原样透传。

## 安装

```r
# install.packages("remotes")
remotes::install_github("weiandata/IRTC")
```

需要 R (>= 3.5.0) 和 C++ 编译工具链（Windows 上需 Rtools）。Excel、SPSS 和报告功能依赖可选包（`readxl`、`writexl`、`haven`、`officer`）；用到哪个缺哪个，IRTC 会直接告诉你装什么。

## 模型与能力

- **模型**：Rasch / 1PL、PCM、RSM、2PL、GPCM，支持二分与有序多分题目。
- **设计**：单维与题间多维、潜在回归、多组、抽样权重。
- **输出**：题目参数、EAP 能力估计与标准误、AIC/BIC、嵌套模型比较（`anova`）、题目拟合与经典测量统计量。
- **规模**：三套引擎（`grid`、`streaming`、`auto`）自动路由；streaming 在「被试 × 题目 × 维度」很大时限定内存占用。可选的受控精度模式会报告**实测**近似误差，精确计算仍是默认。
- **双语**：`options(irtc.lang = "zh")`（默认）或 `"en"`。

## 三类用法

**调查与测评人员** —— 数据进、结果出：

```r
mod <- irtc("问卷数据.xlsx", model = "1PL")
plain_summary(mod)                            # 大白话摘要
irtc_excel(mod, dir = "results")              # 题目质量 / 题目参数 / 被试能力
irtc_report(mod, "report.docx", audience = "decision")
```

**统计人员** —— 完整专业接口，不做任何隐藏：

```r
data(data.sim.rasch)
mod <- irtc.mml(resp = data.sim.rasch)
summary(mod)
irtc_itemfit(mod)
```

**AI 助手与自动化流水线** —— 机器可读的输入与输出：

```r
chk <- irtc_check_data(irtc_read("responses.csv", verbose = FALSE))
if (chk$ok) {
    mod <- irtc("responses.csv", model = "2PL", verbose = FALSE)
    irtc_json(mod, "results.json")   # 结构稳定，参见 inst/llms.txt
}
```

报错是结构化条件对象，带错误码、原因和修复建议。

完整示例见 [examples/basic-usage.R](examples/basic-usage.R)。

## 文档

- [中文使用手册](docs/manuals/IRTC手册-中文-V1.1.0.md) —
  [English manual](docs/manuals/IRTC-Manual-English.md)
- 在 R 里：`?irtc`、`?irtc.mml`、`help(package = "IRTC")`
- [文档索引](docs/README.md)

## 参与贡献

欢迎提 issue 和 PR，分支、提交、测试与评审要求见 [CONTRIBUTING.md](CONTRIBUTING.md)。安全问题请通过 [SECURITY.md](SECURITY.md) 的私密渠道报告，不要发公开 issue。

内置数据集由 IRTC 仿真生成，可用 [`scripts/gen_data.R`](scripts/gen_data.R) 复现，不含任何真实被试数据。

## 许可证

GPL (>= 2)，见 [LICENSE](LICENSE) 与 [`inst/COPYRIGHTS`](inst/COPYRIGHTS)。

版权所有 © 2026 惟安数据科技（北京）有限公司 —— <contact@weiandata.com>
