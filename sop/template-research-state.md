# Research state 模板

> 作用：记录一个 run 当前最新的研究理解。新 run 的 active state 只读写 `notes/research-state.md`；历史快照写入 `notes/state-history/`。
>
> 填写原则：保留英文 key，正文说明使用中文。不要使用空的子列表占位符；未知值写 `unknown`，不适用写 `n/a`，可延后写 `deferred`，列表为空写 `[]`。

## 填写规则

### 原始输入与主题抽取

- `origin_context.original_user_words`：必须保真引用用户原始输入。原则上完整引用本次开题输入；如果输入过长，必须保留关键原句，并在 `based_on.idea` 指向完整 `idea.md`。不得改写成 agent 总结。
- `origin_context.initial_topic`：从 `original_user_words` 抽取出的短标题。它可以由 AI 生成，但只能做标题化压缩，不新增事实、不替用户决定范围。推荐格式是“研究对象 + 研究动作 / 用途”。
- 如果 `original_user_words` 同时包含多个可能主题，并且会改变当前或后续搜索方向，`initial_topic` 标为 `unresolved`，并在 `tracked_facets` 里要求 `ask_user`。

### 上下文生命周期

- `origin_context.known_context`：记录进入本次 state 更新之前已经成立、会约束理解的稳定背景。opening 阶段写开题前已知背景；round 阶段可吸收已经确认的稳定背景或用户补充，但不要把一轮搜索的临时发现都塞进这里。
- `origin_context.user_feedback`：记录用户在 run 过程中新增的约束、修正、确认或否定。用户反馈如果已经变成稳定背景，可以同步压缩进 `known_context`，但原反馈仍应可追溯。
- 下一轮搜索要传递的问题、缺口和聚焦方向，不写在 `known_context`，写在 `derived.search_plan.gaps` 和 `derived.search_plan.next_round_focus`。

### 派生字段

- `derived.use_intent`：不是用户原话字段，而是从 `original_user_words`、`problem_source`、`known_context`、`user_feedback`、`output_action_contract` 中推导出的用途判断。
- `derived.use_intent.derived_from`：必须写明推导来源，例如 `original_user_words + user_feedback`。如果只是默认假设，写 `default` 并在 `tracked_facets` 标 `temporary`。
- `derived.objective.decision_or_action`：根据 `use_intent` 改写成“这次研究要支持的决定 / 推进的项目 / 解决的问题”。
- `derived.objective.research_question`：把主题改写成可搜索、可判断的问题。推荐句式：`为了 <decision_or_action>，需要回答：<research_question>`。
- `derived.objective.current_formulation`：当前工作表述。opening 阶段可以是临时版本；每轮搜索或用户反馈后都可以随证据更新。

### Opening 最低要求

opening 只要求能安全进入第一轮搜索，不要求所有 slot 都 confirmed。最低必须填：

- `origin_context.initial_topic`
- `origin_context.original_user_words`
- `derived.use_intent.value`
- `derived.use_intent.derived_from`
- `derived.objective.research_question`
- `scope_boundary.in_scope`
- `scope_boundary.out_of_scope`
- `scope_boundary.action_boundary`
- `evidence_contract.source_surfaces`
- `evidence_contract.stop_criteria`
- `derived.search_plan.first_round`
- `tracked_facets` 中关键 facet 的 `resolution_state`

## 元信息

- `run_id`: <run-id>
- `snapshot_stage`: current | opening | round | pre-memo | legacy-import
- `snapshot_source`: <manual | llm | legacy_import | search_round_update>
- `updated_at`: <ISO 8601>
- `based_on.idea`: <idea.md path 或 n/a>
- `based_on.search_round`: <sources/search-round-N.md 或 n/a>
- `based_on.user_feedback`: <用户反馈摘要或 n/a>

## origin_context

- `initial_topic`: <从原始输入抽取的短标题>
- `original_user_words`: <用户原始输入；必须保真引用，过长时保留关键原句并指向完整 idea.md>
- `problem_source`: <问题来源；例如用户口述、idea 文件、已有 run、外部材料>
- `known_context`: <本次 state 更新前已经成立的稳定背景；没有写 unknown>
- `existing_materials`: <已有材料路径 / URL 列表；没有写 []>
- `user_feedback`: <run 过程中用户补充、修正或确认的内容；没有写 []>

## inquiry_shape

- `research_object`: <研究对象：人、工具、制度、项目、问题等>
- `operation_type`: <研究动作：比较、解释、验证、诊断、选型、规划、写作等>
- `candidate_paths`: <候选路径 / 候选动作列表；未知写 []>
- `key_terms`: <当前轮次需要压测或保持一致理解的关键术语；未知写 []>
- `map.key_variables`: <关键变量；可随每轮搜索更新>
- `map.major_paths`: <主要路径；可随每轮搜索更新>
- `map.frictions_or_conditions`: <摩擦、约束或适用条件>
- `map.disagreements`: <已知争议；未知写 []>
- `map.unknowns`: <当前未知项；区分 searchable gap 和 user-only gap>

## scope_boundary

- `in_scope`: <本 run 回答什么；列表或短段落>
- `out_of_scope`: <明确不回答什么；列表或短段落>
- `action_boundary`: <本 run 允许做到的动作上限>
- `user_only_decisions`: <只能由用户决定的事项；没有写 []>

## evidence_contract

- `source_surfaces.official_or_primary`: <官方 / 一手来源要求；没有写 n/a>
- `source_surfaces.market_or_news`: <市场 / 新闻来源要求；没有写 n/a>
- `source_surfaces.academic`: <论文 / 学术来源要求；没有写 n/a>
- `source_surfaces.community_or_cases`: <社区 / 案例 / 实践来源要求；没有写 n/a>
- `evidence_principles.primary_source_preferred`: <何时优先一手来源>
- `evidence_principles.method_fit`: <什么证据适合回答这个问题>
- `evidence_principles.practice_friction`: <是否必须覆盖实践摩擦 / 反例>
- `evidence_principles.cross_check`: <交叉验证要求>
- `evidence_principles.evidence_downgrade`: <弱证据如何降级表述>
- `stop_criteria`: <什么情况下可以停止继续搜索>

## output_action_contract

- `product_shape`: <最终产物形态；例如 memo、清单、对比表、workflow、草稿>
- `audience`: <给谁看 / 给谁用>
- `allowed_actions`: <允许建议或执行的动作；没有写 []>
- `disallowed_actions`: <不允许建议或执行的动作；没有写 []>
- `needs_user_confirmation`: <推进前必须问用户确认的事项；没有写 []>

## derived

### use_intent

- `value`: <用户拿研究结果做什么>
- `derived_from`: <original_user_words | problem_source | known_context | user_feedback | output_action_contract | default 的组合>
- `notes`: <推导说明；写明是否为 temporary>

### objective

- `decision_or_action`: <要支持的决定 / 推进的项目 / 解决的问题>
- `research_question`: <为了上述目标，需要回答的问题>
- `current_formulation`: <当前工作表述；可随搜索更新>

### search_plan

- `source_surfaces`: <当前或下一轮要开的来源面；不写工具路由>
- `first_round`: <opening 生成的第一轮搜索意图；后续保留为起点记录>
- `gaps`: <当前待补缺口；区分 searchable 和 user-only>
- `next_round_focus`: <下一轮搜索聚焦；opening 可写 deferred，round 后应随 state 更新>

### enoughness

- `current`: <当前证据是否足够；opening 通常是 insufficient，round 后持续更新>
- `enough_for`: <足够支持什么；opening 通常写 []，round 后持续更新>
- `not_enough_for`: <不足以支持什么>
- `next_action`: search_next | ask_user | defer | write_memo | stop

## child_runs

### candidates

| 子课题 | 对应缺口 | 影响的 slot | 是否已问用户 | 状态 |
|---|---|---|---|---|
| n/a | n/a | n/a | n/a | n/a |

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

- `imported_from_task_card`: yes | no
- `imported_from_judgment`: yes | no
- `imported_from_memo`: yes | no
- `import_notes`: <导入说明；新 run 写 n/a>

## change_log

| 时间 | 来源 | 变更 | 原因 |
|---|---|---|---|
|  |  |  |  |
