# 任务：Research state / slot lifecycle 接入 SOP

状态：已实施（文档层）
来源：`runs/2026-05-24-llm-web-search-principles-auto-research-optimization/sub/research-agent-sop-design-patterns/notes/slot-hierarchy-and-lifecycle.md`
迁移计划：`sop/tasks/research-state-slot-lifecycle-migration-plan.md`
配套测试：`sop/tasks/research-state-slot-lifecycle-test-cases.md`
创建时间：2026-06-01
最近更新：2026-06-01

## 任务目标

把现有 `task-card -> search rounds -> judgment -> memo -> output` 流程，改成以 `research-state.md` 为主线的流程：

```text
research-state opening snapshot
-> search-round-N + state_delta
-> research-state round snapshot
-> memo
-> output
```

这次改造不再让 `task-card.md` 和 `judgment.md` 作为新 run 的 active artifact。旧模板只做覆盖核对：如果某个旧字段已经被现有 slot、search round 或 memo 覆盖，就不再为它新增字段；历史 run 中已有的 `task-card.md` / `judgment.md` 只作为 legacy import 来源。

## 已定约束

- 每个 run 独立维护 `notes/research-state.md`，不先做全局 slot JSON。
- `notes/research-state.md` 是当前操作读取的最新 state。
- `notes/state-history/*.md` 保留完整历史快照，用于复盘、回放和测试。
- 每轮搜索必须产生 `search_round_summary.state_delta`。
- `memo.md` 保留，作为 output 前的最终 enoughness / action boundary review。
- `task-card.md` 和 `judgment.md` 从新流程 active artifact 中移除。
- 第一版先改文档、模板、SOP 和任务计划，不直接改脚本实现。

## 新 active artifact

推荐结构：

```text
runs/<run-id>/notes/research-state.md
runs/<run-id>/notes/state-history/research-state-opening.md
runs/<run-id>/notes/state-history/research-state-r01.md
runs/<run-id>/notes/state-history/research-state-r02.md
runs/<run-id>/notes/state-history/research-state-pre-memo.md
runs/<run-id>/sources/search-round-1.md
runs/<run-id>/sources/search-round-2.md
runs/<run-id>/notes/memo.md
runs/<run-id>/output.md
```

职责边界：

| 文件 | 职责 |
|---|---|
| `notes/research-state.md` | 当前最新 state，agent 继续 run 时优先读取 |
| `notes/state-history/*.md` | 不可变历史快照，用于复盘、比较和测试 |
| `sources/search-round-N.md` | 本轮证据、搜索结论、`state_delta`、`state_before/state_after` 链接 |
| `notes/memo.md` | output 前的最终 enoughness / action boundary review |
| `output.md` | 面向读者的最终产物，不承载过程 state |

旧文件处理：

| 文件 | 新流程处理方式 |
|---|---|
| `notes/task-card.md` | 新 run 不再生成；旧字段只做覆盖核对，不新增对应字段 |
| `notes/judgment.md` | 新 run 不再生成；旧字段由 state snapshot、search round 和 memo 覆盖 |

## Gate 重新绑定

当前 `Update-QueueGate` 只更新 `queue/in_flight.json.current_gate` 并写 `log.md`，不校验标志产物。因此第一版可以先不改脚本，但必须改 SOP 对 gate 的定义。

| gate | 旧标志产物 | 新标志产物 | 触发方式 |
|---|---|---|---|
| `opening` | `notes/task-card.md` | `notes/research-state.md` + `notes/state-history/research-state-opening.md` | LLM 写完 opening state 后调用 `Update-QueueGate -Gate opening` |
| `done` | `output.md` | `output.md` | LLM 写完 output 后调用 `Update-QueueGate -Gate done` |

`memo.md` 不是 queue gate，但仍是 output 前的用户阻塞点：memo 未经用户确认，不写 `output.md`。

`midway` 是旧流程 gate。新 run 不再调用 `Update-QueueGate -Gate midway`；旧 run 中已有的 `current_gate = midway` 只按 legacy 状态处理。

## 关键 facet 的 resolution metadata

不是每个 slot / facet 都挂完整状态字段。默认情况下，slot 只是内容结构；只有会影响搜索方向、用户意图、边界、证据判准、输出动作的关键 facet，才进入 resolution tracking。

需要 tracking 的典型 facet：

- `use_intent`：用户到底拿研究结果做什么。
- `objective`：本轮真正要回答 / 决定什么。
- `scope_boundary`：回答边界、动作边界、不做什么。
- `evidence_contract`：需要什么证据才算够。
- `output_action_contract`：最终要输出什么、能建议什么动作。
- `child_runs.candidates`：是否需要拆子 run。
- 会改变 `search_intent` 的 `inquiry_shape` 关键项。

被 tracking 的关键 facet 使用字段：

```yaml
value: ""
resolution_state: missing | unresolved | temporary | confirmed | deferred
basis: user | evidence | inference | default | mixed | legacy_doc
alternatives: []
next_action: ask_user | search_next | use_as_is | defer | stop
update_reason: ""
```

第一版不强制使用 `confidence`。如果需要表达“把握程度”，优先写在 `update_reason` 里，或通过 `basis` 和来源链接说明。

## 实施任务

### T1. 新增 `sop/template-research-state.md`

必须包含：

- `origin_context`
- `inquiry_shape`
- `scope_boundary`
- `evidence_contract`
- `output_action_contract`
- 派生项：`use_intent`、`objective`、`search_plan`、`enoughness`
- `child_runs.candidates`
- `change_log`
- legacy import 区：记录是否从旧 `task-card.md` / `judgment.md` / `memo.md` 导入

验收点：

- 覆盖旧 `task-card.md` 和 `judgment.md` 的有效信息，但不为旧模板新增专门字段。
- 不要求每个 facet 都填写 resolution metadata。
- 能生成 opening、round、pre-memo 三类快照。
- 不新增 `search_plan.tool_routing`。默认检索工具规则由 `AGENTS.md` 注入：所有检索加载并使用 `agent-reach`；slot 只记录要开的来源面和搜索意图。

### T2. 新增 `sop/template-search-round.md`

必须包含：

- `search_intent`
- `queries_and_sources`
- `key_findings`
- `state_before`
- `state_delta`
- `state_after`
- `new_gaps`
- `enoughness_current`
- `next_search_options`
- `agent_recommendation`：`continue_search / pivot / ask_user / write_memo / stop`

验收点：

- 任意 `search-round-N.md` 都能反推本轮为什么改变 state。
- 每轮都有阶段性 enoughness 初判。
- 每轮都能说明下一步搜索是否由 state gap 触发。

### T3. 更新 `sop/templates.md`

改动要求：

- 新增 `template-research-state.md` 和 `template-search-round.md`。
- 将 `template-task-card.md` 和 `template-judgment.md` 标记为 legacy，不再用于新 run。
- 保留 `template-memo.md` 和 `template-output.md`。

验收点：

- 新 run 的模板路由不会再指向 `task-card` / `judgment`。
- 历史 run 恢复时仍能识别旧模板来源。

### T4. 更新 `sop/stages/1-opening.md`

改动要求：

- opening 不再要求写 `notes/task-card.md`。
- opening 必须写 `notes/research-state.md`。
- opening 后保存 `notes/state-history/research-state-opening.md`。
- opening 只要求能安全进入第一轮搜索。
- high-impact + user-only 且没有安全默认值的字段才问用户。
- searchable 缺口进入第一轮 `search_intent`。
- 写完 opening state 后调用 `Update-QueueGate -RunId <id> -Gate opening`。

验收点：

- 新 SOP 中不再出现“写完 task-card 后过 opening 门”。
- opening state 包含原 task-card 的必要信息。

### T5. 更新 `sop/stages/2-research.md`

改动要求：

- 每轮搜索结束后必须写 `sources/search-round-N.md`。
- 每轮必须先写 `state_delta`，再更新 `notes/research-state.md`。
- 每轮更新后必须保存完整 state 快照。
- 每轮必须给出 `agent_recommendation`。
- 每轮必须写阶段性 `enoughness_current`。
- 不再要求写 `notes/judgment.md`。

必须暂停交给用户确认的情况：

- `agent_recommendation = pivot`
- `agent_recommendation = write_memo`
- `agent_recommendation = stop`
- `action_boundary` 扩张
- high-impact + user-only 缺口
- 两个 scope 会导向不同 output

验收点：

- 新 SOP 中不再出现“写完 judgment 后过 midway 门”。
- 新 run 不再调用 `Update-QueueGate -Gate midway`。

### T6. 更新 `sop/template-memo.md`

改动要求：

保留 memo，但明确它不是状态主表，而是 output 前的最终 review：

```markdown
## enoughness 判断
- 当前证据足够支持什么:
- 当前证据不足以支持什么:
- 为什么现在可以停止继续搜索:
- 哪些判断仍需用户 / 实践确认:

## action boundary
- 当前允许建议的动作:
- 当前不允许建议的动作:
- 需要用户确认后才能推进的动作:
```

验收点：

- memo 不复写完整 slot。
- memo 能引用 `research-state-pre-memo.md`。
- memo 审阅等同于用户确认 enoughness 和 action boundary。

### T7. 更新 `sop/flow-card.md`

改动要求：

- 2 道门 + done 表改为新标志产物。
- 口令改为：

```text
先建 state；搜索后更新 state；memo 前确认 enoughness；output 只写最终稿。
```

验收点：

- flow-card 不再把 task-card / judgment 作为 active artifact。

### T8. 更新 `sop/workflow.md` 和恢复指引

改动要求：

- 在主工作流里说明 `research-state.md`、`state-history/`、`search-round-N.md`、`memo.md` 的关系。
- 恢复中断 run 时，优先读取 `notes/research-state.md`。
- 如果旧 run 没有 `research-state.md`，从 `task-card.md`、`judgment.md`、`memo.md` 做一次 legacy import，生成 `research-state.md` 和 `state-history/research-state-legacy-import.md`。
- 如果旧 run 的 `current_gate = midway`，只视为 legacy 阶段标记，不在新流程中继续推进 midway gate。
- 如果 `research-state.md` 与最新 `search-round-N.md` 不一致，暂停并标记为 workflow inconsistency。

验收点：

- 旧 run 可以继续，不要求批量迁移。
- 新 run 不再生成 task-card / judgment。

### T9. 更新脚本 / contract 的修改计划，但不立即改脚本

需要形成脚本修改计划：

- `new-run.ps1` 是否自动创建 `notes/state-history/` 和空 `notes/research-state.md`。
- `Update-QueueGate` 是否要按 gate 校验新标志产物。
- `queue/in_flight.json.current_gate = opening` 的语义是否保持“当前待过门”，还是改为更清楚的 `opening_pending / searching / memo_review / drafting / done`。
- 是否新增 `Test-RunStateConsistency` 检查 `research-state.md`、latest `search-round-N.md`、`state-history/` 是否一致。

第一版建议：先不改 queue schema；新流程只使用 opening 和 done 两个 queue gate，`midway` 只作为旧 run 的 legacy gate 值处理。等 shadow pilot 后再决定是否 schema migration。

### T10. 更新测试方案

按 `sop/tasks/research-state-slot-lifecycle-test-cases.md` 执行：

- 静态模板检查。
- 旧字段覆盖核对。
- gate 重绑定检查。
- 场景化用例设计。

验收点：

- 场景化用例能判断 pass / fail。
- 需要第二轮状态、legacy 文件或 pre-memo 状态的用例，使用最小合成输入，不回放历史 run。
- 能发现并记录模板负担是否过重。

后续人工验证：

- 新 idea 的 shadow pilot 不作为本次文档改造的自动验收项，由用户后续选择真实候选 idea 运行。

## 暂不做

- 不做全自动 research agent。
- 不先做全局 slot JSON。
- 不要求每个 slot opening 时都 confirmed。
- 不立即改脚本实现。
- 不立即迁移所有历史 run。
