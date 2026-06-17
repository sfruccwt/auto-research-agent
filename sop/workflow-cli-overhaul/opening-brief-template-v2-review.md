# Opening brief v2 模板

## brief

| field | 填写说明 | 展示内容 |
|---|---|---|
| intent | 给用户看的“为什么要做这次研究”；说明结果准备用来支持什么判断、决策或后续工作。 |  |
| object | 给用户看的“这次研究什么”；说明研究对象是工具、机制、合同、流程、地点、问题还是材料。 |  |
| scope | 给用户看的“这次回答到哪里”；说明本 run 覆盖什么、不覆盖什么。 |  |
| use | 给用户看的“结果怎么用”；说明产物形态和动作边界。 |  |
| objective | 给用户看的“本 run 准备回答的问题”；最好写成可判断是否回答到位的一句话。 |  |
| first_search_questions | 给用户看的首轮检索问题；只写自然语言问题，不写裸 query。 |  |
| source_surfaces | 给用户看的首轮来源面计划；这是计划，不是证据回看。 |  |
| stop_when | 给用户看的首轮停止口径；说明第一轮搜到什么程度可以停。 |  |
| needs_user_review | 给用户看的待确认项；只列会影响理解、范围、产物或首轮搜索的问题。 |  |

## user_review

| field | 填写说明 | 展示内容 |
|---|---|---|
| decision | 用户对 opening brief 的决定；例如 pending、confirmed、revised。 |  |
| user_feedback | 用户对理解、范围、产物或首轮计划的修正。 |  |
| reviewed_at | 用户审阅时间；没有审阅则留空。 |  |

## field_mapping

| opening brief field | 从 opening note 抽取的字段 |
|---|---|
| intent | `derived.use_intent.value`；必要时参考 `origin_context.raw_input` |
| object | `inquiry_shape.research_object` |
| scope | `scope_boundary.in_scope`、`scope_boundary.out_of_scope` |
| use | `output_action_contract.product_shape`、`output_action_contract.allowed_actions`、`output_action_contract.disallowed_actions`、`scope_boundary.action_boundary` |
| objective | `derived.objective.research_question`、`derived.objective.decision_or_action`、`derived.objective.current_formulation` |
| first_search_questions | `derived.search_plan.first_round.question` |
| source_surfaces | `derived.search_plan.source_surfaces`、`derived.search_plan.first_round.expected_source_surfaces` |
| stop_when | `derived.search_plan.first_round.stop_when` |
| needs_user_review | `tracked_facets` 中 `resolution_state` 不是 `confirmed` 的关键项；以及 `derived.remaining_gaps.user_only` |
| decision | `derived.search_plan.first_round.user_review.decision` |
| user_feedback | `derived.search_plan.first_round.user_review.user_feedback` |
| reviewed_at | `derived.search_plan.first_round.user_review.reviewed_at` |
