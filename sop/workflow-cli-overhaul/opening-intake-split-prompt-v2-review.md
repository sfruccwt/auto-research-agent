# Opening intake split prompt v2

用途：把一段 raw input 拆成一个或多个可独立研究的候选主题，供 Opening 流程决定后续 run 组织方式。

```text
请判断下面这段 raw input 里包含几个可独立研究的主题。

raw input:
<raw_input>

拆分标准：
- 如果多个问题的研究对象、目标用途、范围或检索路径明显不同，拆成多个候选主题。
- 如果只是同一主题下的步骤、角度或子问题，先合并为一个候选主题。
- 如果主题之间有关系，请标明它们是并列、前置/后续、替代方案，还是可能的母子关系。

请输出：

## split_summary

- split_needed: yes | no | uncertain
- suggested_topic_count:
- reason:

## candidate_topics

| id | topic_title | research_question | research_object | why_separate | relation_to_others | raw_input_cues |
|---|---|---|---|---|---|---|
| C1 |  |  |  |  |  |  |

## organization_hint

简要建议这些候选主题更像：
- parallel_runs
- parent_with_child_runs
- staged_runs
- merge_some_topics

并说明理由。
```
