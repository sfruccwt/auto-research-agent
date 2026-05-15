# Tasks: Runner Lifecycle & SOP Refinement

**Input**: Design documents from `specs/002-runner-lifecycle-sop/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: 无自动化测试。验证通过实际 run 执行（手动集成测试）。

**Organization**: Tasks grouped by user story. US1/US2 为 P1 可先行，US3/US4 为 P2 可后续并行。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: 创建新目录结构

- [x] T001 创建本地 idea 池目录 `ideas/`，添加 `.gitkeep`
- [x] T002 [P] 创建 closed 队列目录 `queue/closed/`，添加 `.gitkeep`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 扩展 queue.ps1——US2（close-run）和 scan-and-align 扩展均依赖这些函数

**⚠️ CRITICAL**: US2 和 US3 的 scan-and-align 扩展依赖此阶段完成

- [x] T003 在 `scripts/queue.ps1` 中新增 `Add-QueueClosed` 函数，按 `contracts/queue.md` 规范实现，结构与 `Add-QueueDone` 对称，写入 `queue/closed/<YYYY-QN>.json`
- [x] T004 [P] 在 `scripts/queue.ps1` 中新增 `Get-QueueClosed` 函数，支持 `-Quarter` 参数，与 `Get-QueueDone` 对称
- [x] T005 [P] 在 `scripts/queue.ps1` 中新增 `Remove-QueueClosed` 函数，从所有季度文件中移除指定 RunId 的记录

**Checkpoint**: queue.ps1 扩展完成，可开始 US1/US2 实现

---

## Phase 3: User Story 1 — 双 idea 池与就地创建 (Priority: P1) 🎯 MVP

**Goal**: 用户在会话中口述研究主题即可直接开 run，无需先去 wiki 写 idea 文件

**Independent Test**: 用户说"我想研究 X"，runner 调 `new-run.ps1 -Topic "X"`，验证本地池 idea 文件创建、run 目录初始化、`source_idea` 指向本地池路径

### Implementation for User Story 1

- [x] T006 [US1] 扩展 `scripts/new-run.ps1`：新增 `-Topic` 和 `-Slug` 参数集（与 `-IdeaPath` 互斥），按 `contracts/new-run.md` 规范实现 —— 包括 slug 生成、`ideas/` 下创建 idea 文件（复用 Wiki frontmatter schema，`source: runner-local`）、idea 文件路径作为 IdeaPath 进入已有流程
- [x] T007 [US1] 修改 `scripts/new-run.ps1` Step 5（冻结快照）：在 `idea.md` 中追加 `source_idea` 字段，记录 idea 原始路径（本地池或 wiki 路径）
- [x] T008 [US1] 扩展 `scripts/scan-and-align.ps1`：新增本地池扫描（Step 1a），读取 `ideas/*.md` frontmatter，按 `contracts/scan-and-align.md` 分类规则生成 `runnable_local` 分类；输出增加 `local_ideas_count` 字段
- [x] T008a [US1] 扩展 `scripts/deliver.ps1`：确保 `runs/<id>/idea.md` 中的 `source_idea` 字段传递到 inbox 输出文件的 frontmatter 中（FR-103——本地池启动的 run 投递后，inbox 文件必须如实记录本地池路径）

**Checkpoint**: 就地创建 idea 并开 run 的完整路径可用，扫描对齐能发现本地池 idea，投递时 source_idea 正确传递

---

## Phase 4: User Story 2 — 轻量结项 (Priority: P1)

**Goal**: run 有结论但不适合投递时，记录结论、标记 closed、不产生 inbox 文件

**Independent Test**: 跑一个 run 到有结论阶段，调 `close-run.ps1`，验证 closing-summary.md 写入、log.md 记录 closed 事件、queue/closed/ 有记录、in_flight 移除

### Implementation for User Story 2

- [x] T009 [US2] 创建 `scripts/close-run.ps1`，按 `contracts/close-run.md` 完整实现：校验 RunId、校验非 delivered、写入 `closing-summary.md`、追加 log.md、调用 `Add-QueueClosed`、调用 `Remove-QueueInFlight`、输出路径
- [x] T010 [US2] 扩展 `scripts/deliver.ps1` Step 7：投递成功后检查 `queue/closed/` 是否有该 RunId 记录，有则调用 `Remove-QueueClosed` 移除（支持 closed → delivered 状态迁移）
- [x] T011 [US2] 扩展 `scripts/scan-and-align.ps1`：新增 Step 3a（加载 `queue/closed/` 记录），Step 4 增加 `closed` 分类，本地池 idea 有 closed 记录时归入 closed 分类

**Checkpoint**: 轻量结项完整路径可用，closed run 在扫描对齐中正确分类

---

## Phase 5: User Story 3 — 派生 idea 与子课题拆分 (Priority: P2)

**Goal**: run 过程中派生的新研究点被结构化记录，扫描对齐时可发现未处理的派生 idea

**Independent Test**: 在 run 的 `notes/derived-ideas.md` 中手动写入一条派生记录（child_run 为空），运行 scan-and-align 验证该条目出现在 `derived_ideas` 分类中

### Implementation for User Story 3

- [x] T012 [US3] 扩展 `scripts/scan-and-align.ps1`：新增 Step 3b，遍历 `runs/*/notes/derived-ideas.md`，解析 `---` 分隔的记录块，筛出 `child_run` 为空的条目，输出到 `derived_ideas` 分类
- [x] T013 [US3] 修改 `scripts/new-run.ps1`：当传入的 idea 来自派生 idea 时（由 Claude 在对话中构造 idea 文件并传 `-IdeaPath`），确保冻结快照的 `idea.md` frontmatter 中保留 `derived_from` 字段
- [x] T013a [US3] 在 `CLAUDE.md` "Working a run" 章节增加"子课题结论回填"指引：子课题 run 完成后，如何将结论追加到母 run 的 `notes/` 或链接子课题产出（FR-113b）；回填方式由用户指示，runner 提示可选操作

**Checkpoint**: 派生 idea 可被扫描发现，子课题 run 能引用母 run，回填流程有文档指引

---

## Phase 6: User Story 4 — SOP 模板与流程修订 (Priority: P2)

**Goal**: 10 条 SOP backlog 全量落地到 SOP 三件套，提升后续 run 的执行质量

**Independent Test**: 修订完成后检查每条 FR（114-122）对应的 SOP 文本是否到位；后续首次 run 验证新流程是否自然引导

### Implementation for User Story 4

- [x] T014 [P] [US4] 修订 `sop/templates.md` 模板 1（研究任务卡）：(1) "真正要回答的问题"标记为迭代字段并加迭代提示（T1/FR-114）；(2) "优先开的检索面"下增加工具分配表，默认社区面双路 WebSearch + agent-reach（T2/FR-115）；(3) "本轮收尾门槛"下增加关键术语确认提示
- [x] T015 [P] [US4] 修订 `sop/templates.md` 模板 2（判断单）：(1) 删除"首个不可信信息跳点"整个区块（T3/FR-118）；(2) "第一轮地图"下增加术语展开提示行
- [x] T016 [P] [US4] 修订 `sop/templates.md` 模板 3（决策导向研究备忘录）：(1) 删除"首个不可信信息跳点"整个区块（T3/FR-118）；(2) 在"当前判断"和"成立前提"之间增加"关键概念展开"结构化区块（T4/FR-117e）
- [x] T017 [US4] 修订 `sop/workflow.md`：(1) 顶部增加"全阶段要求：核心概念清晰描述"（W7/FR-117）；(2) 第 1 步增加"关键词压测"子节（W2/FR-120）；(3) 第 2 步后插入"第 2.5 步：Motivation 校准"（W1/FR-116）；(4) 中途门后增加"子课题拆分检查"（W3/FR-120a）；(5) 备忘录写作增加"证据链扣紧"要求（W4/FR-121）；(6) 路径比较增加"路径定义要求"（W5/FR-122）；(7) 收尾门增加"memo 与 output 的区分"说明（W6/FR-119）
- [x] T018 [US4] 修订 `sop/flow-card.md`：(1) 开题门增加"关键词压测"（F3）；(2) 中途门增加"motivation 校准 + 子课题拆分检查"（F1）；(3) 7 问快检删除"首个不可信信息跳点"，第 5 问改为"证据链是否扣紧"（F2）

**Checkpoint**: SOP 三件套修订完成，10 条 backlog 全部覆盖

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: 收尾整理

- [x] T019 更新 `sop/backlog.md`：将 10 条待改进项移到"已改进"区，标注对应 FR 编号和修订日期
- [x] T020 [P] 更新 `CLAUDE.md`：Working a run 章节增加本地池 idea 启动路径说明；脚本契约引用增加 `specs/002-runner-lifecycle-sop/contracts/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 无依赖，立即可开始
- **Foundational (Phase 2)**: 依赖 Phase 1（需要 `queue/closed/` 目录存在）
- **US1 (Phase 3)**: 依赖 Phase 1（需要 `ideas/` 目录存在）。不依赖 Phase 2
- **US2 (Phase 4)**: 依赖 Phase 2（需要 queue.ps1 的 Closed 函数）
- **US3 (Phase 5)**: 依赖 Phase 2（scan-and-align 的扩展基于 Phase 2 完成的 queue 函数）。与 US1/US2 的 scan-and-align 修改有文件冲突，建议在 US1/US2 之后执行
- **US4 (Phase 6)**: 无脚本依赖，可与 US1-US3 并行。修改不同文件集（sop/）
- **Polish (Phase 7)**: 依赖所有 US 完成

### User Story Dependencies

- **US1 (P1)**: 仅依赖 Phase 1 → 可最先开始
- **US2 (P1)**: 依赖 Phase 2 → Phase 1 后即可开始
- **US3 (P2)**: 建议在 US1/US2 之后（scan-and-align.ps1 同文件修改）
- **US4 (P2)**: 独立于其他 US → 可随时开始

### Within Each User Story

- scan-and-align.ps1 修改跨 US1/US2/US3，建议按 US 顺序依次添加，避免合并冲突
- deliver.ps1 修改跨 US1（T008a: source_idea 传递）和 US2（T010: closed→delivered 迁移），建议按 US 顺序依次修改
- SOP 三件套（US4）的三个文件修改标记 [P]，templates.md 的三个模板修改也标记 [P]

### Parallel Opportunities

- T001 / T002: 两个目录创建可并行
- T004 / T005: Get-QueueClosed 和 Remove-QueueClosed 可并行（都不依赖对方）
- T014 / T015 / T016: templates.md 三个模板修改虽在同一文件，但修改区域不重叠，标记 [P]
- **US1 与 US4 可完全并行**（修改不同文件集）
- **US2 与 US4 可完全并行**（修改不同文件集）

---

## Parallel Example: Phase 2

```
# queue.ps1 的三个新函数，T003 先做（Add 是基础），T004/T005 可并行：
T003: Add-QueueClosed in scripts/queue.ps1
  ↓ 完成后
T004: Get-QueueClosed in scripts/queue.ps1  ← 可并行
T005: Remove-QueueClosed in scripts/queue.ps1  ← 可并行
```

## Parallel Example: US4

```
# templates.md 三个模板可并行修改：
T014: 模板 1（研究任务卡）in sop/templates.md  ← 可并行
T015: 模板 2（判断单）in sop/templates.md  ← 可并行
T016: 模板 3（备忘录）in sop/templates.md  ← 可并行
  ↓ 全部完成后
T017: workflow.md 修订
T018: flow-card.md 修订
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Setup（创建目录）
2. Complete Phase 3: US1（就地创建 idea + 本地池扫描）
3. **STOP and VALIDATE**: 口述主题 → 开 run → 扫描对齐能看到本地 idea
4. 这一步已经消除了最大摩擦点

### Incremental Delivery

1. Phase 1 + Phase 2 → 基础设施就绪
2. US1 → 就地创建可用 → 验证
3. US2 → 轻量结项可用 → 验证
4. US3 → 派生 idea 可发现 → 验证
5. US4 → SOP 修订落地 → 首次 run 验证新流程
6. Phase 7 → 收尾

### 推荐执行顺序（单人）

Phase 1 → Phase 2 → US1 → US2 → US4（可穿插）→ US3 → Phase 7

---

## Notes

- 本项目无自动化测试，验证依赖实际 run 执行
- scan-and-align.ps1 被 US1/US2/US3 三个 US 修改，建议按 US 顺序依次扩展
- SOP 修订（US4）是纯文本修改，可随时穿插进行
- 所有脚本修改保持向后兼容——现有 run 和现有调用方式不受影响
