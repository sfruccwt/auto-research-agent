# 网络搜索步骤怎么做

状态：知识整理稿
关联文件：`../20-search-round/search-plan-and-route-design-review.md`、`ai-search-tooling-knowledge-review.md`
核对时间：2026-06-19

[Time-Check]: Data grounded in local AgentReach skill files, local GPT Researcher / DeerFlow source review, and OpenAI official web search docs checked on June 19, 2026.

## 0. 这份文档回答什么

这份文档只记录“网络搜索 / web search 这个步骤本身怎么做”，不讨论整个自动研究系统如何编排。

这里的“网络搜索步骤”指：

```text
输入一个问题 / search plan
  -> 生成或接收 query
  -> 选择搜索路由 / 搜索服务
  -> 拿候选结果
  -> 选择要打开的 URL
  -> fetch / scrape 正文
  -> 把结果压成可引用、可继续处理的 search context
```

不在本文讨论：

- 整个 research workflow 要不要用 LangGraph。
- 本项目最终应该怎样画总图。
- Round Review Gate、memo、output、child run 这些外层研究流程。
- “什么时候升级为 agent node”的项目落地建议。

## 1. AgentReach 当前路由是什么

AgentReach 在本机不是一个单一搜索引擎，而是一个“路由器”：先按用户意图选 channel，再调用对应平台工具。

本机入口：`C:\Users\cwt\.codex\skills\agent-reach\SKILL.md`

### 1.1 顶层路由表

| 用户意图 | AgentReach 分类 | 主要工具 / 命令 | 适合什么 |
|---|---|---|---|
| 网页搜索 / 代码搜索 | `search` | `mcporter call 'exa.web_search_exa(...)'`、`exa.get_code_context_exa(...)` | 英文技术资料、代码上下文、通用网页发现 |
| 网页 / 文章 / 公众号 / RSS 阅读 | `web` | `curl https://r.jina.ai/URL`、`web-reader.webReader(...)`、Exa 微信文章搜索/抓取、`feedparser` | 已知 URL 正文读取、公众号、RSS |
| GitHub / 代码 / issue / repo | `dev` | `gh search repos`、`gh search code`、`gh issue view/list`、`gh repo view` | 开源实现、源码、issue、PR、release |
| 社交 / 社区 | `social` | `xhs`、`twitter`、`rdt`、V2EX API、微博 Jina、B 站 `yt-dlp` | Reddit / V2EX / X / 小红书 / B 站等社区材料 |
| 招聘 / LinkedIn | `career` | LinkedIn 相关工具 | 职位、招聘、组织信息 |
| YouTube / B 站 / 播客字幕 | `video` | `yt-dlp --write-sub --skip-download` | 视频元数据、字幕、播客转录 |

### 1.2 search route：发现候选来源

`references/search.md` 里只定义了两个核心能力：

| 能力 | 命令形态 | 输出性质 |
|---|---|---|
| 网页搜索 | `mcporter call 'exa.web_search_exa(query: "query", numResults: 5)'` | 候选网页结果 |
| 代码上下文搜索 | `mcporter call 'exa.get_code_context_exa(query: "code question", tokensNum: 3000)'` | 面向代码问题的上下文 |

这个 route 的角色是 discovery：先找“可能该读哪些来源”，不是直接替代事实核查。

### 1.3 web route：读取已知 URL

`references/web.md` 把 web route 分成正文读取和特殊站点读取：

| 场景 | 工具 | 说明 |
|---|---|---|
| 普通网页 / 文章 / 文档 | Jina Reader：`curl -s "https://r.jina.ai/URL"` | 把 URL 转成 Markdown / text |
| 需要格式控制 | `web-reader.webReader(url: "...")` | 可选保留图片、纯文本等 |
| 微信公众号搜索 | Exa 搜索 `includeDomains: ["mp.weixin.qq.com"]` | Jina 对微信文章不可靠，推荐 Exa |
| 微信公众号全文 | `exa.crawling_exa(urls: [...], maxCharacters: 10000)` | 用 Exa 抓正文 |
| RSS | `feedparser` | 订阅源读取 |

这个 route 的角色是 fetch/read：通常输入应是已知 URL，而不是开放式发现。

### 1.4 dev route：代码与 GitHub 来源

`references/dev.md` 以 GitHub CLI 为主：

| 场景 | 命令 |
|---|---|
| 搜仓库 | `gh search repos "query" --sort stars --limit 10` |
| 搜代码 | `gh search code "query" --language python` |
| 看仓库 | `gh repo view owner/repo` |
| 看 issue / PR | `gh issue list/view`、`gh pr list/view` |
| 走 GitHub API | `gh api ...` |

这个 route 对“别人怎么实现 web search step”特别有用，因为它可以直接看 repo、源码和 issue。

### 1.5 social route：社区搜索与读取

`references/social.md` 的特点是每个平台有自己的入口和限制：

| 平台 | 搜索 / 读取方式 | 注意点 |
|---|---|---|
| 小红书 | `xhs search` -> `xhs read` -> `xhs comments` | 不能裸 note id；必须用搜索结果 URL / ID；高频会触发验证码 |
| Twitter/X | `twitter search`、`twitter tweet`、`twitter user-posts` | search 可能随 X GraphQL 变动失效；cookie / token 相关 |
| Reddit | `rdt search` -> `rdt read POST_ID` | 适合读帖子和评论 |
| V2EX | 公开 API：hot、node topics、topic detail、replies | 无需认证 |
| 微博 | Jina Reader 读取 URL | 主要通过网页抓取 |
| B 站 | `yt-dlp --dump-json`、字幕下载 | 可能遇到 412，需要 cookies / 代理 |

这个 route 的角色不是“权威事实证明”，而是找到社区经验、失败模式、重复问题模式。

## 2. AgentReach 对一个问题的网络搜索怎么做

按本机 skill 的路由设计，一个问题进入 AgentReach 后，合理动作链是：

```text
用户问题
  -> 判断意图和来源面
  -> 选择 route: search / web / dev / social / video / career
  -> discovery: 搜候选结果
  -> read: 打开候选 URL 或平台对象
  -> normalize: 输出 title / author / date / URL / snippet / content / comments
  -> compress: 给母上下文返回结构化摘要
```

### 2.1 route 选择不是单选

一个研究型问题通常会同时走多条 route：

| 来源面 | AgentReach route | 例子 |
|---|---|---|
| 官方文档 / 技术博客 | `search` + `web` | Exa 搜 URL，Jina / web-reader 读正文 |
| 开源实现 | `dev` | `gh search repos/code/issues` |
| 社区经验 | `social` | Reddit / V2EX / X / HN 等 |
| 视频教程 / 演示 | `video` | `yt-dlp` 抓字幕 |

所以 AgentReach 的“网络搜索步骤”不是一次 search call，而是一个 route adapter：

```text
source surface -> route -> platform command -> normalized result
```

### 2.2 discovery 和 read 分离

AgentReach 文档里已经隐含了两类动作：

| 动作 | 典型 route | 输入 | 输出 |
|---|---|---|---|
| discovery | `search`、`dev`、`social` 平台搜索 | query / 关键词 / 平台入口 | 候选 URL / repo / post / video |
| read / fetch | `web`、`social read`、`yt-dlp subtitles` | 已知 URL / post id / video URL | 正文、评论、字幕、元数据 |

这个分离很重要：发现候选来源和读取来源内容不是同一件事。

### 2.3 AgentReach 输出需要再压缩

AgentReach 原始工具可能返回搜索列表、网页正文、repo 信息、帖子评论或字幕。对研究系统来说，应该压缩成统一结构，例如：

| 字段 | 含义 |
|---|---|
| `query_or_entry` | 本次搜索 query 或平台入口 |
| `route` | `agent-reach:search` / `agent-reach:web` / `agent-reach:dev` / `agent-reach:social` |
| `title` | 来源标题 |
| `author_or_org` | 作者、组织或账号 |
| `date` | 发布 / 更新日期；没有就标 `unknown` |
| `url` | 原始 URL |
| `source_tier` | primary / implementation / community / web |
| `key_observation` | 1-3 句事实摘录或模式 |
| `read_status` | snippet only / fetched / browser verified / failed |
| `source_notes` | 工具失败、登录态、反爬、fallback 等 |

这一步不是 AgentReach 自带的单个命令，而是调用方需要加的压缩层。

## 3. GPT Researcher 的 web search step

本地源码：`.tmp-gpt-researcher/`

GPT Researcher 的网络搜索步骤比较清楚：它把 query planning、retriever、URL scrape、context retrieval 分开。

### 3.1 关键配置

文档 `docs/docs/gpt-researcher/gptr/config.md` 记录了这些默认值：

| 配置 | 默认值 / 说明 |
|---|---|
| `RETRIEVER` | 默认 `tavily`；可选 `duckduckgo`、`bing`、`google`、`searchapi`、`serper`、`searx` 等 |
| `MAX_SEARCH_RESULTS_PER_QUERY` | 每个 query 最大搜索结果数，默认 `5` |
| `MAX_ITERATIONS` | query expansion / search refinement 最大迭代数，默认 `3` |
| `BROWSE_CHUNK_MAX_LENGTH` | 浏览网页 chunk 最大长度，默认 `8192` |
| `SCRAPER` | 默认 `bs`，也可用 `newspaper`、`browser`、`tavily_extract`、`firecrawl` 等 |
| `MAX_SCRAPER_WORKERS` | 每次 research 最大并发 scraper worker，默认 `15` |
| `CURATE_SOURCES` | 是否额外用 LLM 筛来源，默认 `False` |

### 3.2 搜索步骤链条

代码入口主要在：

- `.tmp-gpt-researcher/gpt_researcher/skills/researcher.py`
- `.tmp-gpt-researcher/gpt_researcher/actions/query_processing.py`
- `.tmp-gpt-researcher/gpt_researcher/actions/retriever.py`
- `.tmp-gpt-researcher/gpt_researcher/actions/web_scraping.py`
- `.tmp-gpt-researcher/gpt_researcher/scraper/scraper.py`

它的链条是：

```text
原始 query
  -> plan_research(): 先用第一个 retriever 搜一批初始结果
  -> plan_research_outline(): LLM 根据初始结果生成 sub_queries
  -> _get_context_by_web_search(): 把 sub_queries 加上原始 query
  -> asyncio.gather(): 并行处理每个 sub_query
  -> _search_relevant_source_urls(): 每个 retriever 搜候选 URL
  -> _scrape_data_by_urls(): scrape 需要打开的 URL
  -> vector_store.load(): 可选写入向量库
  -> context_manager.get_similar_content_by_query(): 按 query 取相关内容
  -> combined context
```

### 3.3 retriever 做什么

`actions/retriever.py` 是 retriever factory。支持的 provider 包括：

```text
google, searx, searchapi, serpapi, serper, duckduckgo, bing,
bocha, arxiv, tavily, exa, semantic_scholar, pubmed_central,
custom, mcp, xquik, openalex
```

每个 retriever 负责把 query 转成候选结果，常见输出字段是：

```json
{
  "href": "https://...",
  "body": "snippet or extracted text"
}
```

两个例子：

| retriever | 行为 |
|---|---|
| Tavily | 调 `https://api.tavily.com/search`，参数包括 `query`、`search_depth`、`max_results`、`include_domains`、`include_raw_content` 等；当前 search 方法返回 `href=url` 和 `body=content` |
| Exa | 调 `client.search(query, type=..., num_results=..., include_domains=...)`；返回 `href=result.url` 和 `body=result.text` |

### 3.4 snippet 和 full content 的分界

GPT Researcher 在 `_search_relevant_source_urls()` 里做了一个关键判断：

- 如果结果里有 `raw_content` 且长度大于 100，就认为 retriever 已经给了完整内容，放进 `prefetched_content`。
- 如果只有 URL 或 `body` 这类 snippet，就把 URL 加到 `new_search_urls`，后面继续 scrape。

这说明它不会默认把搜索结果 snippet 当作正文证据。搜索结果只是候选；正文要走 scraper。

### 3.5 scrape / browse 做什么

`BrowserManager.browse_urls()` 调 `scrape_urls()`，后者实例化 `Scraper`。

`Scraper` 的行为：

- 先对 URL 去重。
- 用 `WorkerPool` 并发抓取。
- 根据 URL 和配置选择 scraper：
  - `.pdf` -> `PyMuPDFScraper`
  - `arxiv.org` -> `ArxivScraper`
  - 其他按 `SCRAPER` 配置：`bs` / `browser` / `nodriver` / `tavily_extract` / `firecrawl` / `web_base_loader`
- 抓到内容后，如果正文长度小于 100，就标为无效。
- 返回结构包括 `url`、`raw_content`、`image_urls`、`title`。

### 3.6 GPT Researcher 这个 search step 的事实层总结

GPT Researcher 的 web search step 不是“一个 agent 自由搜索”，而是：

```text
query -> sub_queries -> retrievers -> URL list / prefetched content
      -> scrape unique URLs -> filter empty content
      -> optional vector store -> similar-content context
```

它的几个可观察设计点：

- 搜索 provider 是可替换 adapter。
- 每个 query 有结果数上限。
- query expansion 有迭代上限。
- URL 去重和 visited URL 记录是内置动作。
- snippet-only 结果要继续 scrape。
- scrape 是并发 worker 池。
- 最终交给下游的不是原始 SERP，而是压缩后的 context。

## 4. DeerFlow 的 web search step

本地源码：`.tmp-deer-flow/`

DeerFlow 的网络搜索更像“工具注册表 + agent 调工具”。它把 `web_search` 和 `web_fetch` 明确拆成两个 tool。

### 4.1 工具配置

`config.example.yaml` 的 web 工具区记录了：

| 工具名 | 默认 / 可选 provider | 作用 |
|---|---|---|
| `web_search` | 默认 DuckDuckGo；可选 Serper、Tavily、InfoQuest、Exa、Firecrawl | 搜索候选结果 |
| `web_fetch` | 默认 Jina AI Reader；可选 Exa、InfoQuest | 读取已知 URL 正文 |
| `image_search` | DuckDuckGo | 图片搜索 |

默认配置片段：

```yaml
tools:
  - name: web_search
    group: web
    use: deerflow.community.ddg_search.tools:web_search_tool
    max_results: 5

  - name: web_fetch
    group: web
    use: deerflow.community.jina_ai.tools:web_fetch_tool
    timeout: 10
```

### 4.2 DuckDuckGo web_search

文件：`.tmp-deer-flow/backend/packages/harness/deerflow/community/ddg_search/tools.py`

行为：

- 输入：`query`、`max_results=5`。
- 内部用 `ddgs.DDGS().text()`。
- 可配置 `region`、`safesearch`。
- 输出 JSON：

```json
{
  "query": "...",
  "total_results": 5,
  "results": [
    {
      "title": "...",
      "url": "...",
      "content": "..."
    }
  ]
}
```

### 4.3 Tavily web_search / web_fetch

文件：`.tmp-deer-flow/backend/packages/harness/deerflow/community/tavily/tools.py`

`web_search`：

- 输入：`query`。
- 从配置读 `max_results`，默认 5。
- 调 `client.search(query, max_results=max_results)`。
- 输出规范化数组：`title`、`url`、`snippet`。

`web_fetch`：

- 输入：精确 URL。
- 调 `client.extract([url])`。
- 如果成功，返回 `# title` + `raw_content[:4096]`。
- 如果失败，返回错误。

### 4.4 Exa web_search / web_fetch

文件：`.tmp-deer-flow/backend/packages/harness/deerflow/community/exa/tools.py`

`web_search`：

- 输入：`query`。
- 配置项：
  - `max_results` 默认 5。
  - `search_type` 默认 `auto`，可选 `auto`、`neural`、`keyword`。
  - `contents_max_characters` 默认 1000。
- 调 Exa `client.search()`。
- 请求 `contents={"highlights": {"max_characters": contents_max_characters}}`。
- 输出规范化数组：`title`、`url`、`snippet`，其中 snippet 来自 highlights。

`web_fetch`：

- 输入：精确 URL。
- 调 Exa `get_contents([url], text={"max_characters": 4096})`。
- 返回标题和正文前 4096 字符。

### 4.5 Jina web_fetch

文件：`.tmp-deer-flow/backend/packages/harness/deerflow/community/jina_ai/tools.py`

行为：

- 只提供 `web_fetch`，不做开放搜索。
- 输入：精确 URL。
- 调 Jina client 抓 HTML。
- 用 `ReadabilityExtractor` 抽正文。
- 返回 Markdown，截断到 4096 字符。

### 4.6 DeerFlow 这个 search step 的事实层总结

DeerFlow 明确把搜索拆成两个工具：

```text
web_search(query) -> [{title, url, snippet/content}]
web_fetch(url) -> markdown/raw_content
```

几个可观察设计点：

- `web_search` 默认只返回 5 条候选。
- `web_fetch` 明确要求 URL 必须是用户提供或 search/fetch 结果返回的 exact URL。
- `web_fetch` 明确不处理登录墙内容。
- 不同 provider 只要规范化成相似输出，就可以替换。
- 搜索结果 snippet 与 fetch 正文分开，正文通常截断到 4096 字符。

## 5. OpenAI Responses API web_search step

来源：OpenAI official docs `https://developers.openai.com/api/docs/guides/tools-web-search`

OpenAI 的 hosted `web_search` 是内置 tool，不暴露完整搜索引擎实现，但公开了可控参数和输出结构。

### 5.1 三种搜索形态

| 形态 | 搜索方式 | 适合 |
|---|---|---|
| non-reasoning web search | 模型把用户 query 发给 search tool，基于 top results 回答；没有内部 planning | quick lookup |
| agentic search | reasoning model 主动管理搜索过程，可以搜索、分析结果、决定是否继续搜 | 复杂 workflow 中的多步搜索 |
| deep research | reasoning model 做长时间调查，可查大量来源，适合 background mode | 长报告 / 深研究 |

### 5.2 输出结构

如果用了 web search，response 里会有：

| 输出 | 含义 |
|---|---|
| `web_search_call` | 搜索工具调用记录 |
| `web_search_call.action` | 可能是 `search`、`open_page`、`find_in_page` |
| `message.content[].annotations` | inline citations；包含 URL、title、位置 |
| `sources` | 可选返回模型实际 consulted URLs；数量可能多于 citations |

这说明 OpenAI 把 search step 的动作分成：

```text
search query
  -> open page
  -> find in page
  -> answer with citations
  -> optional full consulted source list
```

### 5.3 可控参数

| 参数 | 作用 |
|---|---|
| `search_context_size` | 控制搜索结果给模型的上下文量：`low` / `medium` / `high`；不保证精确 token 数或来源数 |
| `filters.allowed_domains` / `blocked_domains` | 限定或排除域名；最多 100 个 allowed 或 blocked domains |
| `return_token_budget` | GPT-5+ reasoning web search 的返回 token 预算；`unlimited` 适合高强度研究但增加成本和延迟 |
| `external_web_access` | 控制 live web access；可设为 false 使用 cache-only |
| `tool_choice` | `auto` 时搜索可选；需要强制搜索时用 required 或指定 tool |
| `include: ["web_search_call.action.sources"]` | 返回 consulted source list |
| `search_content_types` | 可同时请求 image / text search |
| `user_location` | 按近似地理位置调整结果 |

### 5.4 OpenAI 这个 search step 的事实层总结

OpenAI hosted web search 暴露的不是“URL 列表 + 手动 fetch”模式，而是 tool-level 搜索动作：

```text
model decides / is required to call web_search
  -> search action
  -> optional open_page / find_in_page
  -> model answer
  -> citations + optional sources
```

但它仍然有几个和 GPT Researcher / DeerFlow 相同的抽象：

- 搜索上下文预算。
- domain allow/block。
- consulted sources 和 inline citations 分离。
- quick lookup / agentic search / deep research 分层。
- live access 与 cached access 可控。

## 6. 横向对比：这些 web search step 都在做什么

| 系统 | search 输入 | discovery 输出 | fetch/read 是否分离 | 预算 / 限制 | 最终给下游什么 |
|---|---|---|---|---|---|
| AgentReach | 用户问题转 route + query | URL / repo / post / video / RSS entry | 是；`search` 和 `web` route 分离，平台也有 read 命令 | route 级工具参数，如 `numResults: 5`、平台 limit | 需要调用方压缩成结构化结果 |
| GPT Researcher | 原始 query -> LLM sub_queries | retriever results：`href` + snippet/body | 是；snippet-only URL 继续 scraper | `MAX_SEARCH_RESULTS_PER_QUERY=5`、`MAX_ITERATIONS=3`、`MAX_SCRAPER_WORKERS=15` | combined context |
| DeerFlow | agent 调 `web_search(query)` | JSON results：title/url/snippet | 是；`web_fetch(url)` 单独读取正文 | 默认 `max_results=5`、fetch 截断 4096 | tool output JSON / markdown |
| OpenAI web_search | prompt + hosted tool config | 不直接暴露完整 SERP；暴露 web_search_call 和 sources | 部分内置；reasoning models 可 `open_page` / `find_in_page` | `search_context_size`、domain filters、`return_token_budget`、live/cache | answer + citations + optional sources |

共同事实：

1. 搜索步骤通常不是“直接回答”，而是先 discovery。
2. 搜索结果 snippet 和正文读取要区分。
3. 成熟实现都有结果数、迭代数、上下文量或 token budget。
4. provider adapter 很常见：Tavily / Exa / DuckDuckGo / Serper / Searx / Jina / Firecrawl 可替换。
5. URL 去重、失败记录、正文长度过滤、来源 metadata 是搜索步骤的一部分。
6. 最终交给后续节点的应是压缩 context / citations / source list，而不是原始工具输出。

## 7. 资料与本地证据

| 来源 | 用途 | 位置 / URL |
|---|---|---|
| AgentReach router | 顶层 route 表、快速命令、工作区规则 | `C:\Users\cwt\.codex\skills\agent-reach\SKILL.md` |
| AgentReach search reference | Exa web search / code context route | `C:\Users\cwt\.codex\skills\agent-reach\references\search.md` |
| AgentReach web reference | Jina Reader、web-reader、微信、RSS route | `C:\Users\cwt\.codex\skills\agent-reach\references\web.md` |
| AgentReach dev reference | GitHub CLI route | `C:\Users\cwt\.codex\skills\agent-reach\references\dev.md` |
| AgentReach social reference | 小红书、Twitter、Reddit、V2EX、B 站等 route | `C:\Users\cwt\.codex\skills\agent-reach\references\social.md` |
| GPT Researcher config | retriever、结果数、迭代数、scraper 并发等配置 | `.tmp-gpt-researcher/docs/docs/gpt-researcher/gptr/config.md` |
| GPT Researcher query processing | 初始搜索、sub-query generation | `.tmp-gpt-researcher/gpt_researcher/actions/query_processing.py` |
| GPT Researcher retriever factory | provider adapter 列表 | `.tmp-gpt-researcher/gpt_researcher/actions/retriever.py` |
| GPT Researcher research conductor | `_get_context_by_web_search`、sub-query 并发、URL 搜索 / scrape | `.tmp-gpt-researcher/gpt_researcher/skills/researcher.py` |
| GPT Researcher scraper | URL 去重、scraper 选择、正文长度过滤 | `.tmp-gpt-researcher/gpt_researcher/scraper/scraper.py` |
| DeerFlow config | `web_search` / `web_fetch` 工具注册 | `.tmp-deer-flow/config.example.yaml` |
| DeerFlow DuckDuckGo tool | 默认 `web_search` 实现 | `.tmp-deer-flow/backend/packages/harness/deerflow/community/ddg_search/tools.py` |
| DeerFlow Tavily tool | Tavily search / extract | `.tmp-deer-flow/backend/packages/harness/deerflow/community/tavily/tools.py` |
| DeerFlow Exa tool | Exa search highlights / contents fetch | `.tmp-deer-flow/backend/packages/harness/deerflow/community/exa/tools.py` |
| DeerFlow Jina tool | URL fetch + readability extraction | `.tmp-deer-flow/backend/packages/harness/deerflow/community/jina_ai/tools.py` |
| OpenAI web search docs | hosted web_search actions、citations、sources、controls | `https://developers.openai.com/api/docs/guides/tools-web-search` |
