# C5 fixture：pivot 前的 opening state

## 元信息

- snapshot_stage: opening
- snapshot_source: synthetic_test_fixture

## origin_context

- initial_topic: 研究是否应该给 research runner 增加更多 clarification slot。
- original_user_words: 先看要不要问更多澄清问题。

## inquiry_shape

- research_object: research runner clarification flow
- operation_type: workflow design
- candidate_paths:
  - 增加更多 opening clarification question。
  - 先做预搜索，再决定哪些缺口必须问用户。

## scope_boundary

- in_scope:
  - opening clarification 的策略选择。
- out_of_scope:
  - 不直接修改脚本。
- action_boundary: 只做流程判断，不实施。

## derived

### objective

- decision_or_action: 判断是否应该多问 opening clarification。
- research_question: research runner 在开题时应该先问用户，还是先预搜索？
- current_formulation: 当前 formulation 偏向“是否需要更多澄清问题”。

### search_plan

- first_round: 搜索 clarification 与预搜索的实践差异。
- gaps:
  - 何时应该问用户。
  - 何时应该先搜索。

### enoughness

- current: 第一轮搜索前，尚不足以定方向。
- next_action: search_next

## tracked_facets

| facet | value | resolution_state | basis | alternatives | next_action | update_reason |
|---|---|---|---|---|---|---|
| objective | 是否增加更多 opening clarification | temporary | inference | 先预搜索；先问用户；分层处理缺口 | search_next | 需要第一轮搜索验证 |
