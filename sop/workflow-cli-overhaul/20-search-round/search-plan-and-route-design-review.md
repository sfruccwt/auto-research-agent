# Search plan 与工具路由设计

状态：讨论稿
关联文件：`../10-opening/opening-note-template-v2-review.md`、`../10-opening/opening-brief-template-v2-review.md`、`../90-knowledge/ai-search-tooling-knowledge-review.md`
核对时间：2026-06-18

[Time-Check]: Data grounded in OpenAI official docs and local source review from June 2026, plus existing official-source URLs recorded in `../90-knowledge/ai-search-tooling-knowledge-review.md`.

## 0. 这份文档回答什么

这份文档不再重复“Exa / Jina / browser 分别是什么”。它只回答两个执行设计问题：

1. 如何从 Opening 已有字段衍生首轮 search plan，再由 search plan 生成 query。
2. 一轮 search round 内部，如何调用 Exa / fetch-reader / browser 这三类基础工具。

当前结论：

- `opening note` 和 `opening brief` 仍然只写自然语言 `questions`、`source_surfaces`、`stop_when`，不直接写裸 query。
- `search plan` 是介于 Opening 和 Search Round route adapter 之间的执行约束包：它把“为什么搜、搜什么、不搜什么、优先读什么来源、什么时候停”压成可路由的计划。
- query 不是一个字符串，而是一组按来源面和证据任务拆出的 query pack。好 query 的核心不是“长”或“短”，而是把研究意图、来源类型、限制条件和反向验证拆对。
- 一轮内默认流程是：discover 候选来源 -> triage 摘要/片段 -> 选择少量 URL 全文读 -> gap / negation / pivot 补搜 -> browser 复核真实页面或动态内容 -> 压缩写入 `search-round-N.md`。
- 公开资料足够支持“可审计动作和可控参数”的设计，但不支持声称任何 hosted search 或搜索引擎公开了完整 ranking、query rewrite 或页面选择算法。

## 1. search plan 是什么

`derived.search_plan.questions` 仍然是给人看的首轮研究问题。这里讨论的 `search plan` 是给 route adapter 的执行输入，建议只在 search round 启动时生成，或者写入 `search-round-N.md` 的执行计划区，不回填到 Opening 模板。

推荐形态：

| 字段 | 来自哪里 | 作用 |
|---|---|---|
| `round_goal` | `derived.research_goal` + `questions` | 说明本轮要把哪类不确定性推进一步。 |
| `must_cover` | `questions` | 本轮必须覆盖的 2-4 个子问题。 |
| `must_not_cover` | `boundary` | 明确不展开的方向，防止 query 蔓延。 |
| `source_priority` | `source_surfaces` | `primary / community / web` 的优先级和用途。 |
| `evidence_target` | `stop_when` | 本轮停下来的证据条件。 |
| `query_pack` | route adapter 衍生 | 实际 query、domain/date/category/filter、known URL、browser entrypoint。 |
| `read_budget` | route adapter 衍生 | 本轮最多读多少候选、多少全文、多少 browser 复核。 |
| `pivot_rules` | `stop_when` + round gaps | 什么时候换关键词、加否定、换来源面或升级工具。 |

关键边界：这里的 `search plan` 不是另一个大模板。它只是把 Opening 的自然语言计划翻译成“本轮可执行但受限制的检索包”。

## 2. 从 Opening 字段衍生 query

### 2.1 衍生顺序

```text
origin_context.raw_input
  -> inquiry_shape.research_object + operation_type
  -> scope_boundary + output_contract
  -> derived.research_goal + derived.boundary
  -> derived.search_plan.questions/source_surfaces/stop_when
  -> search plan
  -> query pack
```

不要从用户原话直接写 query。先确定研究对象、动作类型、边界、产物用途，再决定首轮要验证什么。

### 2.2 query pack 的基本配方

每个 query 都由五类成分选择性组合：

```text
对象/别名 + 问题维度 + 证据类型 + 来源/过滤条件 + 时间/地域/反向条件
```

| 成分 | 例子 | 说明 |
|---|---|---|
| 对象/别名 | `OpenAI web_search`, `Exa Search API`, `GPT Researcher` | 先列规范名、旧名、社区常用名。 |
| 问题维度 | `query generation`, `domain filters`, `search context size`, `multi-step research` | 来自 `must_cover`，一条 query 只承载一个主维度。 |
| 证据类型 | `official docs`, `API reference`, `source code`, `GitHub issues`, `best practices` | 用来逼近 source surface。 |
| 来源/过滤 | `site:docs.exa.ai`、`includeDomains`、`category=research paper` | 能用结构化 filter 就不要全塞进 query。 |
| 时间/地域/反向 | `2026`, `latest`, `limitations`, `failure`, `not working` | 用于时效和反例，不要默认只搜正向表述。 |

### 2.3 不同搜索工具的 query 风格

| 场景 | query 写法 | 原因 |
|---|---|---|
| Exa / semantic search | 可以写较长自然语言，带目标和来源偏好；domain/date/category 用参数控制。 | Exa 官方 best practices 支持自然语言和语义丰富 query；结果面向 LLM consumption。 |
| Google / Bing / 站内搜索 | 短关键词 + 关键短语 + `site:` / 引号 / 时间词。 | 人类搜索引擎仍强依赖词面匹配、短语、站点约束和结果页判断。 |
| GitHub search | repo/name/language/path/issue 词面约束优先。 | 搜源码和 issue 时，字段化限制比长自然语言更稳定。 |
| arXiv / 专门库 | 2-3 个核心关键词 + category/date filter。 | 本地 DeerFlow SLR skill 明确要求不要把完整用户问题塞进 arXiv query。 |
| 社区搜索 | 症状词、失败词、口语词、产品旧名并用。 | 社区里的有效证据常不是官方术语。 |

注意：Google `site:` 适合复核某个公开域名或 URL prefix 下是否有相关结果，但 Google Search Central 明确不保证它返回该 prefix 下所有已索引 URL。因此它可以做发现和交叉复核，不适合做完整覆盖率统计。

### 2.4 好 query 的判断标准

| 标准 | 好 query | 坏 query |
|---|---|---|
| 单一维度 | `OpenAI web_search search_context_size citations sources official docs` | `OpenAI web search how does it work and what should my whole workflow do` |
| 来源明确 | `Exa Search API includeDomains contents highlights official docs` | `best AI search API` |
| 可反证 | `Exa search limitations ranking algorithm public docs` | `Exa is better than Google evidence` |
| 不过载 | `GPT Researcher planner execution agents research questions` | `GPT Researcher query generation crawler summary validation citations architecture code` |
| 适配工具 | `diffusion models --category cs.CV` | `recent diffusion model variants in computer vision and NLP and robotics` |

### 2.5 首轮 query pack 模板

```yaml
query_pack:
  anchor_discovery:
    purpose: "先确定术语、官方入口和已有框架。"
    queries:
      - "<object> <dimension> official docs"
      - "<object> <dimension> best practices"
  primary_source:
    purpose: "先读一手来源，避免二手转述带偏。"
    queries:
      - "<object> API reference <specific feature>"
    filters:
      allowed_domains: ["<official-domain>"]
  implementation_examples:
    purpose: "看成熟工具实际怎么拆问题、抓取、压缩和汇总。"
    queries:
      - "<open-source-tool> planner execution agents research questions"
      - "<open-source-tool> retriever scraper context compression"
  counter_or_gap:
    purpose: "检查限制、失败模式和反例。"
    queries:
      - "<object> limitations"
      - "<object> search failure missing sources"
```

## 3. 一轮 search round 的工具路由

### 3.1 默认流程

```text
search plan
  -> discovery: Exa / search API / site search
  -> triage: title + snippet/highlights + metadata
  -> select: evidence tier + novelty + relevance + date + access
  -> fetch/read: Exa contents / Jina / WebFetch / Reader
  -> pivot: gap query / negation query / source-surface switch
  -> browser verify: DOM/read-only JS/locator, screenshot only if necessary
  -> write: queries_and_sources + key_findings + source_notes + state_delta
```

这个流程也有开源参照：GPT Researcher 是 planner 先生成 research questions，再由 execution / crawler agents 收集和总结来源；LangGraph agentic RAG 教程把检索流程拆成 generate query、grade documents、rewrite question、generate answer；Open Deep Research 则把 summarization、research、compression 分成不同角色。这些参照共同说明：成熟方案通常不会把“搜索 API 返回的原始列表”直接交给最终回答，而是先筛选、压缩、再综合。

### 3.2 Discovery：先搜候选，不急着全文读

默认先用 Exa / search API 做候选发现：

- 每个 `must_cover` 先 1 条主 query。
- 每条 query 默认取 5 个结果；概念很散或结果质量差时取 10 个。
- 先要 title、URL、author/date、snippet/highlights/summary；不要默认全量读前 10 个。
- 如果 `source_surfaces.primary` 已指定官网、repo、政府站、论文库，优先用 domain filter 或站内搜索约束。

第一批结果只回答一个问题：哪些 URL 值得读。它不直接回答研究问题。

### 3.3 Triage：从候选里挑全文阅读对象

对候选结果做四个标记：

| 标记 | 说明 |
|---|---|
| `tier` | primary / community / web；primary 优先。 |
| `claim_role` | 支撑规则、解释机制、提供案例、暴露冲突、补背景。 |
| `novelty` | 是否和已有候选重复；同域同内容只保留最强版本。 |
| `read_need` | `snippet_only` / `fetch_partial` / `fetch_full` / `browser_verify`。 |

默认阅读预算：

- 普通首轮：全文读 3-6 个 URL。
- 高风险或强事实判断：全文读 6-10 个 URL，并至少保留 2 个 primary。
- 社区模式判断：不追求单条全文权威，追求重复模式；读 5-10 条短结果可以比深读 1 条更有用。

### 3.4 Fetch / Reader：只读被选中的 URL

读 URL 的工具只处理“已知 URL”，不要拿来发现来源。

| 工具 | 使用条件 | 升级条件 |
|---|---|---|
| Exa contents / crawling | URL 来自 Exa，页面文本型，想直接拿 highlights/text。 | 内容为空、截断、疑似抽错区块时转 Jina / WebFetch / browser。 |
| Jina Reader | 文章、博客、docs、PDF 等正文型网页。 | 页面结构复杂、交互加载、登录态、表格/图片承载关键信息时转 browser。 |
| WebFetch / Web Reader | 需要带 extraction prompt 或格式控制。 | 读取失败、结果和页面预期明显不一致时转 browser。 |
| Browser DOM | 动态页面、站内搜索、页面可见状态、展开/翻页、登录态或 reader 不可信。 | 视觉内容、canvas、视频、图片或 DOM 不可信时才 screenshot。 |

### 3.5 Pivot：什么时候换 query

出现以下情况才补搜，不要机械地“每轮搜很多”：

| 触发 | 动作 |
|---|---|
| 全是二手来源，没有 primary | 加 domain / official / repo / API reference query。 |
| 结果集中在一个说法，没有限制条件 | 加 `limitation`、`failure`、`criticism`、`not working`、`missing` query。 |
| 官方术语和社区术语不一致 | 用社区词再搜一轮，尤其是 issue / forum。 |
| 时间敏感但结果过旧 | 加当前年月、release notes、changelog、latest。 |
| 搜索结果看似相关但读后无用 | 保留失败记录，换关键词或换来源面，不继续读同类结果。 |
| 已经满足 `stop_when` | 停止本轮，写 state delta，不为了完整感继续搜。 |

### 3.6 Browser route lane：最后复核，不做默认批量阅读

Browser lane 的价值不是“更高级搜索”，而是复核真实页面和人类入口：

- in-app browser 默认优先，先 DOM / text / read-only JS / locator。
- 只有 UI 可见性、图片/视频/canvas、DOM 不可信或交互定位困难时才截图。
- Chrome extension 只在需要用户 Chrome 登录态、cookies、profile、extensions、existing tabs 时使用。
- 如果 Exa / Jina 访问不了某 URL，不要立刻判定 URL 无效；先用 browser 打开或站内入口复核一次。

## 4. Exa-first 的具体执行建议

你的“先 Exa，再 fetch，再 browser”方向是合理的，但要加两个限制：

1. Exa-first 只适合 discovery 和初筛，不意味着 Exa 的 answer / summary 就是证据本身。
2. 不要默认读前十个全文；先读摘要/片段，按 evidence role 选少量 URL。

建议执行包：

```yaml
route_packet:
  discovery:
    tool: "Exa search"
    num_results: 5
    contents: "highlights or summary, not full text by default"
  triage:
    select_by:
      - "primary source first"
      - "novelty across domains"
      - "directly answers one must_cover item"
      - "contains limitation/conflict when needed"
  read:
    full_text_if:
      - "primary source"
      - "will support a key conclusion"
      - "snippet is ambiguous"
      - "source contains data/table/rules"
    skip_full_text_if:
      - "duplicate secondary summary"
      - "low authority and no new claim"
      - "outside boundary"
  fallback:
    - "Exa contents fails -> Jina/WebFetch"
    - "reader output suspicious -> browser DOM"
    - "login/dynamic/visual -> in-app browser or Chrome"
```

如果启用类似 Exa deep / research 的综合能力，应把它标为“工具生成的 synthesis”。它可以提出候选来源、补充 query variations 或快速形成初步地图，但关键 claim 仍要回到原始 URL、reader 文本或 browser DOM 证据。

## 5. 与 OpenAI web search 公开设计的对应关系

OpenAI 官方文档公开了三个层级，可作为本 workflow 的设计参照：

| OpenAI 层级 | 官方公开含义 | 对本系统的启发 |
|---|---|---|
| Non-reasoning web search | 模型把用户 query 发给 search tool，基于 top results 回答；快，适合 quick lookup。 | 对应轻量 search round：少量 query、少量候选、快速回源。 |
| Agentic search | reasoning model 主动管理搜索过程，可搜索、分析结果、决定是否继续。 | 对应 search plan + pivot rules：不是固定搜 N 次，而是按 gap 决定是否继续。 |
| Deep research | 面向长时间调查，可能使用大量来源，适合后台模式和高 reasoning。 | 对应多轮 run，不应该塞进单个 search round。 |

官方还公开了几个控制点：

- `search_context_size` 控制搜索结果给模型的上下文量，但不保证精确 token 数、来源数或 citation 数。
- `filters.allowed_domains / blocked_domains` 可以把来源面约束结构化。
- `sources` 可以返回 web search consulted URLs，和 inline citations 不完全相同。
- reasoning models 的 web search action 可能包括 `search`、`open_page`、`find_in_page`。
- `return_token_budget=unlimited` 只适合高强度研究或评测，会增加延迟和成本。

不能据此声称 OpenAI 公开了完整内部 ranking、query expansion 或页面选择算法。公开资料只足够说明：它把搜索分成 quick lookup、agentic search、deep research，并提供上下文量、domain、sources、live access 等可控参数。

## 6. 对当前模板的落地建议

### 6.1 Opening note 不新增重字段

`../10-opening/opening-note-template-v2-review.md` 当前的 `derived.search_plan` 可以保持不变：

- `questions`：自然语言首轮问题。
- `source_surfaces`：primary / community / web 的来源面计划。
- `stop_when`：停止条件。

不要把 query、tool、reader、browser locator 写回 Opening。否则 Opening 会变成执行日志。

### 6.2 Search round 增加执行约束区

如果后续要改模板，建议只在 `search-round` 侧加一个轻量区块：

```yaml
search_plan:
  round_goal: ""
  must_cover: []
  must_not_cover: []
  source_priority: []
  evidence_target: []
  read_budget:
    discovery_results_per_query: 5
    full_read_urls: "3-6"
    browser_verifications: "0-3"
  pivot_rules: []
```

然后现有 `queries_and_sources`、`key_findings`、`source_notes`、`search_round_summary.state_delta` 继续记录实际执行和结果。不要新增一套和 search-round 重复的 judgment 字段。

## 7. 一轮搜索的停止口径

本系统不追求“把网页都读完”，而是追求“本轮状态变化够不够”。

可以停止的条件：

- primary 来源已经确认本轮关键规则、参数、机制或事实。
- community 来源已经出现稳定重复的问题模式，或明确没有足够样本。
- web 来源只剩重复转述，没有新增 claim。
- 已暴露关键冲突，足以把下一轮改成冲突核查。
- 已经命中 Opening 的 `stop_when`，并能写出 `state_delta`。

需要继续的条件：

- 结论只来自工具 summary，没有回源 URL。
- 关键 claim 只有二手来源，没有 primary 或原始材料。
- 搜索结果都支持一个方向，但没有做 negation / limitation pivot。
- reader 抽取结果和页面真实结构可能不一致。
- 还不能说明下一轮应该继续、转向、停止还是写 memo。

## 8. 资料来源

| 来源 | 用途 | URL |
|---|---|---|
| OpenAI Web Search docs | web search 三层模式、actions、citations、search_context_size、domain filters、sources、return_token_budget、limitations | `https://developers.openai.com/api/docs/guides/tools-web-search` |
| OpenAI Using tools docs | Responses API 工具调用、built-in tools、tool_choice、Agents SDK 工具语义 | `https://developers.openai.com/api/docs/guides/tools` |
| Exa Search API reference | Search endpoint、参数、contents、filters、result fields | `https://exa.ai/docs/reference/search` |
| Exa Search Best Practices | 自然语言 query、search types、highlights/text、freshness、schema、systemPrompt | `https://exa.ai/docs/reference/search-best-practices` |
| Exa Research | 多步 research：planning、semantic queries、结果扩展、reasoning & synthesis | `https://exa.ai/docs/reference/exa-research` |
| Google Search Central: How Search works | Google crawling / indexing / serving 三阶段 | `https://developers.google.com/search/docs/fundamentals/how-search-works` |
| Google: Ranking results | Google 公开 ranking signals：meaning、relevance、quality、usability、context/settings | `https://www.google.com/search/howsearchworks/how-search-works/ranking-results/` |
| Google Search Central: `site:` operator | `site:` 只能做域名 / URL prefix 相关发现，不保证完整覆盖 | `https://developers.google.com/search/docs/monitor-debug/search-operators/all-search-site` |
| Jina Reader | URL 转 LLM-friendly Markdown，适合 reader/fetch lane | `https://jina.ai/reader/` |
| LangGraph agentic RAG | generate query、grade documents、rewrite question、answer 的 agentic RAG 参照 | `https://docs.langchain.com/oss/python/langgraph/agentic-rag` |
| Open Deep Research README | Summarization / Research / Compression 角色拆分，多 search tools 与 MCP | `https://github.com/langchain-ai/open_deep_research` |
| GPT Researcher local docs/code | planner 生成 research questions、execution agents 搜索、scrape、summary、source tracking、context compression | `.tmp-gpt-researcher/` |
| DeerFlow local docs/skills/code | deep-research skill 的 broad-to-narrow、web_fetch 全文读取、sub-agent 汇总；Exa/Jina tools 的 search/fetch 分离 | `.tmp-deer-flow/` |
| Agent Reach local skill | 本机 Exa / Jina / web reader / platform route 入口 | `C:\Users\cwt\.codex\skills\agent-reach\SKILL.md` |
| web-access local skill | 搜索、fetch、Jina、browser CDP 的选择边界 | `C:\Users\cwt\.codex\skills\web-access\SKILL.md` |

## 9. 待讨论点

- search round 的执行版 `search_plan` 是否只作为运行时临时对象，还是写入 `search-round-N.md` 的开头，便于用户审阅。
- 普通 round 的默认预算是否用固定值：`2-4` 条 discovery query、每条 `5` 个候选、全文读 `3-6` 个 URL、browser 复核 `0-3` 个入口。
- route adapter 是否需要显式输出 query pack，供用户在 round 前确认；还是只在 round 后记录实际 query。
- 对社区搜索是否需要单独预算，因为 community 的价值常在重复模式，而不是单条权威来源。
