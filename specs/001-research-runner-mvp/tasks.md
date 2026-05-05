# Tasks: Research Runner MVP

**Input**: Design documents from `specs/001-research-runner-mvp/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/, research.md, quickstart.md

**Tests**: 手动 smoke run（用迁移 idea 跑端到端），无自动测试框架。

**Organization**: Tasks grouped by user story. US1 = MVP scope.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 / US2 / US3

---

## Phase 1: Setup

**Purpose**: 创建目录结构和空状态文件，让脚本有可写入的目标位置

- [ ] T001 Create `scripts/` directory at repository root
- [ ] T002 Create `queue/` directory structure with initial empty JSON files: `queue/pending.json`, `queue/in_flight.json`, `queue/done/` (dir), `queue/abandoned/` (dir) — each JSON initialized with `{"version": 1, "items": []}`
- [ ] T003 [P] Create `runs/.gitkeep` to ensure directory is tracked

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: queue.ps1 是其他三个脚本的共享依赖，必须先完成

**⚠️ CRITICAL**: new-run / deliver / scan-and-align 全部 dot-source queue.ps1，此 phase 完成前不能开始任何 user story

- [ ] T004 Implement `scripts/queue.ps1` shared function library per `specs/001-research-runner-mvp/contracts/queue.md` — 9 functions: Get-QueuePending, Get-QueueInFlight, Get-QueueDone, Get-QueueAbandoned, Add-QueueDone, Add-QueueAbandoned, Add-QueueInFlight, Remove-QueueInFlight, Get-CurrentQuarter

**Checkpoint**: queue.ps1 可独立验证——调用各 Get-* 函数对空 JSON 返回空数组，调用 Add-* 后 JSON 文件正确写入

---

## Phase 3: User Story 1 — 单 idea 端到端跑通 (Priority: P1) 🎯 MVP

**Goal**: 给一个 idea 路径，runner 能建 run 目录、冻结快照、跑完研究后投递到 wiki inbox

**Independent Test**: 用 `2026-05-01-modernity-wang-minan-thirteen-lectures` 跑 quickstart.md 全流程

### Implementation for User Story 1

- [ ] T005 [P] [US1] Implement `scripts/new-run.ps1` per `specs/001-research-runner-mvp/contracts/new-run.md` — 8 steps: validate path → derive run_id → check done → create dirs → freeze idea → init log → update in_flight → output path
- [ ] T006 [P] [US1] Implement `scripts/deliver.ps1` per `specs/001-research-runner-mvp/contracts/deliver.md` — 9 steps: validate output.md → check frontmatter → compute target path → handle collision → copy file → add done record → remove in_flight → append log → output path
- [ ] T007 [US1] Update `specs/001-research-runner-mvp/quickstart.md` to use unified filenames (`notes/task-card.md`, `notes/judgment.md`, `notes/memo.md`) and gate values (`opening`/`midway`/`closing`) per plan.md
- [ ] T008 [US1] Smoke test: execute quickstart.md scenario end-to-end with one migration idea — verify SC-001 (single session draft), SC-003 (source citations), SC-005 (boundary), SC-006 (no fabrication)

**Checkpoint**: 一个 idea 从 wiki → runs/<id>/ → wiki inbox 端到端跑通，log.md 有完整事件记录

---

## Phase 4: User Story 2 — 扫描对齐与候选呈报 (Priority: P2)

**Goal**: 用户问"有什么可跑"，runner 扫描 wiki ideas 与本地 queue 状态，分类呈报

**Independent Test**: wiki `research/ideas/` 中有混合状态（pending + 已投递 + abandoned），扫描对齐正确分类四象限

### Implementation for User Story 2

- [ ] T009 [US2] Implement `scripts/scan-and-align.ps1` per `specs/001-research-runner-mvp/contracts/scan-and-align.md` — 5 steps: list idea files → read frontmatter → load local queue → classify per FR-022 table → output JSON
- [ ] T010 [US2] Smoke test: prepare mixed wiki state (at least 1 runnable + 1 already-delivered idea), run scan-and-align, verify JSON output matches expected classification

**Checkpoint**: alignment report 正确区分 runnable / awaiting_ingest / previously_abandoned 三类

---

## Phase 5: User Story 3 — 中断后可恢复 (Priority: P3)

**Goal**: 跨会话时 runner 能从 `runs/<id>/` 恢复上下文并继续

**Independent Test**: 主动跑一个 idea 到中途停下，重启会话，告诉 runner "继续"，验证恢复

### Implementation for User Story 3

- [ ] T011 [US3] Add resume protocol to `CLAUDE.md` — 明确：收到"继续 <run-id>"时 runner 应读取哪些文件（idea.md + log.md + notes/* + output.md if exists）、如何从最近事件推断当前阶段、如何向用户复述进度
- [ ] T012 [US3] Smoke test: interrupt a run after midway gate, start new session, say "继续 <run-id>", verify runner correctly identifies current stage and proposes next step

**Checkpoint**: Runner 能在新会话中正确恢复中断的 run 并继续推进

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: 全流程验证与收尾

- [ ] T013 Run second migration idea end-to-end (满足 SC-002: 4 个迁移 idea 中至少 2 个跑通)
- [ ] T014 Verify all success criteria SC-001 ~ SC-006 against completed runs
- [ ] T015 [P] Review and clean up any leftover TODO/placeholder in CLAUDE.md, plan.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (directories must exist for queue.ps1 to write)
- **US1 (Phase 3)**: Depends on Phase 2 (new-run + deliver both dot-source queue.ps1)
- **US2 (Phase 4)**: Depends on Phase 2 (scan-and-align dot-sources queue.ps1). Independent of US1.
- **US3 (Phase 5)**: Depends on US1 being complete (needs a real run to test resume against)
- **Polish (Phase 6)**: Depends on US1 + US2 both complete

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational — No dependencies on other stories
- **US2 (P2)**: Can start after Foundational — Independent of US1 (parallel opportunity)
- **US3 (P3)**: Depends on US1 (needs existing run with log data to resume from)

### Within Each User Story

- Scripts before smoke tests
- T005 and T006 are parallel (different scripts, both depend only on queue.ps1)

### Parallel Opportunities

- T001 + T003: both create directories, no conflict
- T005 + T006: new-run.ps1 and deliver.ps1 are independent scripts
- US1 (Phase 3) and US2 (Phase 4) can run in parallel after Foundational
- T013 + T015: independent polish tasks

---

## Parallel Example: Phase 3 (US1)

```
# After Phase 2 (queue.ps1) is done, launch in parallel:
Task T005: "Implement new-run.ps1"
Task T006: "Implement deliver.ps1"

# After both complete:
Task T007: "Update quickstart.md filenames"
Task T008: "Smoke test end-to-end"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: queue.ps1 (T004)
3. Complete Phase 3: new-run + deliver + smoke test (T005–T008)
4. **STOP and VALIDATE**: Run quickstart.md scenario, verify SC-001/003/005/006
5. MVP done — runner can execute a single research idea end-to-end

### Incremental Delivery

1. Setup + Foundational → scripts infrastructure ready
2. US1 → single idea runs → **MVP deliverable**
3. US2 → scan-and-align → user can discover candidates
4. US3 → resume → cross-session robustness
5. Polish → second idea + SC validation → release confidence

---

## Notes

- 本项目 "runner 行为" 由 Claude 在对话中按 CLAUDE.md + SOP 规约执行，不需要对应的 task
- 脚本契约已在 `contracts/` 中完整定义，实现时逐条对照即可
- 测试策略为手动 smoke run（research.md D7），不引入 Pester
- 每个脚本完成后立即手测基本 happy path + 至少一个 edge case（如同名冲突、已投递检查）
