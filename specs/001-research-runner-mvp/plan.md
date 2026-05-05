# Implementation Plan: Research Runner MVP

**Branch**: `001-research-runner-mvp` | **Date**: 2026-05-01 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/001-research-runner-mvp/spec.md`

## Summary

Runner = Claude Code 在本工作区按 `CLAUDE.md` + `sop/` 规约行事，加上 4 个 PowerShell 脚本承接机械动作。研究执行、用户多轮修订全程由 Claude 在对话里做；脚本只负责扫描对齐 / run 初始化 / 投递 / queue 读写这些可重复纯机械操作。MVP 不封装任何 slash-skill，保持高对外暴露度，等流程稳定再回头封装。

## Technical Context

**Language/Version**: PowerShell 7+（脚本，跟 SpecKit 已用栈一致）；Markdown + JSON（数据/文档）
**Primary Dependencies**: Claude Code 运行时 + 内置工具（Read / Edit / Write / Bash / Grep / Glob）；MCP 工具栈：默认 agent-reach，回退 Exa MCP / WebSearch / WebFetch
**Storage**: 文件系统（本工作区 + wiki，无数据库）。状态文件 JSON，文档 Markdown
**Testing**: MVP 阶段以手动 smoke run 为主（用 4 个迁移 idea 跑端到端验证）；脚本层不强制 Pester，等需要再加
**Target Platform**: Windows 11 + PowerShell 7+（与 SpecKit init-options 一致）
**Project Type**: 工具型（low-code）——主要靠 Markdown 规约 + 少量脚本，Claude Code 是运行时
**Performance Goals**: 不预设，扫描对齐预期亚秒级（当前 wiki 仅十几个 idea）
**Constraints**: wiki 上只能写 `sources/notes/inbox/`；runner 与 wiki 异步通信只通过文件
**Scale/Scope**: 单用户、单 runner 实例；同时 active run = 1（MVP）；wiki idea 数量预计长期 < 100

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 原则 | 本 plan 如何满足 | 通过 |
|---|---|---|
| **I. Runner 是工具不是知识库** | runner 在 wiki 上的写入只发生在 `deliver.ps1`，目标固定 `sources/notes/inbox/`。其他 wiki 位置 0 写入。`scan-and-align.ps1` 只读 `research/ideas/` | ✅ |
| **II. 不编造（NON-NEGOTIABLE）** | plan 不引入任何"自动填充"机制。研究行为完全由 Claude 在对话里执行，SOP 强制要求带可追溯来源；脚本不参与内容生成 | ✅ |
| **Per-run 工作区** | `new-run.ps1` 为每个 run 建独立 `runs/<id>/`；跨 run 共享状态只在 `queue/` 与 `downloads/` | ✅ |

无违反，无需 Complexity Tracking。

## Project Structure

### Documentation (this feature)

```text
specs/001-research-runner-mvp/
├── plan.md              # This file
├── spec.md              # Already written
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (script CLI contracts)
│   ├── scan-and-align.md
│   ├── new-run.md
│   ├── deliver.md
│   └── queue.md
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
auto_research_agent/
├── CLAUDE.md            # Runner identity + 简短指向 sop/
├── sop/                 # 已就位：workflow / flow-card / templates / README
├── templates/           # 已就位：inbox-output.md
├── scripts/             # 本 plan 新建：4 个 PowerShell 脚本
│   ├── scan-and-align.ps1
│   ├── new-run.ps1
│   ├── deliver.ps1
│   └── queue.ps1        # 共享 queue 读写函数（dot-source 调用）
├── runs/                # 由 new-run.ps1 按需创建
│   └── <YYYY-MM-DD-slug>/
│       ├── idea.md      # 冻结快照
│       ├── log.md       # 追加写
│       ├── notes/       # 中间产物（任务卡 / 判断单 / 决策备忘录）
│       ├── sources/     # 缓存抓取
│       └── output.md    # 成稿草稿，反复迭代直到 user 认可
├── queue/               # 由 queue.ps1 维护
│   ├── pending.json
│   ├── in_flight.json
│   ├── done/<YYYY-QN>.json
│   └── abandoned/<YYYY-QN>.json
├── downloads/           # 已就位（瞬态共享缓存）
├── specs/               # SpecKit
├── .specify/            # SpecKit 配置
└── .claude/             # SpecKit skills
```

**Structure Decision**: 脚本集中 `scripts/`；状态集中 `queue/`；执行实例集中 `runs/`。Run 子目录里的文件结构对齐 SOP 三个产物模板（任务卡 / 判断单 / 决策备忘录在 `notes/` 里），最终 `output.md` 是综合定稿。

## SOP 集成：Runner 如何继承研究流程

### 三件套的角色分工

| 文件 | Runner 如何使用 |
|---|---|
| `sop/workflow.md` | **执行主线**。Runner 按 6 步顺序推进研究（定义问题 → 宽搜建全貌 → 拆逻辑与支撑 → 主动找反对 → 综合判断 → 转动作） |
| `sop/flow-card.md` | **门控与自检工具**。在特定节点触发判断审计（3 道门）、用 7 问快检做自检。不替代 workflow，而是从中抽出关键判断点 |
| `sop/templates.md` | **产物骨架**。Runner 在每道门产出对应模板的填充版本，写入 `runs/<id>/notes/` |

### 三道门的执行映射

| 门 | 触发时机 | Runner 产出 | 文件位置 | 用户交互 | log gate 值 |
|---|---|---|---|---|---|
| 开题门 | run 启动后、开始搜索前 | 研究任务卡（模板 1 填充版） | `notes/task-card.md` | **等用户确认**才开搜 | `opening` |
| 中途门 | 第一轮建图完成后 | 判断单（模板 2 填充版） | `notes/judgment.md` | **等用户确认**才进第二轮 | `midway` |
| 收尾门 | 综合判断形成后 | 决策备忘录（模板 3 填充版） | `notes/memo.md` | **等用户确认**后再合成 `output.md` | `closing` |

收尾门确认后，Runner 将 memo 内容转写为面向未来阅读者的正式稿 `output.md`（格式按 `templates/inbox-output.md`）。memo 是面向用户做 review 的判断结论，output.md 是面向 wiki 的内容交付物——两者读者不同、写法不同。

**为什么 memo 先于 output.md**：memo 沿用 SOP 原有的决策备忘录模板，类似研究摘要——用户扫一眼就能判断研究方向是否正确。方向对了再看细节；方向错了直接打回重做，节省双方精力。这是先验证 SOP 现有流程在 runner 场景下是否仍然有效的一次尝试。

### 角色转换适配

原 SOP 假设用户 = 执行者。Runner 场景下用户 = 审核者/方向修正者，因此：

| SOP 环节 | Runner 行为 |
|---|---|
| "先问自己到底在回答什么" | Runner 读 idea 文件后，若意图/决策问题仍模糊，**必须反问用户**，不得自行脑补。第一步错则全链路错 |
| "第二轮只补关键缺口" | Runner 自行判断哪些是关键缺口并执行，不需要每次问用户 |
| "7 问快检" | Runner 自检工具——在每道门产出前内部过一遍，不显式输出给用户（除非自检发现问题需要问用户） |
| 因果推断意识 / Motivation-Insight 筛选 | Runner 内化为研究质量标准，体现在产出质量中，不单独输出 |

### Workflow 6 步与 Runner 实际节奏的对应

```
Workflow 步骤          Runner 动作                           门控
─────────────────────────────────────────────────────────────────
1. 定义问题      →  读 idea → 填 task-card → 反问(如需)  → [开题门]
2. 宽搜建全貌    →  按检索面执行第一轮搜索
3. 拆逻辑与支撑  →  提取观点、逻辑链、支撑事实
                    ↓ 合并为判断单                        → [中途门]
4. 找反对意见    →  第二轮补关键缺口 + 反方验证
5. 综合判断      →  形成决策备忘录                        → [收尾门]
6. 转动作        →  合成 output.md → 用户多轮修订 → 投递
```

### 未在本 feature 中改动 SOP 的部分

MVP 直接复用 `sop/` 三件套原文，不做重写。以下已识别的潜在改善点留给后续迭代：

- flow-card 中"资产配置类主题的默认收紧"——目前作为可选附加槽位存在，runner 按 idea 主题自行判断是否启用
- templates 中"用户解读/感想"字段——runner 场景下由用户在确认环节口头表达，不强制写入模板
- workflow 第 6 节"当前还要继续研究的重点"——属于 SOP 自身演进方向，不影响 runner 执行

## Complexity Tracking

无违反，本节空。
