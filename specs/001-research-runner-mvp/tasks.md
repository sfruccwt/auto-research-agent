# Tasks: Research Runner MVP

**输入**: `specs/001-research-runner-mvp/` 下的设计文档
**前置**: plan.md, spec.md, data-model.md, contracts/, research.md, quickstart.md

**测试**: 手动 smoke run（用迁移 idea 跑端到端），无自动测试框架。

**组织方式**: 按 user story 分组。US1 = MVP 范围。

## 格式: `[ID] [P?] [Story] 描述`

- **[P]**: 可并行（不同文件、无依赖）
- **[Story]**: US1 / US2 / US3

---

## Phase 1: 初始化

**目的**: 创建目录结构和空状态文件，让脚本有可写入的目标位置

- [x] T001 在仓库根目录创建 `scripts/` 目录
- [x] T002 创建 `queue/` 目录结构及初始空 JSON：`queue/pending.json`、`queue/in_flight.json`、`queue/done/`（目录）、`queue/abandoned/`（目录）——每个 JSON 初始化为 `{"version": 1, "items": []}`
- [x] T003 [P] 创建 `runs/.gitkeep` 确保目录被 git 跟踪

---

## Phase 2: 基础设施（阻塞性前置）

**目的**: queue.ps1 是其他三个脚本的共享依赖，必须先完成

**⚠️ 关键**: new-run / deliver / scan-and-align 全部 dot-source queue.ps1，此 phase 完成前不能开始任何 user story

- [x] T004 实现 `scripts/queue.ps1` 共享函数库，按 `contracts/queue.md` 契约——9 个函数：Get-QueuePending, Get-QueueInFlight, Get-QueueDone, Get-QueueAbandoned, Add-QueueDone, Add-QueueAbandoned, Add-QueueInFlight, Remove-QueueInFlight, Get-CurrentQuarter

**检查点**: queue.ps1 可独立验证——各 Get-* 对空 JSON 返回空数组，Add-* 后 JSON 文件正确写入

---

## Phase 3: US1 — 单 idea 端到端跑通 (P1) 🎯 MVP

**目标**: 给一个 idea 路径，runner 能建 run 目录、冻结快照、按 SOP 跑完研究后投递到 wiki inbox

**独立验证**: 用 `2026-05-01-modernity-wang-minan-thirteen-lectures` 跑 quickstart.md 全流程

### 实现

- [x] T005 [P] [US1] 实现 `scripts/new-run.ps1`，按 `contracts/new-run.md` 契约——8 步：校验路径 → 推导 run_id → 检查 done → 建目录 → 冻结 idea → 初始化 log → 写 in_flight → 输出路径
- [x] T006 [P] [US1] 实现 `scripts/deliver.ps1`，按 `contracts/deliver.md` 契约——9 步：校验 output.md → 检查 frontmatter → 计算目标路径 → 处理同名冲突 → 拷贝文件 → 写 done 记录 → 移除 in_flight → 追加 log → 输出路径
- [x] T007 [US1] 更新 `quickstart.md`：统一文件名（`notes/task-card.md`、`notes/judgment.md`、`notes/memo.md`）和 gate 值（`opening`/`midway`/`closing`）
**检查点**: 一个 idea 从 wiki → runs/<id>/ → wiki inbox 端到端跑通，log.md 有完整事件记录

---

## Phase 4: US2 — 扫描对齐与候选呈报 (P2)

**目标**: 用户问"有什么可跑"，runner 扫描 wiki ideas 与本地 queue 状态，分类呈报

**独立验证**: wiki `research/ideas/` 中有混合状态（pending + 已投递 + abandoned），扫描对齐正确分三类

### 实现

- [x] T009 [US2] 实现 `scripts/scan-and-align.ps1`，按 `contracts/scan-and-align.md` 契约——5 步：列出 idea 文件 → 读 frontmatter → 加载本地 queue → 按 FR-022 表分类 → 输出 JSON

---

## Phase 5: US3 — 中断后可恢复 (P3)

**目标**: 跨会话时 runner 能从 `runs/<id>/` 恢复上下文并继续

**独立验证**: 主动跑一个 idea 到中途停下，重启会话，告诉 runner "继续"，验证恢复

### 实现

- [x] T011 [US3] 在 `CLAUDE.md` 添加 resume protocol——明确：收到"继续 <run-id>"时 runner 读取哪些文件（idea.md + log.md + notes/* + output.md）、如何从最近事件推断阶段、如何向用户复述进度

---

## 烟测（全部待执行）

以下测试需要用户参与，按依赖顺序排列：

| ID | 依赖 | 做什么 | 通过标准 |
|---|---|---|---|
| T008 | T005+T006 | 用一个迁移 idea 跑 quickstart.md 全流程端到端 | SC-001（单会话出 draft）、SC-003（来源引用）、SC-005（边界）、SC-006（无编造）、FR-011（git log 含修订 commit） |
| T010 | T008+T009 | T008 跑完后执行 scan-and-align，验证分类 | 刚投递的 idea 出现在 `awaiting_ingest`，其余 pending idea 在 `runnable` |
| T012 | T008 | 跑一个 idea 到中途门后停下，新会话说"继续 <run-id>" | runner 正确识别当前阶段并提出下一步，不重复已做工作 |
| T013 | T008 | 跑第二个迁移 idea 端到端 | 同 T008（满足 SC-002: 至少 2 个跑通） |
| T014 | T008+T013 | 对照 SC-001 ~ SC-006 逐条确认 | 6 条全过 |
| T015 | — | 扫一遍 CLAUDE.md、plan.md，清理遗留 TODO/placeholder | 无残留 |

---

## 依赖与执行顺序

### Phase 间依赖

- **Phase 1（初始化）**: 无依赖，立即开始
- **Phase 2（基础设施）**: 依赖 Phase 1（目录必须存在才能写 JSON）
- **US1（Phase 3）**: 依赖 Phase 2（new-run + deliver 都 dot-source queue.ps1）
- **US2（Phase 4）**: 依赖 Phase 2（scan-and-align 也 dot-source queue.ps1），与 US1 独立
- **US3（Phase 5）**: 依赖 US1（需要真实 run 数据来测试恢复）
- **Phase 6（收尾）**: 依赖 US1 + US2 都完成

### User Story 间依赖

- **US1 (P1)**: Phase 2 完成后即可开始，不依赖其他 story
- **US2 (P2)**: Phase 2 完成后即可开始，与 US1 独立（并行机会）
- **US3 (P3)**: 依赖 US1（需要已有 run + log 数据）

### 各 Story 内部顺序

- 先脚本后烟测
- T005 和 T006 可并行（不同脚本，只依赖 queue.ps1）

### 并行机会

- T001 + T003: 都是建目录，无冲突
- T005 + T006: new-run.ps1 和 deliver.ps1 是独立脚本
- US1 和 US2 在 Phase 2 完成后可并行
- T013 + T015: 独立的收尾任务

---

## 实施策略

### MVP 优先（只做 US1）

1. 完成 Phase 1: 初始化 (T001–T003)
2. 完成 Phase 2: queue.ps1 (T004)
3. 完成 Phase 3: new-run + deliver + 烟测 (T005–T008)
4. **停下验证**: 跑 quickstart.md 场景，确认 SC-001/003/005/006
5. MVP 完成——runner 可以端到端跑一个研究 idea

### 增量交付

1. 初始化 + 基础设施 → 脚本骨架就位
2. US1 → 单 idea 可跑 → **MVP 可交付**
3. US2 → scan-and-align → 用户可发现候选
4. US3 → resume → 跨会话健壮性
5. 收尾 → 第二个 idea + SC 验收 → 发布信心

---

## 备注

- "runner 行为"由 Claude 在对话中按 CLAUDE.md + SOP 规约执行，不产生源代码，不需要对应 task
- 脚本契约已在 `contracts/` 中完整定义，实现时逐条对照即可
- 测试策略为手动 smoke run（见 research.md D7），不引入 Pester
- 每个脚本完成后立即手测 happy path + 至少一个 edge case（同名冲突、已投递检查等）
