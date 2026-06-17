你是一次 Codex CLI 日志可观测性验证任务。

目标：
1. 尽量执行一次联网查证，查询 Codex CLI `codex exec --json` 与 LangGraph streaming `custom/tasks/updates` 的公开文档。
2. 输出必须符合调用方提供的 JSON Schema。
3. 不要修改工作区文件。

请在最终 JSON 中填写：
- `search_task_attempted`: 是否尝试进行联网查证。
- `search_queries`: 你实际使用或准备使用的查询词。
- `sources`: 你找到的 1-3 个来源；如果工具不可用，返回空数组并在 `answer_summary` 说明。
- `tool_log_expectation.expected_tool_event_types`: 你预计 Codex CLI `--json` 事件中可能出现、适配层应观察的事件类型名称；如果无法确认，写出无法确认。
- `tool_log_expectation.what_adapter_should_extract`: 适配层应该从过程日志和最终 JSON 中抽取哪些字段。
- `tool_log_expectation.known_limitations`: 本次验证中发现或预期的限制。
- `answer_summary`: 用 2-4 句话总结这次验证对 LangGraph adapter 是否可行的意义。
