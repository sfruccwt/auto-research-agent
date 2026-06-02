# 测试方案：Research state / slot lifecycle

状态：已准备（文档层测试方案）
对应任务：`sop/tasks/research-state-slot-lifecycle.md`
迁移计划：`sop/tasks/research-state-slot-lifecycle-migration-plan.md`
创建时间：2026-06-01
最近更新：2026-06-01

## 测试边界

本测试方案只覆盖当前改造阶段能验证的内容：

- 静态模板 / SOP 检查。
- 旧字段覆盖核对。
- gate 重绑定检查。
- 场景化用例。

不把历史 run 回放作为本次验收项。历史 run 已有定论，倒推新流程容易变形，价值不如新场景测试。

真实新 idea 的 shadow pilot 属于后续人工验证，不作为本次自动验收门槛。

## 测试目标

验证新流程是否真的替代旧阶段文档，而不是在旧流程旁边再加一套表：

- 新 run 不再依赖 `task-card.md` 和 `judgment.md`。
- `task-card` / `judgment` 的旧字段完成覆盖核对，不为了旧模板新增字段。
- opening gate 改绑到 state 快照；midway 仅作为旧 run legacy gate，不进入新流程。
- 每轮搜索后能说明 state 怎么变。
- memo 前能明确 enoughness 和 action boundary。
- 用例需要上下文时，后续执行时临时构造最小合成输入，不回放历史 run。

## L1. 静态模板检查

对象：

- `sop/template-research-state.md`
- `sop/template-search-round.md`
- `sop/template-memo.md`
- `sop/stages/1-opening.md`
- `sop/stages/2-research.md`
- `sop/flow-card.md`
- `sop/templates.md`

检查项：

| 编号 | 检查点 | 通过标准 |
|---|---|---|
| S1 | `research-state` 字段完整 | 有五个主 slot、派生项、`child_runs.candidates`、`change_log` |
| S2 | tracking 字段克制 | 只有关键 facet 挂 `value / resolution_state / basis / alternatives / next_action / update_reason`，普通 facet 保持轻量文本 |
| S3 | `search-round` 字段完整 | 有 `state_before / state_delta / state_after / enoughness_current / agent_recommendation` |
| S4 | `memo` 做最终 review | 有 enoughness 和 action boundary，不复写完整 slot |
| S5 | task-card 已退出 active flow | 新 SOP 不要求新 run 写 `notes/task-card.md` |
| S6 | judgment 已退出 active flow | 新 SOP 不要求新 run 写 `notes/judgment.md` |
| S7 | 模板索引清楚 | `template-task-card.md` 和 `template-judgment.md` 标为 legacy |

失败信号：

- active SOP 仍写“写完 task-card 后过 opening 门”。
- active SOP 仍写“写完 judgment 后过 midway 门”。
- active SOP 仍要求新 run 调用 `Update-QueueGate -Gate midway`。
- 同一个 slot 在 `research-state.md` 和其他 active 文档里重复维护。
- 每个 facet 都被迫填写 metadata，导致 `research-state.md` 膨胀成表单。
- `search-round-N.md` 只能看到“搜到了什么”，看不到 state 为什么变。

## L2. 旧字段覆盖核对

目标：确认删除 `task-card.md` / `judgment.md` 后没有丢信息，也没有为了旧模板新增不必要字段。

### Task-card 字段

| 旧字段 | 新位置 | 通过标准 |
|---|---|---|
| `主题` | `origin_context.initial_topic` | 能保留原始主题 |
| `交付对象` | `use_intent.audience` / `output_action_contract.audience` | 能说明写给谁 / 给谁用 |
| `这次真正要支持的决定 / 动作` | `objective.decision_or_action` | 能说明研究服务的动作 |
| `这次真正要回答的问题` | `objective.research_question` | 能形成可搜索问题 |
| `当前待比较路径 / 候选动作` | `inquiry_shape.candidate_paths` | 能列出候选路径 |
| `输出模式` | `output_action_contract.product_shape` | 能决定最终产物形态 |
| `明确不回答什么` | `scope_boundary.out_of_scope` | 能约束范围 |
| `优先开的检索面` | `search_plan.source_surfaces` | 能生成第一轮搜索面 |
| `工具分配` | 不迁入 slot | 默认工具规则已由 `AGENTS.md` 注入；slot 只记录来源面和搜索意图 |
| `本轮动作上限` | `scope_boundary.action_boundary` | 能避免研究越界实施 |
| `本轮收尾门槛` | `enoughness.stop_criteria` | 能判断何时够用 |
| `用户解读 / 感想` | `origin_context.user_feedback` / `change_log` | 能保留用户补充 |

### Judgment 字段

| 旧字段 | 新位置 | 通过标准 |
|---|---|---|
| `当前研究问题` | `objective.research_question` | 能记录当前 formulation |
| `第一轮地图` | `inquiry_shape.map` / `search-round-N.key_findings` | 能保留建图结果 |
| `当前判断` | `search-round-N.enoughness_current` / `memo.md` | 能表达阶段性判断和最终判断，不新增 `midway_review` |
| `判断成立依赖的前提` | `scope_boundary` / `evidence_contract` / `memo.md` | 只在影响边界或证据判准时进入 state |
| `最短证据链` | `search-round-N.key_findings` / `memo.md` | 能保留证据链，不新增判断单副本 |
| `竞争判断` | `inquiry_shape` 候选路径 / tracked facet `alternatives` | 能保留替代解释，不新增判断单副本 |
| `待证点列表` | `search_plan.gaps` | 能驱动后续补缺 |
| `第二轮只补什么` | `search_plan.next_round_focus` | 能限制第二轮搜索 |
| `用户解读 / 感想` | `origin_context.user_feedback` / `change_log` | 能保留用户反馈 |

通过门槛：

- 每个旧字段都能被现有结构覆盖。
- 没有为旧模板新增 `midway_review` 或其他判断单副本字段。
- `工具分配` 不迁入 slot；默认检索工具规则继续由 `AGENTS.md` 负责。

## L3. Gate 重绑定检查

目标：确认 run 状态更新不再依赖旧阶段文档。

| gate | 必备 artifact | 禁止条件 |
|---|---|---|
| `opening` | `notes/research-state.md` + `notes/state-history/research-state-opening.md` | 不能要求 `notes/task-card.md` |
| `done` | `output.md` | 不变 |
| `midway` | legacy only | 新 run 不能调用 `Update-QueueGate -Gate midway` |

检查项：

- `sop/stages/1-opening.md` 中 opening 过门条件已经改绑到 opening state。
- `sop/stages/2-research.md` 不再设置 midway 过门条件；每轮搜索只更新 state 和 round snapshot。
- `sop/flow-card.md` 中 2 道门 + done 表不再列 task-card / judgment。
- `scripts/queue.ps1` 当前不校验 artifact，文档里应明确第一版不改脚本、只改 SOP 触发条件。
- 脚本修改计划应列出后续是否加入 artifact 校验。

## L4. 场景化用例

这些用例不追求完整研究，只测试流程分支是否正确。需要前置状态的用例，后续执行时临时构造最小合成输入。

### 前置状态约定

不在 `main` 保留临时 fixture。需要前置状态的用例，在实际执行时按用例描述临时构造最小输入，执行后不提交测试产物。

### C1. Searchable missing

输入：

```text
研究一下现在 AI 搜索 agent 的好用工作流。
```

预期：

- 不应立即追问用户所有细节。
- `origin_context` 可为 `missing` 或 `temporary`。
- `inquiry_shape` 应形成临时对象：AI 搜索 agent 工作流。
- `next_action` 应指向 `search_next`。
- opening gate 产物是 `research-state-opening.md`，不是 `task-card.md`。

通过标准：

- agent 能进入第一轮搜索。
- 未把可搜索缺口误判为必须问用户。

### C2. User-only missing

输入：

```text
帮我查这个方案值不值得做，后面我要用它改我自己的流程。
```

预期：

- 如果“不知道这个方案是什么”且会改变搜索对象，必须问用户。
- 不能擅自把“这个方案”替换成某个 agent 常见方案。
- `next_action = ask_user`。

通过标准：

- agent 暂停并问一个具体问题。
- 问题聚焦于 user-only 缺口，不发散问一堆偏好。

### C3. Temporary assumption

输入：

```text
研究一下是否应该给这个 research runner 加 slot。
```

预期：

- 可临时假设 slot 指 research clarification slot / research state slot。
- `resolution_state = temporary`。
- `alternatives` 记录：prompt slot、schema slot、workflow state slot。
- 第一轮搜索或本地梳理用于验证这个 temporary 值。

通过标准：

- agent 没有把 temporary 写成 confirmed。
- 后续 search round 能更新或替换该假设。

### C4. Unresolved branch

输入：

```text
研究一下这个系统下一步应该自动化。
```

预期：

- “自动化”可能指脚本自动化、agent 自动判断、模板自动生成、queue gate 自动推进。
- 不同解释会导向不同 output 和 action boundary。
- 应标记为 `unresolved`，并问用户或先列分支。

通过标准：

- agent 不擅自选择其中一个解释作为 confirmed。
- 如果先搜，必须明确只做“自动化候选面建图”。

### C5. Pivot after round 1

准备：

- 临时构造最小 `research-state-before.md`：opening 目标仍偏向“是否要多问澄清问题”。
- 临时构造最小 `search-round-1.md`：第一轮发现真正关键是先预搜索，并区分 `searchable gap` 与 `user-only gap`。

输入：

```text
第一轮发现：关键不是问更多澄清问题，而是先预搜索，把 searchable gap 和 user-only gap 分开。
```

预期：

- `state_delta` 更新 `objective` 或 `inquiry_shape`。
- `agent_recommendation = pivot`。
- 必须暂停给用户确认。

通过标准：

- agent 不直接按 pivot 后方向继续搜。
- 用户确认前不改 action boundary。

### C6. Enough after round 2

准备：

- 临时构造最小 `research-state-r02.md`：已有状态模型、每轮更新规则、用户阻塞点、模板改造点、测试方案。
- 临时构造最小 `search-round-2.md`：第二轮只补齐最后的证据判准或 action boundary 缺口。

前置状态：

```text
状态模型、每轮更新规则、用户阻塞点、模板改造点、测试方案已经齐备。
```

预期：

- `enoughness_current` 说明当前足够支持写 memo。
- `agent_recommendation = write_memo`。
- 保存 `research-state-pre-memo.md`。
- 必须交用户确认是否收口。

通过标准：

- agent 不继续无目的搜索。
- 能说清“足够支持什么”和“不足以支持什么”。

### C7. Child run candidate

输入：

```text
研究一下 research runner 的 slot lifecycle，同时看看有没有现成项目能直接借。
```

预期：

- 如果“现成项目扫描”膨胀成独立任务，应写入 `child_runs.candidates`。
- 标明它影响哪个 slot：通常是 `evidence_contract` 或 `output_action_contract`。
- 是否开子 run 需要提示用户。

通过标准：

- 子课题不是只写在普通 TODO 里。
- 子 run 完成后能回填影响的母 run slot。

### C8. Action boundary expansion

输入：

```text
先帮我查一下这个机制怎么设计。
```

搜索后 agent 想直接修改 SOP。

预期：

- 如果 opening 的 action boundary 只是“查一下 / 设计”，直接改 SOP 属于边界扩张。
- 必须暂停问用户。
- `output_action_contract` 更新前不能执行文件修改。

通过标准：

- agent 能识别 action boundary expansion。
- 不把“研究”自动升级成“实施”。

### C9. Legacy run resume

准备：

- 临时构造一个旧 run 目录，包含最小 `task-card.md`、`judgment.md`、`memo.md`，但没有 `research-state.md`。

输入：

```text
继续一个旧 run。该 run 有 task-card.md 和 judgment.md，但没有 research-state.md。
```

预期：

- agent 先做 legacy import。
- 生成 `notes/research-state.md` 和 `notes/state-history/research-state-legacy-import.md`。
- `basis = legacy_doc`。
- 不自动改 queue gate。

通过标准：

- 旧 run 可继续。
- 没有把旧文档内容误判为用户刚刚确认。
- 这个测试使用临时合成输入，不回放历史 run。

## L5. 后续人工验证：Shadow pilot

这部分不是本次文档改造的自动验收项。它由用户后续选择真实候选 idea 运行。

建议观察：

- 新 run 不生成 `task-card.md`。
- 新 run 不生成 `judgment.md`。
- 每轮维护 `notes/research-state.md`。
- 每轮保存 `notes/state-history/research-state-*.md`。
- 每轮 `sources/search-round-N.md` 末尾写 `search_round_summary.state_delta`。
- 不改脚本。

观察项：

| 观察项 | 记录 |
|---|---|
| 每轮多花时间 | low / medium / high |
| 用户是否更容易判断下一步 | yes / no / uncertain |
| agent 是否减少无效追问 | yes / no / uncertain |
| state 快照是否真的被后续用到 | yes / no / uncertain |
| 不写 task-card 是否丢 opening 信息 | yes / no / uncertain |
| 不写 judgment 是否丢阶段性判断信息 | yes / no / uncertain |
| 是否需要脚本辅助创建文件 | yes / no / uncertain |

## 通过门槛

当前文档改造验收：

- L1 静态检查可逐项判断 pass / fail。
- L2 旧字段覆盖核对可逐项判断 pass / fail，且没有新增 judgment 副本字段。
- L3 gate 重绑定检查可逐项判断 pass / fail。
- L4 场景覆盖完整；后续执行时至少选 6 个场景化用例，其中 C2、C4、C5、C6、C8 必须覆盖。

后续人工验证：

- L5 shadow pilot 至少完成 1 个新 run 后，再决定是否改脚本。

## 失败后处理

- 如果 task-card 字段有缺口：优先检查是否已有 slot 可覆盖，确实缺核心信息再补 `template-research-state.md`。
- 如果 judgment 字段有缺口：优先放到 `template-search-round.md`、`enoughness` 或 `memo.md`，不要新增 `midway_review`。
- 如果 active SOP 仍依赖 task-card / judgment：继续清理 stage、flow-card、templates 索引。
- 如果 metadata 泛滥：只对用户意图、目标、边界、证据判准、产出动作和会改变搜索方向的关键项做 tracking。
- 如果需要上下文的场景测不出来：临时补最小合成输入，不回放历史 run。
- 如果 agent 仍然无目的继续搜：强化每轮 `enoughness_current` 和 `agent_recommendation`。
