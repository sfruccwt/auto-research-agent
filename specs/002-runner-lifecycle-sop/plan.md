# Implementation Plan: Runner Lifecycle & SOP Refinement

**Branch**: `002-runner-lifecycle-sop` | **Date**: 2026-05-10 | **Spec**: `specs/002-runner-lifecycle-sop/spec.md`
**Input**: Feature specification from `specs/002-runner-lifecycle-sop/spec.md`

## Summary

基于 MVP 两次测试 run 暴露的 known-gaps 和 SOP backlog，执行第二轮改进：(1) 建立双 idea 池（Wiki + 本地），支持就地创建 idea 直接开跑；(2) 新增轻量结项机制（`closed` 终态）；(3) 支持派生 idea 和子课题拆分记录；(4) 批量修订 SOP 三件套（10 条 backlog 全量落地）。技术路径为扩展现有 4 个 PowerShell 脚本 + 新建 1 个脚本 + 修订 3 个 SOP 文档。

## Technical Context

**Language/Version**: PowerShell 7+ (pwsh)
**Primary Dependencies**: 无外部依赖，纯 PowerShell + 文件系统操作
**Storage**: JSON 文件（queue/）+ Markdown 文件（runs/、ideas/、sop/）
**Testing**: 手动集成测试（通过实际 run 验证）
**Target Platform**: Windows 11 (D:\developing_project\auto_research_agent\)
**Project Type**: SOP + 脚本工具链（Claude Code 驱动的研究 runner）
**Performance Goals**: N/A（单用户、低频操作）
**Constraints**: 不扩大 runner 对 wiki 的写权限（仅 inbox）
**Scale/Scope**: 单用户，预期 runs 数十个量级

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Runner 是工具，不是知识库

| 检查项 | 结果 |
|---|---|
| 本地池 idea 是否构成"知识存储" | ✅ 通过 — 本地池存储的是研究种子（主题描述），不是研究成果。成果仍然通过 inbox 投递到 wiki |
| ideas/ 目录是否扩大 wiki 写权限 | ✅ 通过 — ideas/ 在 runner 工作区内，不涉及 wiki 写权限 |
| 轻量结项是否在 runner 内存储知识 | ✅ 通过 — closing-summary 是过程记录（结论摘要 + 方向），不是知识持久化。最终知识仍需通过投递到 wiki 完成持久化 |

### Principle II: 不编造

| 检查项 | 结果 |
|---|---|
| 新功能是否引入编造风险 | ✅ 通过 — 本 feature 改的是流程机制和脚本，不涉及研究内容产出。SOP 修订中 FR-118（删除不可信信息跳点）和 FR-121（证据链扣紧）反而加强了不编造约束 |

### Principle III: 用户掌握判断权

| 检查项 | 结果 |
|---|---|
| 子课题拆分由谁决策 | ✅ 通过 — FR-113a 明确"runner 提示但不自动决策"，FR-117 的概念展开采用"标记+用户确认"流程 |
| 轻量结项由谁触发 | ✅ 通过 — FR-105 明确"何时结项由用户判断" |
| 派生 idea 处理权 | ✅ 通过 — 派生 idea 只记录，用户决定跑哪个 |

### Additional Constraints: Per-run 工作区

| 检查项 | 结果 |
|---|---|
| 新文件是否在对应 run 目录内 | ✅ 通过 — closing-summary.md、derived-ideas.md、child-results.md 均在 runs/<id>/notes/ 下 |
| 跨 run 共享是否限于 queue/ | ✅ 通过 — ideas/ 是 idea 存储（run 前），不是跨 run 共享状态。queue/closed/ 与 queue/done/ 同级 |

**Constitution Gate: ✅ PASS — 无违反项**

## Project Structure

### Documentation (this feature)

```text
specs/002-runner-lifecycle-sop/
├── spec.md
├── plan.md              # 本文件
├── research.md          # 9 项设计决策
├── data-model.md        # 实体扩展定义
├── contracts/
│   ├── new-run.md       # 扩展：+Topic 参数
│   ├── close-run.md     # 新建：轻量结项脚本
│   ├── scan-and-align.md # 扩展：双池+派生+closed
│   ├── queue.md         # 扩展：+Closed 函数
│   ├── deliver.md       # 小改：closed→delivered 迁移
│   └── sop-revisions.md # SOP 三件套修订清单
├── checklists/          # tasks 完成后生成
└── tasks.md             # 下一步 /speckit-tasks 生成
```

### Source Code (repository root)

```text
scripts/
├── new-run.ps1          # 修改：新增 -Topic 参数集
├── close-run.ps1        # 新建：轻量结项脚本
├── scan-and-align.ps1   # 修改：双池扫描 + 派生 idea + closed
├── queue.ps1            # 修改：新增 Closed 系列函数
└── deliver.ps1          # 修改：closed→delivered 迁移

ideas/                   # 新建目录：本地 idea 池

sop/
├── workflow.md          # 修改：7 处修订（W1-W7）
├── flow-card.md         # 修改：3 处修订（F1-F3）
├── templates.md         # 修改：4 处修订（T1-T4）
└── backlog.md           # 修改：已完成条目移到"已改进"

queue/
└── closed/              # 新建目录：closed 状态记录
```

**Structure Decision**: 沿用现有 flat 结构。脚本在 `scripts/`，SOP 在 `sop/`，新增 `ideas/` 目录和 `queue/closed/` 目录。不引入 src/ 或 tests/ 结构——本项目是 SOP + 脚本工具链，不是应用程序。

## Post-Design Constitution Re-Check

Phase 1 设计完成后重新检查：

- **ideas/ 目录**：仅存储 idea 种子文件（标题+描述），不是知识。✅
- **close-run.ps1**：写入 closing-summary 到 run 目录内，不触及 wiki。✅
- **scan-and-align.ps1 扩展**：只读操作，不写文件。✅
- **SOP 修订**：FR-117（概念展开）和 FR-120a（子课题拆分）均保持用户判断权。✅
- **derived-ideas.md**：追加式记录在 run 目录内，不跨 run 共享。✅

**Post-Design Gate: ✅ PASS**

## Complexity Tracking

无 Constitution 违反项，本节不适用。
