# Split Summary v2 模板

## split_summary

| field | 填写说明 | 填写 |
|---|---|---|
| split_needed | 是否建议拆分；填 `yes`、`no` 或 `uncertain`。 |  |
| topic_count | 候选 topic 数量；如果 `split_needed = no`，填 `1`；不确定时写 `unknown`。 |  |
| reason | 简要说明为什么这样拆分或不拆分。 |  |

## candidate_topics

| id | research_object | decision_or_question | relation_to_others |
|---|---|---|---|
| C1 | 研究对象。说明这一个 topic 要研究的对象是什么；例如某个工具、机制、流程、材料、问题或场景。 | 要支持的判断、决策或核心问题。说明这个 topic 最终要回答什么，或要帮助用户判断什么。 | 与其他候选 topic 的关系；例如 `parallel`、`parent`、`child`、`staged_after`、`alternative`、`merge_candidate`。 |
