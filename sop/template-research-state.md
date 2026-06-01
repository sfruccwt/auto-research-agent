# Research state 模板

> 作用：记录一个 run 当前最新的研究理解。新 run 的 active state 只读写 `notes/research-state.md`；历史快照写入 `notes/state-history/`。

## 元信息

- run_id:
- snapshot_stage: current | opening | round | pre-memo | legacy-import
- snapshot_source:
- updated_at:
- based_on:
  - idea:
  - search_round:
  - user_feedback:

## origin_context

- initial_topic:
- original_user_words:
- problem_source:
- known_context:
- existing_materials:
- user_feedback:

## inquiry_shape

- research_object:
- operation_type:
- candidate_paths:
  -
- key_terms:
  -
- map:
  - key_variables:
  - major_paths:
  - frictions_or_conditions:
  - disagreements:
  - unknowns:

## scope_boundary

- in_scope:
  -
- out_of_scope:
  -
- action_boundary:
- user_only_decisions:
  -

## evidence_contract

- source_surfaces:
  - official_or_primary:
  - market_or_news:
  - academic:
  - community_or_cases:
- evidence_principles:
  - primary_source_preferred:
  - method_fit:
  - practice_friction:
  - cross_check:
  - evidence_downgrade:
- stop_criteria:

## output_action_contract

- product_shape:
- audience:
- allowed_actions:
  -
- disallowed_actions:
  -
- needs_user_confirmation:
  -

## derived

### use_intent

- value:
- derived_from:
- notes:

### objective

- decision_or_action:
- research_question:
- current_formulation:

### search_plan

- source_surfaces:
  -
- first_round:
- gaps:
  -
- next_round_focus:
  -

### enoughness

- current:
- enough_for:
  -
- not_enough_for:
  -
- next_action: search_next | ask_user | defer | write_memo | stop

## child_runs

### candidates

| 子课题 | 对应缺口 | 影响的 slot | 是否已问用户 | 状态 |
|---|---|---|---|---|
|  |  |  |  |  |

## tracked_facets

> 只记录关键 facet，不给每个字段都挂 metadata。

| facet | value | resolution_state | basis | alternatives | next_action | update_reason |
|---|---|---|---|---|---|---|
| use_intent |  | missing |  |  | ask_user |  |
| objective |  | missing |  |  | search_next |  |
| scope_boundary |  | missing |  |  | ask_user |  |
| evidence_contract |  | missing |  |  | search_next |  |
| output_action_contract |  | missing |  |  | defer |  |

可用 `resolution_state`：

- `missing`：当前没有有效值，也不能安全假设。
- `unresolved`：存在多个候选值，且选择会改变 search direction、output 或 action boundary。
- `temporary`：agent 自选一版临时工作值，可先推进，后续可替换。
- `confirmed`：用户确认，或证据足够支持当前用途。
- `deferred`：知道缺口存在，但当前阶段故意不处理。

可用 `basis`：

- `user`
- `evidence`
- `inference`
- `default`
- `mixed`
- `legacy_doc`

## legacy_import

- imported_from_task_card: yes | no
- imported_from_judgment: yes | no
- imported_from_memo: yes | no
- import_notes:

## change_log

| 时间 | 来源 | 变更 | 原因 |
|---|---|---|---|
|  |  |  |  |
