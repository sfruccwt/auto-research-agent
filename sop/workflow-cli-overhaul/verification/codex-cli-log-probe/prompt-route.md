你是一次 Codex CLI 路由日志可观测性验证任务。

目标：验证 Codex CLI `--json` 是否能记录以下“外部路由 / 浏览器路由”尝试的过程日志。

硬性要求：
1. 不要修改工作区业务文件。
2. 可以执行只读探测命令；命令失败也要继续并在最终 JSON 记录。
3. 最终输出必须符合调用方提供的 JSON Schema。
4. 不要调用 new-run.ps1，不要创建研究 run。

请尝试以下 route probes：

1. AgentReach doctor：
   - 尝试命令：`agent-reach doctor`
   - 目的：看 CLI 是否存在，以及 `command_execution` 日志是否记录 command / output / exit code。

2. AgentReach Exa route：
   - 尝试命令：`mcporter call 'exa.web_search_exa(query: "LangGraph streaming custom tasks checkpoints", numResults: 2)'`
   - 如果 `mcporter` 不存在，记录失败即可。

3. AgentReach Jina route：
   - 尝试命令：`curl -s "https://r.jina.ai/https://docs.langchain.com/oss/python/langgraph/streaming"`
   - 只读取前面一小段即可，不要输出长文。

4. AgentReach GitHub route：
   - 尝试命令：`gh search repos "langgraph langchain" --sort stars --limit 2`
   - 如果 `gh` 不存在或未登录，记录失败即可。

5. Codex in-app browser route：
   - 尝试发现当前会话是否有 in-app browser / browser plugin tool 可用。
   - 如果可以使用，请只打开或读取一个公开页面标题，例如 `https://docs.langchain.com/oss/python/langgraph/streaming`。
   - 如果不可用，不要绕路；记录不可用。

6. Codex Chrome extension route：
   - 尝试发现当前会话是否有 Chrome extension tool 可用。
   - 不要读取 cookies / localStorage / profile / password。
   - 如果可以使用，请只读取一个公开页面标题。
   - 如果不可用，不要绕路；记录不可用。

同时请根据公开知识简短判断 LangSmith 的主要用途和可替代边界：
- LangSmith 主要解决什么问题。
- 哪些可用 LangGraph stream/checkpoint/local JSONL/SQLite 替代。
- 哪些没有产品层时不能完整替代。

最终 JSON 中：
- `route_probes_attempted` 每个 route 填一项。
- `event_types_expected` 写你预计 `events-route.jsonl` 里会出现的事件类型。
- `adapter_fields_to_extract` 写适配层应抽取的字段。
- `langsmith_replacement_assessment` 写替代判断。
