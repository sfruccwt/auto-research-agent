你是一次 Codex CLI 联网搜索日志可观测性验证任务。

硬性要求：
1. 不要修改工作区文件。
2. 不要先做代码库扫描、memory 搜索或 git status。
3. 请优先使用可用的 web search / browser / network search 工具，查询下面两个公开文档主题：
   - Codex CLI `codex exec --json`
   - LangGraph streaming `custom` / `tasks` / `updates`
4. 最终输出必须符合调用方提供的 JSON Schema。

请在最终 JSON 中填写：
- `search_task_attempted`: 是否实际尝试了联网查证。
- `search_queries`: 实际使用或准备使用的查询词。
- `sources`: 找到的 1-3 个来源；如果联网工具不可用，返回空数组并在 `answer_summary` 说明。
- `tool_log_expectation.expected_tool_event_types`: 你预计本次 `codex exec --json` 日志里会出现的搜索/工具事件类型；无法确认就写无法确认。
- `tool_log_expectation.what_adapter_should_extract`: LangGraph 适配层应该抽取的字段，例如 query、url、title、tool status、error、final_json_path。
- `tool_log_expectation.known_limitations`: 本次验证中发现或预期的限制。
- `answer_summary`: 用 2-4 句话说明这次验证对 LangGraph adapter 是否可行的意义。
