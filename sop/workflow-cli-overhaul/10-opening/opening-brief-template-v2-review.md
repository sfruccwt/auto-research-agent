# Opening brief v2 模板

## brief

| field | 填写说明 | 展示内容 |
|---|---|---|
| research_goal | 从 opening note 抽出的研究目标；说明用户为什么要做这次研究、研究对象是什么、准备用结果支持什么判断、决策或后续工作。 |  |
| boundary | 从 opening note 抽出的边界；说明本 run 的内容边界、动作边界、产物形态和目标读者。 |  |
| first_search_questions | 从 opening note 抽出的首轮检索问题；只写自然语言问题，不写裸 query。 |  |
| source_surfaces | 从 opening note 抽出的首轮来源面计划；这是计划，不是证据回看。 |  |
| stop_when | 从 opening note 抽出的首轮停止口径；说明第一轮搜到什么程度可以停。 |  |

## user_review

| field | 填写说明 | 展示内容 |
|---|---|---|
| user_feedback | 用户对理解、范围、产物或首轮计划的修正；如果用户要求 revise，下一版 brief 应吸收这条反馈。 |  |

`decision` 不写入 brief 字段。Opening Review Gate 的运行时动作只有 `confirm` / `revise`：`confirm` 后进入 `seal opening`，`revise` 后带着 `user_feedback` 回到 opening note / brief 重写。挂起状态和审阅时间由 workflow runtime / log 记录，不由 brief 字段承担。

## field_mapping

| opening brief field | 从 opening note 抽取的字段 |
|---|---|
| research_goal | `derived.research_goal.research_goal` |
| boundary | `derived.boundary.boundary` |
| first_search_questions | `derived.search_plan.questions` |
| source_surfaces | `derived.search_plan.source_surfaces` |
| stop_when | `derived.search_plan.stop_when` |
| user_feedback | opening brief review feedback |
