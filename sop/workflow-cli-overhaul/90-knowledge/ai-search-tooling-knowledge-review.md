# AI 检索工具知识

状态：讨论稿
关联文件：`../10-opening/opening-note-template-v2-review.md`、`../10-opening/opening-brief-template-v2-review.md`、`../00-overview/workflow-cli-target-flow.md` 的 Search round node
核对时间：2026-06-18

## 0. 这份文档回答什么

这份文档先记录 AI 检索工具的基本知识，用来支撑后续讨论 `derived.search_plan` 应该写到什么粒度。

当前结论：

- Exa / 搜索类工具承担“搜索引擎”角色：给它 `query`，它从自己的 index / 搜索系统里返回一组结果，并可顺带抽取 `text`、`highlights`、`summary` 或生成带 citations 的综合输出。
- Jina / WebFetch / Reader 更接近“打开并读取一个 URL”：通常不是拿来发现来源，而是在已经有 URL 后把页面正文、片段、PDF 或结构化内容读出来。
- Browser route lane 更接近“人类浏览器复核”：它不是搜索 API，而是用 URL、搜索入口、DOM、locator、read-only JS 或 screenshot 条件去验证真实页面、动态渲染、登录态、站内搜索和可见性。
- Opening 阶段仍应保留自然语言 `questions`、`source_surfaces`、`stop_when`。具体 query、URL、reader 选择、browser entrypoint 应下沉到 Search Round 的 route adapter。

## 1. 基础模型：发现来源和读取来源是两件事

| 动作 | 典型工具 | 输入 | 输出 | 在 Search Round 中的角色 |
|---|---|---|---|---|
| 发现来源 | Exa、Google、Bing、GitHub search、平台搜索 | query / 搜索目标 / 过滤条件 | 排序后的候选 URL 列表，通常带标题、摘要、日期、作者等 metadata | 找“该读哪些来源” |
| 读取来源 | Jina、WebFetch、Reader、Exa Contents、browser DOM | URL | 页面正文、片段、图片/结构信息、可见状态 | 判断“这个来源到底说了什么” |
| 综合回答 | Exa Answer、Exa deep search、LLM synthesis | query + 检索结果 + schema / prompt | answer / summary / structured output + citations | 可作为辅助，但证据仍要回到原始 URL |
| 真实页面复核 | in-app browser / Chrome extension | URL / 搜索页面 / locator / DOM / screenshot 条件 | 页面真实渲染、交互状态、登录态可见内容 | 复核机器读取和搜索 API 是否漏掉动态或登录态信息 |

所以，AI research workflow 里不应只问“我要传自然语言还是 query”。更准确的拆法是：

```text
自然语言研究问题
  -> search intent
  -> source surface
  -> discovery query / known URL / platform target
  -> reader or browser verification
  -> compressed findings + route log
```

## 2. Exa 是什么：AI / agent 用的搜索 API

Exa 官方文档把 Search API 描述为：给自然语言 search query，返回网页及其内容，结果面向 LLM consumption 优化。它不是浏览器结果页产品，而是 API：调用方拿到 `results`，可请求 `highlights`、`text`、`summary`，也可用 `outputSchema` 让 Exa 返回结构化 synthesized output。

Exa Search endpoint 的公开输入包括：

| 参数 | 含义 |
|---|---|
| `query` | 必填 search query。Exa best practices 明确支持较长、语义丰富的描述。 |
| `numResults` | 返回结果数量，默认 10，公开范围 1-100。 |
| `includeDomains` / `excludeDomains` | 限定或排除域名。相当于把浏览器搜索里的 `site:` 和排除条件变成结构化参数。 |
| `startPublishedDate` / `endPublishedDate` | 按页面发布日期限制。 |
| `startCrawlDate` / `endCrawlDate` | 按 Exa 发现 / crawl 到链接的时间限制。 |
| `contents` | 控制是否返回 `text`、`highlights`、`summary` 等内容。 |
| `type` | `auto`、`fast`、`instant`、`deep-lite`、`deep`、`deep-reasoning`。越往 deep 越像多步搜索 + synthesis。 |
| `category` | 面向 `company`、`research paper`、`news`、`personal site`、`financial report`、`people` 等内容类型的垂直搜索。 |
| `systemPrompt` | 指导 synthesized output 或 deep-search planning，例如偏好官方来源、避免重复。 |
| `outputSchema` | 控制 `output.content` 的结构化格式；Exa 同时返回 built-in grounding / citations。 |
| `maxAgeHours` | 控制使用 cache 还是 livecrawl：如 24 小时内用缓存，否则 fresh crawl；0 表示总是 livecrawl；-1 表示只用 cache。 |

Exa 还提供 `/answer` endpoint：它会先做 Exa search，再用 LLM 生成直接答案或开放问题的详细摘要，并返回 sources / citations。也就是说，Exa 既有“返回结果列表”的 search 层，也有“基于搜索结果生成答案”的 answer / deep synthesis 层。

## 3. Exa 的检索逻辑能确认到什么

能确认的公开事实：

- Exa 有自己的 index。官方 `The Exa Index` 页面说它维护 high quality, curated index，并列出研究论文、个人页面、Wikipedia、新闻、LinkedIn people/company、公司主页、财报、GitHub repos、blogs、法律/政策、政府/国际组织等覆盖面。
- Exa Search API 返回的是排序结果列表，每条结果有 title、URL、published date、author 等字段；请求内容时可带 text、highlights、summary。
- Exa best practices 说它支持自然语言、语义丰富的 query；结果面向 LLM consumption，强调 token efficient highlights、specialized index coverage、低延迟 search type。
- Exa 的 deep / research 模式会把自然语言 instructions 拆成多步：planning、semantic queries、扩展/细化结果集、reasoning & synthesis。
- Exa 可以控制 freshness：默认会在没有 cache 时 livecrawl；也可要求固定时间窗或强制 livecrawl。

不能确认的部分：

- Exa 没有公开完整 ranking algorithm。
- 文档没有说明每个结果的排序权重，例如 embedding 相似度、链接权重、点击数据、内容质量、时效性、来源权威性各占多少。
- 因此不能写“Exa 一定按某个固定分数排序”。只能写：它会返回排序后的结果列表；从官方材料看，这个排序服务于 semantic / neural search 和 LLM-ready retrieval，但具体内部 ranking 细节不透明。

对 workflow 的含义：

- Exa 适合把自然语言 research intent 转成候选来源，但不要把 Exa 返回的第一批结果当作“事实已证实”。
- `search-round-N.md` 需要记录 Exa query、结果 URL、读取方式和 evidence level。
- 对关键事实，应回源读取原文；对高风险结论，应再用 browser route 或 primary source 复核。

## 4. Google / Bing 这类人类搜索引擎的检索逻辑

Google 官方把 Search 拆成三阶段：

1. Crawling：crawler 发现并下载网页、图片、视频等内容。
2. Indexing：分析页面内容并存入 index。
3. Serving search results：用户搜索时返回与 query 相关的信息。

Google 官方对 ranking 的公开说明是：排序系统会在极短时间内从海量网页中选出相关、有用的结果；信号包括 query words、页面相关性和可用性、source expertise、用户 location 和 settings。它还明确说不同 query 下权重会变化，例如新闻类 query 更看 freshness。

Google 公开提到的关键 ranking signals 包括：

| 信号 | 含义 |
|---|---|
| Meaning | 先理解 query intent，用 language models、拼写纠错、同义词系统处理用户输入。 |
| Relevance | 看页面是否包含相关信息；关键词在 heading / body 中仍是基础信号，但不只看关键词堆叠。 |
| Quality | 识别 expertise、authoritativeness、trustworthiness；其他 prominent websites 的链接或引用是质量信号之一。 |
| Usability | 页面体验、移动端友好、加载等可用性因素在其他信号相近时影响排序。 |
| Context / settings | location、past search history、search settings 等会影响当前用户看到的结果。 |
| Interaction data | Google 说会使用 aggregated and anonymized interaction data 来帮助机器学习系统估计相关性。 |

Bing 的公开 search API 已经退役，Exa 的迁移文档把 Bing 的 `q/count/freshness/site:` 等参数映射到 Exa 的 `query/numResults/startPublishedDate/includeDomains` 等结构化参数。这个迁移文档说明 API 形态上可以替换，但它不等于 Bing 与 Exa 的 ranking 逻辑相同。

## 5. Exa 与 Google / Bing 的关键差异

| 维度 | Exa / AI search API | Google / Bing 人类搜索引擎 |
|---|---|---|
| 主要用户 | LLM、agent、应用程序、RAG / research workflow | 人类用户 |
| 输出形态 | JSON results、text、highlights、summary、structured output、citations / grounding | SERP：标题、链接、snippet、富结果、广告、AI overview、地图/图片/视频等 |
| Query 形态 | 支持较长、语义丰富的自然语言 query；可用 schema / systemPrompt 指导 synthesis | 人类输入短 query 很常见，也支持自然语言和搜索 operators |
| 排序目标 | 面向机器消费的 relevant sources 和可读内容；官方强调 LLM-ready、token efficient、specialized index | 面向人类 first-page satisfaction，强调相关性、质量、可用性、上下文、速度 |
| 内容读取 | Search 同时可以抽取 `text/highlights/summary`；Answer/deep 可直接 synthesis | SERP 主要展示 snippet，用户通常还要点开网页；AI Overview 是另一层 synthesis |
| 时效控制 | 可结构化指定 publish date、crawl date、`maxAgeHours`、livecrawl / cache | 用户可用时间工具和 query；内部 freshness 权重随 query 变化 |
| 个性化 | API 可传 `userLocation`；默认不等同于用户登录浏览器上下文 | location、history、settings、账号状态可能影响结果 |
| 可审计性 | API 返回 structured result、requestId、grounding / citations；便于记录 route log | SERP 易截图/复核，但个性化、地区、时间和 UI 状态会造成差异 |
| 未公开部分 | 完整 ranking algorithm 未公开 | 完整 ranking algorithm 也未公开，只公开信号类别 |

最重要的差异不是“谁有 crawler”。两者都需要 crawler / index / retrieval。但 Exa 把搜索包装成 agent / LLM API，结果可以直接进入上下文；Google / Bing 把搜索包装成人类 SERP，用户会用肉眼判断、点开、换关键词、排除广告或低质量站点。

## 6. Exa 检索后如何获取和总结内容

Exa 有三种层级：

1. Search result list：返回 `results`，每条包括 title、url、publishedDate、author 等 metadata。
2. Contents extraction：在 Search 或 Contents API 中请求 `text`、`highlights`、`summary`。`highlights` 是和 query 相关的关键片段，适合减少 token；`text` 适合需要完整上下文的深读。
3. Synthesis：`outputSchema`、`systemPrompt`、`deep` / `deep-reasoning`、`/answer` endpoint 会让 Exa 在搜索结果基础上生成 output，并返回 grounding / citations。

这说明 Exa 不是简单返回“十个蓝色链接”。它可以把 discovery 和 reading 合在一次 API 调用里。但是，在研究 workflow 中仍应把这三层拆开审计：

| 层 | 可以相信什么 | 需要复核什么 |
|---|---|---|
| result list | 某 URL 被 Exa 认为和 query 相关 | 是否是 primary source；是否被排序误导；是否有遗漏 |
| highlights / text / summary | 页面里有相关内容片段或抽取正文 | 抽取是否完整；summary 是否漏关键限制；页面是否动态/登录态 |
| answer / synthesized output | 多来源综合的初步答案 | citation 是否真的支撑 claim；不同来源是否冲突；是否遗漏反例 |

## 7. Jina / WebFetch / Reader 的位置

你的理解是对的：Jina、WebFetch、Reader 更像“打开 URL 读内容”，不是主搜索引擎。

| 工具类型 | 输入 | 适合 | 不适合 |
|---|---|---|---|
| Jina Reader | URL | 把文章、博客、文档、PDF 转成 Markdown / text，节省 token | 复杂交互页面、登录态页面、强反爬、页面可见性判断 |
| WebFetch / Reader | URL + extraction prompt / format | 从已知页面抽取指定信息 | 发现来源、判断搜索结果排序 |
| Browser DOM / screenshot | URL / tab / locator | 真实渲染、动态内容、站内搜索、展开/翻页、登录态复核 | 大批量低成本正文读取 |

因此，Search Round 里应先由 Exa / 搜索引擎 / 平台搜索发现 URL，再决定用 Jina、WebFetch、Exa Contents 还是 browser 去读。

## 8. 对 search plan 的影响

Opening 阶段不应该写：

```yaml
query: "..."
includeDomains: [...]
reader_preference: jina
browser_locator: "..."
```

Opening 阶段应该写：

```yaml
questions:
  - "第一轮先确认 AI search API 与人类搜索引擎在 discovery、ranking、content extraction 上有什么差异。"
source_surfaces:
  - "primary: Exa / Google / Microsoft 官方文档，确认公开机制和参数。"
  - "web: 必要时用技术博客或论文解释 neural / semantic search，但不能替代官方说法。"
stop_when:
  - "Exa 的输入、输出、content extraction、synthesis 层级已确认。"
  - "Google / Bing 这类人类搜索引擎的 crawling / indexing / ranking 信号已有官方解释。"
  - "仍未公开的 ranking 细节已标为 unknown，不继续猜。"
```

然后 Search Round route adapter 再生成执行输入：

```yaml
execution_packet:
  discovery:
    exa_query: "Exa Search API semantic search highlights summary outputSchema ranking"
    google_query: "Google Search ranking crawling indexing relevance quality usability context"
  readers:
    - url: "https://exa.ai/docs/reference/search"
      read_for: "Search API parameters and result fields"
    - url: "https://www.google.com/search/howsearchworks/how-search-works/ranking-results/"
      read_for: "Google public ranking signals"
  browser_route:
    use_when: "需要确认页面真实可见结构或 docs 动态内容"
```

## 9. 对本 research runner 的设计结论

1. `derived.search_plan.questions` 继续写自然语言问题。
2. `source_surfaces` 不要写工具名，而是写证据面：`primary`、`community`、`web`。
3. route adapter 负责把自然语言问题翻译成：
   - Exa / search query
   - domain / date / category filters
   - known URL reader tasks
   - browser verification tasks
4. `sources/search-round-N.md` 记录实际执行：
   - query / URL / route
   - result ordering 或 selected source
   - reader / browser 使用方式
   - highlights / text / summary 是否来自工具自动抽取
   - synthesis 是否由工具生成，还是由母 agent 基于来源写成
5. 对 Exa / Answer / deep search 的综合输出，必须保留“它是工具生成的 synthesis，不是原文证据本身”这个边界。

## 10. 资料来源

| 来源 | 用途 | URL |
|---|---|---|
| Exa Search API reference | Search endpoint、参数、结果字段、content / outputSchema / systemPrompt | `https://exa.ai/docs/reference/search` |
| Exa Search Best Practices | 自然语言 query、search types、highlights/text、freshness、schema、systemPrompt | `https://exa.ai/docs/reference/search-best-practices` |
| Exa Answer API | `/answer` 如何基于 Exa search results 生成 answer / summary + citations | `https://exa.ai/docs/reference/answer` |
| Exa Research | 多步 research：planning、semantic queries、结果扩展、reasoning & synthesis | `https://exa.ai/docs/reference/exa-research` |
| The Exa Index | Exa index 覆盖面和 curated index 说明 | `https://exa.ai/docs/reference/the-exa-index` |
| Migrating from Bing | Bing API 参数到 Exa 参数的映射、Exa response 与 Bing response 差异 | `https://exa.ai/docs/reference/migrating-from-bing` |
| Google Search Central: How Search works | Google crawling / indexing / serving 三阶段 | `https://developers.google.com/search/docs/fundamentals/how-search-works` |
| Google: Ranking results | Google 公开 ranking signals：meaning、relevance、quality、usability、context/settings | `https://www.google.com/search/howsearchworks/how-search-works/ranking-results/` |
| Agent Reach local skill | 本机 Agent Reach route 表和 Exa/Jina/GitHub 等入口 | `C:\Users\cwt\.codex\skills\agent-reach\SKILL.md` |
| web-access local skill | WebSearch / WebFetch / Jina / browser CDP 的工具选择边界 | `C:\Users\cwt\.codex\skills\web-access\SKILL.md` |

## 11. 待确认点

- Exa 没有公开完整 ranking algorithm；只能基于官方 API、index、best practices 和 research docs 说明公开可见机制。
- 本机 Agent Reach live MCP schema 未在主线程直接 introspect；涉及 `exa.web_search_exa` / `web_fetch_exa` / legacy tool 名称时，正式实现前仍要看实际 MCP schema。
- Bing 官方 ranking 细节没有找到足够清晰的一手公开说明；当前主要用 Google 官方文档代表“人类搜索引擎”的公开机制，用 Exa 的 Bing migration 文档说明 API 层差异。
