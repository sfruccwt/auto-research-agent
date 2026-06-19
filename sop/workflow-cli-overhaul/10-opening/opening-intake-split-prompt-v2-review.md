# Opening intake split prompt v2

用途：为 Split Summary JSON / 模板填充提供 topic 拆分判断标准。

```text
请判断 raw input 里包含几个可独立研究的 topic。

拆分标准：
- 主要根据两个维度判断是否是独立 topic：
  1. research_object：研究对象是否不同。
  2. decision_or_question：本 topic 要支持的判断、决策或核心问题是否不同。
- 如果只是同一研究对象、同一核心判断下的步骤、角度、子问题，先合并为一个 topic。
- 如果不确定，标 `uncertain`，把可能拆分点写进 reason，不强行拆。

请按 Split Summary 模板 / JSON schema 填写结果。
```
