# C6 fixture：第二轮后足够进入 memo 的 state

## 元信息

- snapshot_stage: round
- snapshot_source: synthetic_test_fixture
- based_on:
  - search_round: `sources/search-round-2.md`

## origin_context

- initial_topic: research-state / slot lifecycle 接入 SOP。

## inquiry_shape

- research_object: research runner SOP lifecycle
- operation_type: workflow migration plan
- candidate_paths:
  - 保留旧 task-card / judgment 并新增 state。
  - 用 research-state 替代 task-card / judgment。

## scope_boundary

- in_scope:
  - 文档层 SOP、模板、任务、测试方案。
- out_of_scope:
  - 不立即改脚本。
  - 不迁移历史 run。
- action_boundary: 可以改 SOP 文档，不做脚本实现。

## evidence_contract

- stop_criteria: 状态模型、每轮更新规则、用户阻塞点、模板改造点、测试方案齐备。

## derived

### objective

- decision_or_action: 确认新 SOP 是否足够写 memo。
- research_question: research-state 是否能替代 task-card / judgment 并支撑每轮搜索更新？
- current_formulation: 以 research-state 为唯一当前状态，每轮 search-round 提交 state_delta。

### search_plan

- gaps:
  - 无阻塞型缺口。
- next_round_focus:
  - 如用户不认可 enoughness，再补具体实现脚本计划。

### enoughness

- current: 足够支持写 memo。
- enough_for:
  - 文档层 SOP 改造。
  - 用户审阅是否进入 output。
- not_enough_for:
  - 直接改脚本。
- next_action: write_memo

## tracked_facets

| facet | value | resolution_state | basis | alternatives | next_action | update_reason |
|---|---|---|---|---|---|---|
| objective | research-state 替代旧阶段文档 | confirmed | mixed | 新老并存 | write_memo | 两轮已覆盖关键流程 |
| scope_boundary | 文档层，不改脚本 | confirmed | user | 直接实施脚本 | write_memo | 用户要求先写修改计划 |
| evidence_contract | 足够写 memo，不足以脚本落地 | confirmed | inference | 继续搜索 | write_memo | 缺口不再改变当前文档设计 |
