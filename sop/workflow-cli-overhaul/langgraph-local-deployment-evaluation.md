# LangGraph 本地部署可行性评估

状态：初版判断稿，含一次 Codex CLI 日志可观测性验证

核对日期：2026-06-17

[Time-Check]: Data grounded in search results from June 2026.

## 0. 当前结论

本项目可以把“本地部署 LangGraph”作为一个可行方向保留，但它不应被理解为“把所有 LLM 调用都改成 LangGraph / OpenAI API 调用”。

当前建议固定的方向是：

```text
LangGraph 负责 workflow 编排、state、checkpoint、节点级 runtime。
Codex CLI 作为部分高智能节点的外部 worker。
CodexNodeAdapter 负责把 LangGraph state 转成 codex exec 输入，再把 Codex 输出解析回 LangGraph state。
```

这个方向的价值是：保留 LangGraph 的节点化 workflow 和 runtime 能力，同时避免把研究节点强绑定到 OpenAI API 单独计费路径。

同时需要把“本地跑 LangGraph”和“完整自托管 LangSmith / LangSmith Deployment”拆开：

- `LangGraph` 作为开源 workflow / graph runtime，可以优先本地验证。
- `langgraph dev` / `langgraph up` 是本地开发和 production-like validation 路径；`langgraph dev` 轻量，`langgraph up` 需要 Docker、PostgreSQL、Redis 和 API server。
- `LangSmith` 是 observability / evaluation / deployment 平台，不等于 LangGraph runtime 本身。云端 LangSmith 有免费额度和用量计费；自托管 LangSmith 是 Enterprise plan add-on，不是免费个人本地部署项。
- 因此，本项目的低成本路线应是：先只使用 LangGraph 本地 runtime + run-local 日志；不要把 LangSmith 作为硬依赖。

## 1. 为什么不是直接使用 LangGraph 的 LLM API 路径

LangGraph 节点可以直接调用 LangChain / OpenAI / Anthropic 等模型接口，但这会把模型调用落到 API key / token billing 路径。当前用户约束是：不希望为了这个 workflow 额外接受 OpenAI API 单独计费。

因此，本方案不把 LangGraph 当作“LLM 调用层”，而是把它当作“编排层”。

## 2. LangGraph 能否编排外部 CLI

官方文档足以支持这个判断：LangGraph 的 `Nodes` 本质上是函数。节点接收当前 `state`，执行 computation 或 side-effect，然后返回 state update。文档还明确说明，`Nodes` 和 `Edges` 只是函数，节点可以包含 LLM，也可以只是普通代码。

这意味着，一个节点可以封装外部 CLI 调用，例如：

```text
node_search_with_codex(state)
  -> 生成 Codex prompt 和输出 schema
  -> 调用 codex exec
  -> 捕获 stdout / stderr / exit code / event log
  -> 解析最终 JSON
  -> return {"search_round_result": ..., "codex_node_log": ...}
```

这里的 Codex CLI 对 LangGraph 来说不是“LangGraph 内部 agent”，而是一个由普通节点函数调用的外部 worker。

### 已确认依据

- LangGraph Graph API：`State` 是共享状态，`Nodes` 是执行逻辑的函数，`Edges` 决定下一步；节点可以包含 LLM，也可以只是普通代码。
  来源：<https://docs.langchain.com/oss/python/langgraph/graph-api>，核对日期：2026-06-17。
- LangGraph Streaming：`stream_mode="custom"` 可用于外部模型或外部服务自己的 streaming 接口，说明 LangGraph 并不要求所有模型调用都走 LangChain chat model interface。
  来源：<https://docs.langchain.com/oss/python/langgraph/streaming>，核对日期：2026-06-17。

### 仍需本地验证

官方语义上支持外部 CLI，但本项目仍需要一个最小 PoC 验证：

```text
LangGraph dev
  -> 一个 Python node 调 subprocess.run(["codex", "exec", ...])
  -> Codex 输出 JSON
  -> LangGraph state 接收并继续到下一 node
```

这个验证不需要完整部署，也不需要先改研究 runner。只需要一个临时最小 graph，确认外部进程调用、超时、退出码、输出解析和 state 更新都能跑通。

## 3. Codex CLI 节点适配层

建议新增一个很薄的适配层，暂称 `CodexNodeAdapter`。它不承担研究语义，只承担边界转换。

| 职责 | 说明 |
|---|---|
| 输入整理 | 从 LangGraph state 中抽取本节点需要的 `task_intent`、上下文、文件路径、输出要求 |
| prompt 生成 | 生成给 `codex exec` 的非交互 prompt |
| 输出约束 | 优先使用 `codex exec --output-schema`，要求最终输出可被 controller 校验 |
| 进程调用 | 调用 Codex CLI，设置 working directory、timeout、sandbox / profile 参数 |
| 结果采集 | 捕获 stdout、stderr、exit code、最终 JSON、可选 JSONL events |
| state 写回 | 只把压缩后的结果、错误、日志路径、证据 URL / 文件路径写回 LangGraph state |
| 审计辅助 | 可选把 Codex 原始事件写入 run-local log 文件，但不直接塞进 `research-state` |

Codex 官方文档确认：

- `codex exec` 用于 scripted / CI-style 的非交互任务。
- `--json` 可以输出 newline-delimited JSON events。
- `--output-last-message` 可把最终消息写入文件。
- `--output-schema` 可要求最终响应符合 JSON Schema，适合下游自动化稳定解析。

来源：

- <https://developers.openai.com/codex/cli/reference#codex-exec>，核对日期：2026-06-17。
- <https://developers.openai.com/codex/noninteractive#create-structured-outputs-with-a-schema>，核对日期：2026-06-17。

## 4. LangGraph runtime 在该方案中仍然有效的范围

LangGraph runtime 仍然有效，但只覆盖 LangGraph 能看见的边界。

| 能力 | 在 Codex CLI 节点方案中是否有效 | 说明 |
|---|---|---|
| 节点调度 | 有效 | Codex 调用被包成普通 LangGraph node |
| state 更新 | 有效 | 前提是 adapter 把 Codex 输出解析成 state update |
| checkpoint | 有效 | 保存的是节点完成后的 graph state |
| resume / fault tolerance | 部分有效 | 可从上一个 checkpoint 恢复；正在运行的 Codex 子进程通常不能被 LangGraph 原生恢复 |
| streaming updates | 有效 | 可看到节点级 updates；内部 Codex 事件需 adapter 主动转发 |
| tasks / debug stream | 有效 | 可看到哪个节点运行、结果和错误；内部工具调用不自动展开 |
| LangSmith 顶层 trace | 有效 | 可看到 LangGraph 节点；自定义内部 trace 需手动包装 |
| Codex 内部工具调用记录 | 待验证 | 取决于 `codex exec --json` 输出粒度和本地 CLI 行为 |

LangGraph persistence 文档说明，checkpointer 持久化 thread 的 graph state，可用于 conversation continuity、human-in-the-loop、time travel 和 fault tolerance；store 用于跨 thread 长期数据。
来源：<https://docs.langchain.com/oss/python/langgraph/persistence>，核对日期：2026-06-17。

LangGraph streaming 文档说明：

- `checkpoints` mode 可接收 checkpoint events。
- `tasks` mode 可接收节点开始、结束、结果和错误。
- `debug` mode 输出更完整的节点名和 state。
- `custom` mode 可从外部 LLM API 或外部服务转发自定义数据。

来源：<https://docs.langchain.com/oss/python/langgraph/streaming>，核对日期：2026-06-17。

## 5. 日志与可观测性边界

本方案需要明确两层日志：

| 层 | 记录什么 | 写入位置建议 |
|---|---|---|
| LangGraph runtime log | node start / end、state update、checkpoint、error | LangGraph stream / checkpointer / LangSmith |
| Codex worker log | `codex exec` prompt、最终输出、exit code、stderr、可选 JSONL events | run-local adapter log，例如 `logs/codex-node-*.jsonl` |

不要假设 LangGraph 会自动理解 Codex 内部工具调用。Codex 是外部进程，除非 adapter 把内部事件转写为 LangGraph custom stream、state 字段或 LangSmith trace，否则 LangGraph 只能看到“这个节点调用了一个外部命令并返回了某个结果”。

### 5.1 Codex CLI 日志验证结果

验证日期：2026-06-17。

验证位置：

```text
sop/workflow-cli-overhaul/verification/codex-cli-log-probe/
```

验证目标：

- `codex exec --json` 是否能输出过程事件。
- `--output-schema` / `--output-last-message` 是否能稳定产出最终 JSON。
- web search 事件与 shell 工具事件是否能被 adapter 抽取。
- 这些事件是否能映射到 LangGraph `custom` / `updates` / `tasks` stream。

验证命令形态：

```text
codex exec
  --json
  --sandbox workspace-write
  -c sandbox_workspace_write.network_access=true
  -c web_search="live"
  -c memories.use_memories=false
  -c memories.generate_memories=false
  --output-schema schema.json
  --output-last-message final-web.json
```

验证产物：

| 文件 | 说明 |
|---|---|
| `schema.json` | 最终 JSON 的约束 schema |
| `prompt.md` | read-only shell / 文件探针 |
| `prompt-web.md` | web search 探针 |
| `events.jsonl` | read-only 探针的 Codex NDJSON 事件 |
| `final.json` | read-only 探针的最终结构化输出 |
| `events-web.jsonl` | web search 探针的 Codex NDJSON 事件 |
| `final-web.json` | web search 探针的最终结构化输出 |
| `stderr*.txt` / `exit_code*.txt` | 子进程 stderr 与退出码 |

#### 观察 1：`--json` 能输出工具过程事件

`events.jsonl` 中观察到以下事件形态：

```json
{"type":"thread.started","thread_id":"..."}
{"type":"turn.started"}
{"type":"item.started","item":{"type":"command_execution","command":"...","status":"in_progress"}}
{"type":"item.completed","item":{"type":"command_execution","command":"...","aggregated_output":"...","exit_code":0,"status":"completed"}}
{"type":"turn.completed","usage":{"input_tokens":...,"output_tokens":...}}
```

这说明 shell 类工具调用至少可以抽取：

- `thread_id`
- `item.id`
- `item.type`
- `item.command`
- `item.status`
- `item.exit_code`
- `item.aggregated_output`
- `turn.completed.usage`

#### 观察 2：web search 事件可见

`events-web.jsonl` 中观察到 web search 事件：

```json
{"type":"item.started","item":{"type":"web_search","id":"...","query":"","action":{"type":"other"}}}
{"type":"item.completed","item":{"type":"web_search","id":"...","query":"2026-06-17 latest status today OpenAI Codex CLI web search logging observability","action":{"type":"search","query":"...","queries":["..."]}}}
{"type":"item.completed","item":{"type":"web_search","id":"...","query":"https://developers.openai.com/codex/changelog","action":{"type":"other"}}}
```

这说明联网搜索类日志至少可以抽取：

- 是否发生 web search。
- search query。
- search action type。
- 后续打开 / 访问的 URL。
- web search item id。

但本次 NDJSON 事件没有直接暴露完整搜索结果列表的每条 title / snippet / URL。最终 JSON 中可以由 Codex 自己填写 `sources`，但这属于模型生成的结构化交接结果，不等同于 runtime 原始工具日志。

#### 观察 3：最终 JSON 可稳定落盘

`final-web.json` 成功按 `schema.json` 生成，包含：

- `search_task_attempted`
- `search_queries`
- `sources`
- `tool_log_expectation`
- `answer_summary`

这验证了 adapter 可以把最终 JSON 当作稳定交接面；过程 NDJSON 则作为审计证据和可选摘要来源。

#### 观察 4：当前运行需要子 Codex 访问用户级状态目录

第一次在当前外层沙箱内直接运行时失败，原因是子 `codex exec` 无法写入：

```text
C:\Users\cwt\.codex\sqlite\state_5.sqlite
```

以及无法初始化 in-process app-server client。使用外部执行权限后成功。这意味着如果 LangGraph 节点要本地调用 Codex CLI，adapter 需要明确处理：

- `CODEX_HOME` / 用户级状态目录访问权限。
- `sqlite_home` 是否可定向到 run-local 或专用目录。
- 非交互场景下的 sandbox / approval / network 配置。
- 子 Codex session 是否允许持久化，或者是否使用 `--ephemeral`。

#### 与 LangGraph stream 的匹配关系

LangGraph v2 stream chunk 的统一形态是：

```json
{
  "type": "values | updates | messages | custom | checkpoints | tasks | debug",
  "ns": [],
  "data": {}
}
```

来源：<https://docs.langchain.com/oss/python/langgraph/streaming>，核对日期：2026-06-17。

本次验证显示，Codex NDJSON 不需要和 LangGraph 原生 schema 完全一致；adapter 可以做如下映射：

| Codex CLI 事件 | Adapter 抽取 | LangGraph stream 建议映射 |
|---|---|---|
| `thread.started` | `codex_thread_id` | `custom` |
| `turn.started` | `codex_turn_status=started` | `custom` |
| `item.started` + `command_execution` | command、item id、status | `custom` |
| `item.completed` + `command_execution` | command、aggregated_output、exit_code、status | `custom`，必要时压缩后写 `updates` |
| `item.started/completed` + `web_search` | query、action.type、item id、URL | `custom`，并压缩为 `source_and_route_log` 候选 |
| `agent_message` final JSON | schema 校验后的业务结果 | `updates` |
| `turn.completed.usage` | token usage | `custom` 或 node log |
| 子进程 exit code / stderr / timeout | 进程级状态 | `tasks` error / result，或 node update 中的 `adapter_status` |

#### 当前判断

Codex CLI 适配层具备可行性，但边界应这样定：

```text
可信交接面：--output-schema 生成的 final JSON
过程审计面：--json 生成的 NDJSON events
LangGraph 可见面：adapter 转写后的 custom / updates / tasks
```

本次验证已经证明：

- shell 工具调用日志可见。
- web search 调用日志可见。
- 最终 JSON 可按 schema 落盘。
- 可以设计 adapter 把 Codex events 转成 LangGraph `custom` stream。

仍然未证明：

- Codex 的 browser / MCP / app connector 等所有工具都有同等粒度事件。
- web search 原始搜索结果列表是否能从 NDJSON 直接完整提取。
- 事件字段是否长期稳定；需要把解析器写成容错逻辑。
- 在 Docker / `langgraph up` 容器内调用宿主 Codex CLI 是否可行。

因此，adapter 的策略应是：原样保存完整 NDJSON；只把稳定字段解析为摘要；最终业务判断以 `--output-schema` 的 final JSON 为准。

### 5.2 AgentReach / Browser / Chrome 路由日志验证结果

验证日期：2026-06-17。

验证位置：

```text
sop/workflow-cli-overhaul/verification/codex-cli-log-probe/
```

新增验证产物：

| 文件 | 说明 |
|---|---|
| `schema-route.json` | route probe 的最终 JSON schema |
| `prompt-route.md` | 要求子 Codex 尝试 AgentReach、Jina、GitHub、in-app browser、Chrome extension route |
| `events-route.jsonl` | 本次 route probe 的 Codex NDJSON 事件 |
| `final-route.json` | 本次 route probe 的最终结构化输出 |
| `stderr-route.txt` / `exit_code-route.txt` | 子进程 stderr 与退出码 |

本次验证命令形态：

```text
codex exec
  --json
  --sandbox workspace-write
  -c sandbox_workspace_write.network_access=true
  -c web_search="live"
  -c memories.use_memories=false
  -c memories.generate_memories=false
  --output-schema schema-route.json
  --output-last-message final-route.json
```

#### Route probe 结果

| route | 机制 | 结果 | 日志可见性 |
|---|---|---|---|
| AgentReach doctor | `agent-reach doctor` | 失败：本机子 Codex 环境中 `agent-reach` 不是可识别命令 | 可见：`command_execution` 记录 command、失败输出、exit code、status |
| AgentReach Exa route | `mcporter call 'exa.web_search_exa(...)'` | 失败：`mcporter` 不是可识别命令 | 可见：`command_execution` 记录 command、失败输出、exit code、status |
| AgentReach Jina route | `curl.exe https://r.jina.ai/...` | 失败：TLS / Schannel `SEC_E_NO_CREDENTIALS` | 可见：`command_execution` 记录 URL、HTTP/error text、exit code、status |
| AgentReach GitHub route | `gh search repos "langgraph langchain"` | 成功：返回 public repo rows | 可见：`command_execution` 记录 command、aggregated output、exit code、status |
| Codex in-app browser route | `agent.browsers.get("iab")` | 失败：`Browser is not available: iab` | 可见：`mcp_tool_call` 记录 server/tool/arguments/result/status |
| Codex Chrome extension route | `agent.browsers.get("extension")` + 临时 tab 打开公开文档 | 成功：读取标题 `Streaming - Docs by LangChain` 和 URL | 可见：`mcp_tool_call` 记录 server/tool/arguments/result/status，并带 `_meta.codex/toolSurface.backend="chrome"` |

这里有一个重要边界：AgentReach 的“路由”有两层含义。

- 在 Codex / agent 语义层，`agent-reach` 是 skill 路由表。
- 在 shell 执行层，部分路由依赖外部命令，例如 `agent-reach`、`mcporter`、`gh`、`curl`。

因此 adapter 不应假设所有 AgentReach 路由都一定可执行。更稳妥的策略是：

```text
先记录 route_intent
再记录 route_backend_command
再记录 command_execution / mcp_tool_call 的结果
最后由 final JSON 给出业务摘要
```

#### 事件形态

本次 `events-route.jsonl` 中观察到：

```text
thread.started
turn.started
item.started / item.completed + item.type=command_execution
item.started / item.completed + item.type=mcp_tool_call
item.completed + item.type=agent_message
turn.completed
```

`command_execution` 对 shell route 的审计字段包括：

- `item.id`
- `item.type`
- `item.command`
- `item.aggregated_output`
- `item.exit_code`
- `item.status`

`mcp_tool_call` 对 Browser / Chrome route 的审计字段包括：

- `item.id`
- `item.type`
- `item.server`
- `item.tool`
- `item.arguments.title`
- `item.arguments.code`
- `item.result.content[].text`
- `item.status`
- `item.result._meta.codex/toolSurface.backend`
- `item.result._meta.codex/toolSurface.kind`

这说明 Codex CLI 适配层不仅能记录 shell 类工具，也能记录 MCP / browser plugin 类工具调用。对本项目最关键的是：Chrome extension route 成功时，日志中能看到工具调用、backend、脚本参数和最终页面标题 / URL；in-app browser route 不可用时，也能得到明确失败原因。

#### 对本项目的影响

这次 route probe 强化了上一节判断：

```text
Codex CLI process log = 可审计底层
Codex final schema JSON = 稳定业务交接层
LangGraph custom stream = adapter 转写后的 runtime 可见层
本项目 search-round/source_and_route_log = 人可读审计面
```

建议 adapter 的 route log 最小字段为：

| 字段 | 来源 |
|---|---|
| `route_intent` | adapter / prompt 显式传入 |
| `route_backend` | `command_execution` / `mcp_tool_call` / `web_search` |
| `command_or_tool` | `item.command` 或 `server/tool/arguments.title` |
| `status` | `item.status` |
| `exit_code` | shell route 的 `item.exit_code` |
| `output_excerpt` | `aggregated_output` 或 `result.content[].text` 的压缩摘要 |
| `url_or_query` | command / arguments / final JSON 中抽取 |
| `fallback_reason` | 失败输出或 final JSON 中解释 |
| `final_sources` | `--output-schema` final JSON |

本次也暴露了一个控制问题：子 Codex 虽然被 prompt 要求不要先扫 repo，但仍然执行了若干本地 `Get-ChildItem` / `rg` 检查。适配层不能只靠 prompt 约束路由行为；如果要严格控制工具调用范围，需要通过 sandbox、tool availability、工作目录、prompt、以及外层 controller 校验共同约束。

### 待验证项 1：Codex 内部事件粒度

已完成一次最小本地验证，确认 `codex exec --json` 暴露 shell 和 web search 的过程事件。但仍需要后续覆盖更多 Codex 工具类型：

- browser / in-app browser / Chrome extension：已验证 Chrome extension route 可见，in-app browser 在当前子 Codex 环境不可用但失败原因可见。
- MCP tool。
- app connector。
- approval / sandbox escalation。
- 长任务 resume / timeout / interrupted。

如果后续事件粒度足够完整，adapter 可把它压缩成 `codex_node_log_summary` 写回 state 或 run-local log。
如果某些工具事件粒度不足，只把 Codex 最终结构化输出作为可信交接面，内部过程另作为 Codex 自己的 session 记录，不纳入 LangGraph runtime 的强审计面。

### 待验证项 2：LangSmith 是否需要手动 trace

LangSmith 对 LangGraph 有集成；但使用非 LangChain SDK 或自定义函数时，官方建议用 `@traceable` / wrapper 之类方式手动包装，才会形成嵌套 trace。

来源：<https://docs.langchain.com/langsmith/trace-with-langgraph>，核对日期：2026-06-17。

因此 Codex adapter 的默认策略应是：

```text
先保证 run-local 文件日志和 LangGraph state 可靠。
再考虑是否把 adapter 包成 LangSmith traceable function。
```

## 6. 收费与本地部署边界

### 6.1 结论

当前不能把“LangGraph + LangSmith 整套都能免费本地部署”作为前提。更准确的判断是：

| 组件 / 能力 | 是否可本地使用 | 当前收费判断 | 对本项目的建议 |
|---|---|---|---|
| `langgraph` 开源库 | 可以 | 本身不是 LangSmith 计费项 | 可作为 workflow 编排核心 |
| `langgraph dev` | 可以 | 官方要求准备 LangSmith API key，注册免费；但如果发送 traces 到 LangSmith，会进入 LangSmith 免费额度 / 用量边界 | 可用于最小 PoC；优先关闭或最小化 LangSmith 依赖 |
| `langgraph up` | 可以 | 本地 Docker stack 本身不是云部署计费；但更重，且自定义 auth 等能力可能需要 license key | 只作为后续 production-like validation |
| LangSmith Cloud observability / eval | 云端服务 | Developer plan：1 seat、5k base traces / month included，超过后 pay-as-you-go | 不作为硬依赖；若使用，必须控制 trace 量 |
| LangSmith Deployment | 云端 / 平台服务 | Plus plan 才包含 1 个 free dev-sized deployment；额外 deployment run 和 uptime 会计费 | 暂不采用 |
| LangSmith Fleet | 云端 / 平台服务 | Developer plan 有 50 Fleet runs / month；Fleet runs 会自动 trace 并计入 LangSmith 用量 | 暂不采用 |
| LangSmith Engine | 云端 / 平台服务 | Plus plan 后按 LCU 计费 | 暂不采用 |
| LangSmith Sandboxes | 云端 / 平台服务 | Plus plan 后按 CPU / memory / storage 计费 | 暂不采用 |
| Self-hosted LangSmith | 自有基础设施 | 官方写明是 Enterprise plan add-on，需要联系 sales 获取 trial license key | 不作为个人本地免费方案 |
| LLM / third-party tools | 取决于 provider | LangSmith pricing 明确模型费用由模型 provider 另行计费；第三方工具也可能单独计费 | 本项目继续走 Codex CLI / 用户账号约束，不默认接入 provider API key |

### 6.2 官方依据

LangGraph 本地开发文档把本地 Agent Server 分成两条命令：

- `langgraph dev`：轻量开发 server，不需要 Docker，直接运行在本地环境，state persisted to local directory。
- `langgraph up`：production-like validation，需要 Docker，并运行 server、PostgreSQL、Redis 等容器，资源占用更高。

同一文档还写明，开始 `langgraph dev` 前需要一个 LangSmith API key，并注明注册免费。
来源：<https://docs.langchain.com/langgraph-platform/local-server>，核对日期：2026-06-17。

LangSmith pricing 页面显示：

- Developer plan：`$0 / seat per month`，但 `then pay as you go`；包含 1 seat 和 5k base traces / month。
- Plus plan：`$39 / seat per month`，包含 1 个 dev-sized agent deployment；额外 deployment run、deployment uptime、Fleet run、Engine、Sandboxes 等有各自计费项。
- Pricing FAQ 明确：model usage billed separate by your model provider；第三方工具费用也由第三方 provider 收取。

来源：<https://www.langchain.com/pricing>，核对日期：2026-06-17。

Self-hosted LangSmith 文档明确写明：Self-hosted LangSmith is an add-on to the Enterprise plan，并需要联系 sales 获取 license key 试用。它包含 frontend、backend API、Platform backend、Playground、queue、ACE backend，以及 ClickHouse、PostgreSQL、Redis、blob storage 等存储服务。
来源：<https://docs.langchain.com/langsmith/self-hosted>，核对日期：2026-06-17。

Self-hosted dependency 文档还要求 PostgreSQL、Redis / Valkey、ClickHouse、Kubernetes / Helm / Docker 等依赖，并提到 LangSmith 0.9.0 后默认需要到 `https://beacon.langchain.com` 的 egress 做 license verification 和 usage reporting，除非运行 offline mode。
来源：<https://docs.langchain.com/langsmith/self-host-dependency-versions>，核对日期：2026-06-17。

### 6.3 对本项目的直接影响

如果用户的硬约束是“不接受 OpenAI API 单独计费，也不希望引入新的平台服务账单”，那么默认架构应避免依赖以下能力：

- LangSmith Cloud tracing / eval 作为必须路径。
- LangSmith Deployment。
- LangSmith Fleet。
- LangSmith Engine。
- LangSmith Sandboxes。
- Self-hosted LangSmith。

本项目可以先保留这些能力的接口位置，但实际运行时只依赖：

```text
LangGraph local graph runtime
Codex CLI
CodexNodeAdapter
run-local logs
本项目已有 controller / state / seal 机制
```

### 6.4 待验证项 3：`langgraph dev` 是否能完全离线 / 不写 LangSmith

官方本地开发文档要求准备 LangSmith API key，但这不等于业务逻辑必须把 traces 发到 LangSmith。对本项目来说，需要本地验证：

- `langgraph dev` 是否可以在不配置 LangSmith tracing 的情况下启动和执行最小 graph。
- 如果必须配置 LangSmith API key，是否只是用于 Studio / UI / auth，而不是强制把本地执行日志上传。
- 哪些环境变量可以关闭 tracing 或把 trace 写入本地。
- 关闭 LangSmith 后，`tasks` / `debug` / `custom` stream 和 checkpointer 是否仍满足本项目审计需求。

这个验证优先级高于 LangSmith 自托管。因为如果 `langgraph dev + run-local logs` 已经满足本项目调试和审计需求，就不需要进入 LangSmith 账单边界。

### 6.5 没有 LangSmith 时，runtime 追踪是否完全不可用

结论：不是。没有 LangSmith 时，缺失的是托管 observability 产品层，不是 LangGraph runtime 的全部追踪与审计能力。

先明确 LangSmith 的产品定位。官方文档把 LangSmith 分成几类主要能力：

| 能力 | LangSmith 解决什么问题 | 本项目是否必须依赖 |
|---|---|---|
| Observability | 从单次 trace 到生产性能指标，查看、过滤、导出、分享、比较 traces，建立 dashboards / alerts | 非必须；本地可用 JSONL / SQLite / Markdown 做低配替代 |
| Evaluation | 离线评测、在线评测、dataset、evaluator、experiment compare、回归测试、生产质量监控 | 非必须；本项目初期可用固定 fixtures + 脚本校验替代 |
| Prompt engineering | prompt 创建、版本管理、tag、webhook、prompt hub、Playground | 非必须；本项目可用 repo 内 Markdown / JSON schema / git 版本管理替代 |
| Context Hub / Studio / Deployment | agent context、可视化调试、部署与平台协作能力 | 本地 demo 阶段不采用 |
| Engine | 自动发现重复失败、诊断根因、辅助修复 | 不采用；可后续用本地规则 / review gate 替代一部分 |

来源：

- LangSmith Observability：<https://docs.langchain.com/langsmith/observability>，核对日期：2026-06-17。
- LangSmith Evaluation：<https://docs.langchain.com/langsmith/evaluation>，核对日期：2026-06-17。
- LangSmith Prompt engineering：<https://docs.langchain.com/langsmith/prompt-engineering>，核对日期：2026-06-17。

因此，LangSmith 不是 LangGraph 节点运行的必要 runtime；它更像是围绕 LLM / agent 应用的托管 trace、eval、prompt、monitoring、collaboration 产品层。是否值得接入取决于目标：

| 目标 | 判断 |
|---|---|
| 个人本地 demo、验证 LangGraph + Codex CLI adapter | 不需要 LangSmith |
| 需要可审计、可恢复、可查看本地过程 | 用 LangGraph stream / checkpoint + 本地 JSONL / SQLite 足够起步 |
| 需要团队共享 trace UI、在线评估、告警、反馈队列、长期保留 | LangSmith 或同类产品才有明显价值 |
| 不接受平台账单，但想要 UI | 考虑自建轻量 UI，或后续评估 Langfuse / Phoenix / OTel 等第三方栈 |

LangGraph 本地仍可用的 runtime 追踪 / 审计入口包括：

| 能力 | 是否依赖 LangSmith | 本项目用途 |
|---|---|---|
| `stream_mode="updates"` | 否 | 记录每个节点后的 state update |
| `stream_mode="values"` | 否 | 记录每步完整 state snapshot，适合调试 |
| `stream_mode="custom"` | 否 | adapter 主动转发 Codex CLI 事件、进度、source log |
| `stream_mode="checkpoints"` | 否，但需要 checkpointer | 观察 checkpoint 写入 |
| `stream_mode="tasks"` | 否，但需要 checkpointer | 观察 task start / finish / result / error |
| `stream_mode="debug"` | 否 | 获取更完整 runtime debug 信息 |
| `stream_events()` | 否 | 新版 typed projections，适合应用侧消费 message / state / output / subgraph / interrupt / extension |
| checkpointer | 否 | 保存 thread-scoped graph state，用于 resume、fault tolerance、time travel、审计 |
| `graph.get_state()` / `graph.get_state_history()` | 否 | 读取当前 state 与历史 state snapshot |
| `runtime.execution_info` | 否 | 节点内读取 attempt、thread id、run id、checkpoint id 等执行信息 |

来源：

- LangGraph Streaming：<https://docs.langchain.com/oss/python/langgraph/streaming>，核对日期：2026-06-17。
- LangGraph Event Streaming：<https://docs.langchain.com/oss/python/langgraph/event-streaming>，核对日期：2026-06-17。
- LangGraph Persistence：<https://docs.langchain.com/oss/python/langgraph/persistence>，核对日期：2026-06-17。
- LangGraph Checkpointers：<https://docs.langchain.com/oss/python/langgraph/checkpointers>，核对日期：2026-06-17。
- LangGraph Fault tolerance：<https://docs.langchain.com/oss/python/langgraph/fault-tolerance>，核对日期：2026-06-17。

没有 LangSmith 时缺失的是：

- 可视化 trace tree / run graph UI。
- trace 查询、过滤、分享、导出、比较。
- dashboard / alert / feedback queue / automation。
- LangSmith Engine 的故障聚类、诊断和修复建议。
- 跨项目 / 团队的统一 trace 管理、权限、retention、usage 视图。

来源：LangSmith Observability，<https://docs.langchain.com/langsmith/observability>，核对日期：2026-06-17。

因此，本项目如果不接受 LangSmith 账单，最低可行审计面应设计为：

```text
LangGraph stream / event chunks
  -> CodexNodeAdapter 统一标准化
  -> run-local JSONL / SQLite / Markdown audit surface
  -> 本项目 controller 执行 validate / snapshot / log / status / seal
```

这不是 LangSmith 的完整替代品，但足够支撑个人本地 demo 的可追溯性：能知道哪个节点运行、输入输出如何更新、checkpoint 何时产生、Codex CLI 发生了哪些 shell / web_search 过程事件、最终 JSON 如何写回 state。

第三方替代方案方面，Langfuse 提供了 LangGraph callback handler 示例，可用 `graph.stream(..., config={"callbacks": [langfuse_handler]})` 或 `compile().with_config(...)` 接入。它可以作为非 LangSmith 的 tracing 方向，但属于第三方集成，不是 LangGraph 原生本地 UI，采用前仍需要 PoC。
来源：<https://langfuse.com/guides/cookbook/integration_langgraph>，核对日期：2026-06-17。

## 7. 本地部署硬件约束

### `langgraph dev`

官方定位：

- 不需要 Docker。
- 直接运行在本地 Python / Node 环境。
- 启动快，支持 hot reload。
- state 使用 in-memory 并 pickled 到本地目录。
- resource usage 标注为 lightweight。

来源：<https://docs.langchain.com/langgraph-platform/local-server>，核对日期：2026-06-17。

官方没有给出 `langgraph dev` 的精确 RAM / disk 数字。基于其“不需要 Docker、直接本地运行、轻量”的官方定位，本项目可先按以下保守预算判断：

| 项 | 建议预算 | 说明 |
|---|---:|---|
| 运行时内存 | 1-2 GB 余量起步 | 不含 Codex CLI 自身、浏览器、IDE、检索工具和本地模型 |
| 硬盘 | 2-5 GB 可用空间起步 | 覆盖 Python / Node 依赖、虚拟环境、缓存、少量 state / log |
| CPU | 普通开发机即可 | 主要耗时在外部 LLM / Codex / 网络工具，不在 LangGraph 调度本身 |
| 16 GB 内存机器 | 可做本地 dev 验证 | 需要控制浏览器、IDE、Docker、多个 agent 并发带来的叠加占用 |

这不是官方硬指标，只是本项目的本地验证预算。真正的数值应由最小 PoC 实测补充。

### `langgraph up`

官方定位：

- 需要 Docker。
- 用于 production-like validation。
- 会运行 API server、PostgreSQL、Redis 等容器。
- resource usage 标注为 heavier。
- 本地 Docker 常见资源问题包括 RAM 和 disk 不足。

来源：<https://docs.langchain.com/langgraph-platform/local-server>，核对日期：2026-06-17。

Docker Desktop Windows 官方要求 WSL2 / Hyper-V 路径的硬件前提包含 8 GB system RAM。
来源：<https://docs.docker.com/desktop/setup/install/windows-install/>，核对日期：2026-06-17。

对本项目而言，`langgraph up` 不应作为第一步。先用 `langgraph dev` 验证节点和 adapter，再考虑 Docker 化。

## 8. 本项目的建议验证顺序

### 第一步：最小 Codex 节点 PoC

目标：验证 LangGraph node 能否调用外部 Codex CLI，并把结果写回 state。

最小输入：

```json
{
  "task_intent": "总结一个固定文本",
  "expected_output": "JSON"
}
```

最小输出：

```json
{
  "codex_exit_code": 0,
  "codex_final_json": {},
  "codex_event_log_path": "logs/codex-node-001.jsonl",
  "adapter_status": "ok"
}
```

验收：

- LangGraph 能继续执行下一个 node。
- state 中能看到 Codex 输出。
- 失败时能记录 exit code / stderr / timeout。

### 第二步：Codex 事件粒度验证

目标：验证 `codex exec --json` 是否足以作为内部工具调用审计来源。

验收：

- 能否识别每次工具调用。
- 能否提取 URL / 文件路径 / 错误。
- 能否压缩成本项目 `source_and_route_log` 所需字段。

### 第三步：LangGraph runtime 绑定验证

目标：验证 checkpointer、tasks/debug/custom stream 对 Codex 节点的可见性。

验收：

- checkpoint 能保存 Codex 节点后的 state。
- tasks/debug 能显示 Codex 节点 start/end/error。
- custom stream 能否接收 adapter 转发的 Codex progress。

### 第四步：LangSmith 依赖关闭验证

目标：确认本地 `langgraph dev` 是否能在不产生 LangSmith 云端账单风险的情况下运行。

验收：

- 不使用 LangSmith tracing 时，最小 graph 能启动和执行。
- 或者即使需要 LangSmith API key，也确认不会默认产生超过免费额度的 trace 写入。
- run-local adapter log 足以替代 LangSmith trace 作为当前阶段审计面。

### 第五步：再决定是否进入 `langgraph up`

只有前四步通过后，才需要考虑 Docker 化。Docker 化时要额外解决：

- 容器内是否安装 Codex CLI。
- 容器是否能安全读取 Codex auth。
- 工作区路径如何映射。
- Codex sandbox / approval 如何设置成非交互可运行。
- 是否允许容器访问网络、浏览器或宿主机工具。

## 9. 当前架构判断

当前固定为可行方向之一：

```text
LangGraph = workflow 编排层
Codex CLI = 高智能外部 worker
CodexNodeAdapter = 输入 / 输出 / 日志 / trace 适配层
本项目 controller = 结构封账层
```

不把 LangGraph 替换为本项目 controller。二者职责不同：

| 层 | 职责 |
|---|---|
| LangGraph | 运行节点图、维护 graph state、checkpoint、stream、node-level runtime |
| Codex CLI | 执行具体智能任务，例如搜索、总结、代码/文档分析 |
| CodexNodeAdapter | 把 Codex 变成 LangGraph 可调用、可解析、可记录的节点 |
| 本项目 controller | validate / snapshot / log / status / seal，不做语义判断 |

这条路线不要求现在手搓完整 runtime。真正需要新增的是 adapter 和 PoC 验证。
