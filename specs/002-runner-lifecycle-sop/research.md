# Research: Runner Lifecycle & SOP Refinement

**Feature**: 002-runner-lifecycle-sop | **Date**: 2026-05-10

---

## Decision 1: new-run.ps1 如何支持"就地创建 idea"

**Decision**: 为 `new-run.ps1` 新增 `-Topic` 参数（与 `-IdeaPath` 互斥）。传 `-Topic` 时，脚本在 `ideas/` 下自动创建 idea 文件，再走正常的 run 初始化流程。

**Rationale**:
- Spec FR-102 要求"用户在会话中直接描述研究主题时，Runner 在本地池 `ideas/` 中创建 idea 文件"
- 保持 `-IdeaPath` 向后兼容：从 Wiki 池或本地池已有 idea 文件启动的路径不变
- `-Topic` 是一个字符串参数，脚本据此生成 idea 文件（frontmatter + 标题），slug 由脚本从 topic 中生成
- idea 文件写入 `ideas/YYYY-MM-DD-<slug>.md`，frontmatter 复用 Wiki idea schema（`source: runner-local`、`captured`、`route`、`route_reason`、`status: pending`），保持两池结构一致

**Alternatives considered**:
- 由 Claude 在对话中手写 idea 文件再调 `-IdeaPath`：增加摩擦，违背 FR-102 的"就地"精神
- 新建独立脚本 `create-local-idea.ps1`：增加脚本数量，且 spec 明确说"均为修改现有 contract，不新增脚本"

---

## Decision 2: 轻量结项机制——新建 close-run.ps1 还是扩展 deliver.ps1

**Decision**: 新建 `scripts/close-run.ps1`。不扩展 `deliver.ps1`。

**Rationale**:
- `deliver.ps1` 的职责是"投递到 wiki inbox"，轻量结项的核心特征恰恰是"不投递"。将两者混在一起违反单一职责
- `close-run.ps1` 接受 `-RunId`、`-Summary`（结论摘要）、`-Reason`（不投递原因）、`-NextSteps`（后续方向，可选）
- 脚本写入 `closing-summary.md`、追加 `log.md` 事件、将记录移入 `queue/closed/<quarter>.json`、从 `in_flight.json` 移除
- Spec 的"Contract 影响"部分说"均为修改现有 contract，不新增脚本"——这指的是 US1（双 idea 池）的 contract 影响。US2 的轻量结项是全新功能路径，新建脚本是合理的

**Alternatives considered**:
- 扩展 deliver.ps1 加 `-CloseOnly` 开关：语义混乱，deliver 名字暗示投递
- 由 Claude 手动写文件不走脚本：缺乏一致性保证，且 queue 状态更新容易遗漏

---

## Decision 3: queue.ps1 如何支持 closed 状态

**Decision**: 在 `queue.ps1` 中新增 `Add-QueueClosed` 和 `Get-QueueClosed` 函数，结构与 `Add-QueueDone`/`Get-QueueDone` 完全对称。存储目录为 `queue/closed/<quarter>.json`。

**Rationale**:
- Spec FR-107 明确要求 `queue/closed/<quarter>.json`
- 与 done/abandoned 保持对称的目录结构和 API，降低认知负担
- item schema: `{ run_id, idea_slug, closed, summary, reason }`

---

## Decision 4: scan-and-align.ps1 如何支持双池 + 派生 idea + closed 状态

**Decision**: 扩展 `scan-and-align.ps1`，增加三个新能力：
1. **本地池扫描**：扫描 `ideas/*.md`，与 `queue/` 状态对齐，分类规则同 spec Assumptions 表
2. **派生 idea 汇总**：遍历所有 `runs/*/notes/derived-ideas.md`，提取未处理条目（无 `child_run` 字段或 `child_run` 为空）
3. **closed 状态分类**：读取 `queue/closed/` 记录，在报告中增加 `closed` 分类

输出 JSON 的 `categories` 从 3 类扩展为 6 类：`runnable`、`runnable_local`、`awaiting_ingest`、`previously_abandoned`、`derived_ideas`、`closed`。

**Rationale**:
- Spec FR-104a、FR-109、FR-112 分别要求这三项能力
- 保持单脚本输出完整 alignment report，不拆分脚本
- 本地池 idea 和 wiki 池 idea 使用不同分类键（`runnable` vs `runnable_local`），按来源标注

**Alternatives considered**:
- 拆成多个扫描脚本：增加调用复杂度，Claude 需要多次调用再手动合并
- 合并 `runnable` 和 `runnable_local` 为一类加 `source` 字段：可行但 spec 明确要求"按来源标注分类"，独立分类更清晰

---

## Decision 5: derived-ideas.md 的格式设计

**Decision**: 采用 YAML-like 列表格式，每条 derived idea 作为一个独立 block，用 `---` 分隔。

```markdown
# Derived Ideas

---
title: <标题>
description: <一句话描述>
relation: <与母课题的关系>
recorded: <ISO timestamp>
child_run: <启动后回填的 run-id，初始为空>
---

title: <标题>
...
```

**Rationale**:
- Spec FR-111 要求每条记录包含标题、描述、关系、时间；启动后回填 `child_run`
- 纯 markdown 格式便于 Claude 追加写入，无需 JSON 解析
- `scan-and-align.ps1` 可用简单正则解析提取条目
- 用 `---` 分隔而非 markdown 列表，是因为每条有多个字段，结构化程度更高

---

## Decision 6: 轻量结项后再投递的流程

**Decision**: 不需要新脚本。用户说"把 <run-id> 正式投递"时，Claude 基于 `closing-summary.md` 和 `notes/memo.md` 生成 `output.md`，然后调用现有的 `deliver.ps1`。`deliver.ps1` 不需要知道 run 之前是否 closed。

**Rationale**:
- Spec Edge Case 明确允许"轻量结项后又想投递"
- `deliver.ps1` 的逻辑是通用的：校验 `output.md` → 拷贝到 inbox → 更新 queue
- closed → delivered 的状态迁移：`deliver.ps1` 调用 `Add-QueueDone` 并 `Remove-QueueInFlight`。但 closed 的 run 不在 `in_flight`，所以 `Remove-QueueInFlight` 会静默无操作（当前实现已兼容）。需要额外处理：从 `queue/closed/` 中移除对应记录

**Action**: `deliver.ps1` 需小幅修改——投递成功后，额外检查 `queue/closed/` 中是否有该 run 的记录，有则移除（状态从 closed 迁移到 done）

---

## Decision 7: 子课题结论回填机制

**Decision**: 回填由 Claude 在对话中执行，不需要脚本自动化。回填动作是"将子 run 的 `closing-summary.md` 或 `output.md` 中的关键结论追加到母 run 的 `notes/child-results.md`"。

**Rationale**:
- Spec FR-113b 明确说"具体回填方式由用户指示"
- 回填是低频操作，且需要用户判断哪些结论值得回填、放在哪里
- 自动化回填需要理解语义（哪些是关键结论），超出脚本能力范围
- Claude 在对话中执行回填时，可参考母 run 的 `derived-ideas.md` 找到子 run，再读取子 run 产物

---

## Decision 8: SOP 模板修订策略

**Decision**: 直接修改 `sop/workflow.md`、`sop/flow-card.md`、`sop/templates.md` 三个文件。所有 10 条 backlog 在一轮 tasks 中全部处理。

**Rationale**:
- Spec Assumption 明确说"10 条 backlog 在本 feature 中全部处理"和"模板/流程文本层面的修改，工作量可控"
- 修订内容已在 spec FR-114 到 FR-122 中逐条明确
- 不需要新建文件或新模板

**具体修订映射**（FR → backlog 条目 → 文件）:

| FR | Backlog 条目 | 修改文件 |
|---|---|---|
| FR-114 | 开题卡迭代式填写 | templates.md 模板 1 |
| FR-115 | 搜索路径默认开 agent-reach | templates.md 模板 1 |
| FR-116 | Motivation 持续捕获 | workflow.md |
| FR-117 | 核心概念展开（全阶段） | templates.md 模板 1/2/3 + workflow.md |
| FR-118 | 删除不可信信息跳点 | templates.md 模板 2/3 |
| FR-119 | memo vs output 区分 | workflow.md |
| FR-120 | 关键词压测 | workflow.md |
| FR-120a | 子课题拆分检查 | workflow.md |
| FR-121 | 证据链扣紧 | workflow.md |
| FR-122 | 路径定义清晰度 | workflow.md |

---

## Decision 9: closing-summary.md 模板设计

**Decision**: 在 `sop/templates.md` 中增加模板 4：结项总结。由 `close-run.ps1` 的参数填充基本字段，Claude 可在对话中补充。

```markdown
# 结项总结

## 结论摘要
[1-3 句话]

## 不投递原因
[为什么不适合产出正式 output]

## 后续方向建议
- [如有子课题需要先研究，列在这里]
- [如有需要等待的外部条件]

## 关联
- 派生 idea: [指向 derived-ideas.md 中的条目，如有]
- 母课题: [如本 run 本身是子课题]
```

**Rationale**:
- Spec FR-106 定义了三个必填内容
- 加上关联信息，支持树状研究的回溯
