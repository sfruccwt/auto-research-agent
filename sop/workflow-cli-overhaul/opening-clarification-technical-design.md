# Opening brief 技术设计

状态：简化草案
上级流程：`stage-opening-clarification.md`

## 0. 定位

Opening 阶段只做一件事：把 raw intake 变成用户可审阅的 opening brief，并生成首轮检索计划 `notes/search-opening.md`。

它不设计复杂 clarification taxonomy，不自动执行检索，也不要求填满完整 research-state schema。

## 1. 最小执行链条

```text
raw intake
  -> 保真记录 original_user_words
  -> 抽取 opening brief 最小字段
  -> 生成 notes/search-opening.md
  -> 展示 opening brief + first search plan
  -> 用户修改或批准
  -> 写回 research-state
  -> 脚本 seal opening
```

## 2. Opening brief 最小字段

| 字段 | 用户主要审什么 |
|---|---|
| `user_intent` | runner 是否理解了用户为什么要做这次研究。 |
| `research_object` | 研究对象是否正确。 |
| `operation_type` | 研究动作是否正确，例如解释、比较、诊断、选型、规划。 |
| `scope_boundary` | 本 run 回答什么、不回答什么、动作上限是什么。 |
| `use_intent` | 研究结果准备用来做什么、做到什么程度。 |
| `output_shape / action_boundary` | 产物形态和允许动作是否正确。 |
| `source_surfaces` | 第一轮大概要打开哪些来源面。 |
| `first_search_questions` | 第一轮准备回答哪些问题。 |
| `stop_when` | 第一轮做到什么程度可以停。 |
| `temporary_or_default_fields` | 哪些字段是默认、推断或临时值。 |

## 3. `notes/search-opening.md` 最小结构

```markdown
# Search opening

## opening brief

- user_intent:
- research_object:
- operation_type:
- scope_boundary:
- use_intent:
- output_shape / action_boundary:
- temporary_or_default_fields:

## first search plan

- source_surfaces:
- first_search_questions:
- stop_when:

## user review

- decision: confirmed | revised
- user_feedback:
- reviewed_at:
```

## 4. 字段填充原则

- `original_user_words` 必须保真保存，不被用户后续反馈改写。
- 默认值必须标在 `temporary_or_default_fields` 中。
- opening 可以给出轻量 `source_surfaces` 和 `stop_when`，但不扩写成完整证据策略。
- 可搜索事实缺口不在 opening 阶段反复问用户；它进入第一轮 search。
- 只有会改变对象、scope、action boundary 或产物形态的事项，才需要用户在 opening 审阅中修改。

## 5. 与后续 round brief 的区别

Opening brief 没有：

- `previous_search_intent`
- `enough_for`
- `not_enough_for`
- 本轮 evidence 是否服务 original intent 的判断

这些字段只在 search round 执行后出现。
