# Search API 服务对照

状态：知识快照
核对时间：2026-06-19
关联文件：`ai-search-tooling-knowledge-review.md`

## 0. 这份文档回答什么

这份文档只整理“可以给 agent / Codex 接入的搜索类服务”：它们负责发现来源、返回候选 URL / SERP / search snippets，有些还会附带正文抽取或答案综合。

不把以下工具当成主搜索 API：

- `Jina Reader` / `WebFetch` / `web-reader`：更接近“已知 URL 后读取页面”。
- in-app browser / Chrome extension：更接近“真实浏览器复核和交互”，不是批量搜索 API。
- GitHub CLI / 平台搜索：是垂直搜索入口，可进入 route plan，但不是通用 Web Search API。

当前结论：

- Codex 当前最直接可用的是 OpenAI 托管的 `web_search` / WebSearch 能力，以及本机 `agent-reach` route 里的 Exa。
- 如果要自己搭建 search route adapter，优先评估 OpenAI `web_search`、Exa、Serper；Exa 功能最贴合 workflow，但大陆充值可得性最差。
- SerpAPI / Serper 更像“Google SERP API”，适合需要模拟 Google 结果页、SEO、local pack、shopping、news 等结构化 SERP 的场景。
- Google Custom Search JSON API 已不适合新接入：官方说明对新客户关闭，既有客户需要在 2027-01-01 前迁移。
- Brave Search API 也支持时间过滤；上一版只写了 country/language/snippets/goggles，不够完整。

## 1. Codex / 本机可用性分层

| 层级 | 工具 / 服务 | 当前可用性 | 在 workflow 中的位置 |
|---|---|---|---|
| Codex 托管能力 | OpenAI `web_search` / WebSearch | 当前会话和 OpenAI API 生态可用；底层供应商和 ranking 未公开 | 默认低摩擦搜索入口；适合快速 current facts、带 citations 的回答 |
| 本机 skill route | AgentReach + Exa | 本机 `agent-reach` 的 search route 已写 `exa.web_search_exa` / `exa.get_code_context_exa` | 搜索子 agent lane 的主要候选；尤其适合英文技术、代码、docs、repo 类检索 |
| 可外接 API | Tavily | 需要 Tavily API key；有 SDK / API / MCP 生态 | Agent/RAG 友好搜索，参数简单，能直接返回 answer / raw content / images |
| 可外接 API | Brave Search API | 需要 Brave Search API key；公开 Web / Image / News / Answers 等 endpoint | 价格清晰，有独立 search index，适合需要低价真实 SERP / snippets 的 route |
| 可外接 API | SerpAPI | 需要 SerpAPI key；支持 MCP 和大量垂直 SERP | 需要 Google / Bing / YouTube / Maps / Shopping 等 SERP 结构时使用 |
| 可外接 API | Serper | 需要 Serper key；Google SERP API | 大批量低价 Google SERP，参数较少，适合轻量 Google results discovery |
| 旧式 / 不推荐新接入 | Google Custom Search JSON API | 对新客户关闭；既有客户迁移窗口到 2027-01-01 | 只作为 legacy 记录，不作为新 workflow 默认候选 |

## 2. 价格快照

价格非常容易变，下面只作为 2026-06-19 的 route-design 参考，真正接入前必须重新打开价格页核对。

| 服务 | 免费额度 / 试用 | 主要收费口径 | 备注 |
|---|---:|---:|---|
| OpenAI `web_search` | 无独立免费层；随 OpenAI API 账户计费 | 官方 pricing 的 Tools 区显示 Web search / Image Web search 等按 tool call 计费；当前可见口径为约 `$10 / 1k calls`，search content tokens 另按所选模型输入 token 计费；legacy non-reasoning preview 为 `$25 / 1k calls` 且 search content tokens 免费 | 新接入优先 Responses API `web_search`，不要用 legacy `web_search_preview` |
| Exa Search | 官方页面当前存在不同呈现：一处写 free tier 20,000 requests/month，另一处写 `$10` free credits；保守表述为“有免费额度/试用” | Search `$7 / 1k requests`；Deep Search `$12-15 / 1k requests`；Contents `$1 / 1k pages per content type`；Answer `$5 / 1k answers`；Agent 还有 per-run / ACU / search call 计费 | 不要写“Exa 免费”；应写“商业 API，有免费额度/credits” |
| Tavily | Free plan：`1,000 API credits / month` | Pay as you go `$0.008 / credit`；`basic` / `fast` / `ultra-fast` search 为 1 credit，`advanced` 为 2 credits | 对 agent 使用友好，价格按 credit 而不是固定每次搜索 |
| Brave Search API | 每月 `$5` free credits | Search `$5 / 1k requests`；Answers `$4 / 1k requests + $5 / 1M input/output tokens` | Search API 明确提供 50 QPS；Answers 是 OpenAI SDK compatible 的回答层 |
| SerpAPI | Free plan：`250 searches / month` | Starter `$25 / month` for 1,000 searches；Developer `$75 / month` for 5,000；Production `$150 / month` for 15,000；Big Data `$275 / month` for 30,000 | 单次成功 search 计数；返回 100 results 也算 1 search |
| Serper | `2,500 free queries` | Starter `$50` for 50k credits (`$1.00 / 1k`)；Standard `$375` for 500k (`$0.75 / 1k`)；Scale `$1250` for 2.5M (`$0.50 / 1k`)；Ultimate `$3750` for 12.5M (`$0.30 / 1k`) | 官网说实时查 Google、不缓存；适合大批量低价 SERP |
| Google Custom Search JSON API | 既有客户：`100 queries / day` free | `$5 / 1k queries`，最高 10k queries/day | 官方说明对新客户关闭，既有客户到 2027-01-01 前迁移 |

## 2.5 中国大陆可得性与第三方转售风险

本节是 2026-06-19 的操作性观察，混合了用户人工观察和官方文档核对。淘宝 / 闲鱼售卖状态不是官方渠道，也会快速变化；这里只作为个人 workflow 可得性判断，不作为采购建议。

| 服务 | 中国大陆可得性观察 | 第三方转售观察 | 风险判断 |
|---|---|---|---|
| OpenAI `web_search` / Codex WebSearch | 当前 Codex 环境可直接使用；对本工作区来说无需额外 API key 或单独充值 | 不需要 | 优先先用。限制是缺少显式 `category` 和显式 publish-date 参数；可以用 prompt、domain filters、source selection 和多轮 search 弥补一部分 |
| Exa | 功能最贴合，但官方充值难度高，需要境外银行卡；用户观察淘宝 / 闲鱼未发现相关售卖 | 少见 | 如果能解决充值和 API key，最适合做可控 route adapter；否则只能作为“功能理想型”或通过 AgentReach 现有可用额度使用 |
| Tavily | 官方付费可能同样有跨境支付问题 | 用户观察淘宝 / 闲鱼有较多售卖；常见说法是每个 API 对应一个初始免费账号 | 不建议直接信任共享/转卖 key。需要核查：API key 是否独占、账号归属是否可迁移、是否会被卖家回收、是否多人共用、是否违反服务条款、免费额度耗尽后的处理、请求日志是否暴露查询内容 |
| Brave Search API | 官方付费可能有跨境支付问题 | 用户观察淘宝 / 闲鱼有类似 Tavily 的售卖，且常见 2-3 人共享一个 API key | 共享 key 风险比独享更高：配额争用、rate limit 互相影响、查询内容可能被同 key 的账号所有者看到、key 被封会连带不可用 |
| SerpAPI | 官方付费可能有跨境支付问题 | 用户观察淘宝 / 闲鱼售卖较多 | 适合需要 Google SERP 结构时再考虑；第三方 key 同样要先核验是否独占和稳定 |
| Serper | 官方支持信用卡 / PayPal；跨境支付仍可能是门槛 | 用户观察淘宝 / 闲鱼售卖较多 | 综合可得性比 Exa 好，价格低，vertical endpoints 多；如果接受 Google SERP API 路线，是较现实候选 |

第三方 API key 的最低核查清单：

- 是否给独立 dashboard / 独立 API key，而不是只给一串共享 key。
- 能否自己重置 key、查看 usage、设置额度上限。
- 是否明确多人共享；共享 key 不适合写入长期自动化 workflow。
- 是否会把 query、URL、source list 暴露给卖家或同账号使用者。
- 是否违反平台条款；被封禁时是否有替换和退款机制。
- 初始免费账号模式是否只是批量注册免费额度；如果是，不适合作为稳定依赖。

## 3. 参数对照

### 3.1 OpenAI `web_search`

定位：OpenAI 托管的 built-in tool。它不是公开的独立 search API，也没有公开底层使用哪家搜索供应商。

常用参数 / 控制面：

| 参数 | 含义 | route 设计含义 |
|---|---|---|
| `tools: [{ "type": "web_search" }]` | 启用 Responses API Web Search | 新接入默认用这个，不用 legacy `web_search_preview` |
| `search_context_size` | `low` / `medium` / `high`，控制搜索结果给模型的上下文量 | 影响成本、延迟和可读上下文，不保证固定来源数量 |
| `filters.allowed_domains` | 最多 100 个允许域名 | 适合 primary-source-first route |
| `filters.blocked_domains` | 最多 100 个排除域名 | 适合排除 Reddit / Quora / Wikipedia 等非目标来源 |
| `external_web_access` | `true` 默认 live；`false` 为 offline/cache-only | 需要可复现或禁 live access 时使用 |
| `return_token_budget` | `default` / `unlimited`；只适用于 GPT-5+ reasoning web search | 长研究任务才考虑 `unlimited` |
| `search_content_types` | `text` / `image` | 需要图片结果时显式启用 image |
| `image_settings.max_results` | 图片结果数量 | image search 专用 |
| `image_settings.caption` | 是否返回图片 caption | image search 专用 |
| `user_location` | 近似国家、城市、地区、时区 | 本地化 query 使用；deep research 不支持 user location |
| `include: ["web_search_call.action.sources"]` | 返回所有 consulted URLs | 审计 search-round 时建议打开 |
| `tool_choice` | `auto` / `required` / 指定 tool | 必须搜索时不要只依赖 `auto` |
| `reasoning.effort` / `background` | 控制 agentic search 深度和长任务运行方式 | 长 research run 才需要 |

输出要点：

- `web_search_call.action.type` 可能是 `search`、reasoning model 下的 `open_page`、`find_in_page`。
- `message.content[].annotations` 里有 inline URL citations。
- `sources` 比 inline citations 更完整，适合写入 search-round audit。
- 它没有公开显式 `category` 参数，也没有 Exa/Tavily/Brave 那种结构化 publish-date/freshness 参数；若 workflow 强依赖“只查某类来源/某个发布时间窗”，需要靠 prompt、domain filters、query 约束、多轮复核或外部 search API 弥补。

### 3.2 Exa

定位：面向 AI / agent 的搜索 API；本机 AgentReach search route 当前使用它。

常用参数：

| 参数 | 含义 | route 设计含义 |
|---|---|---|
| `query` | 必填搜索 query；支持自然语言语义搜索 | 可由 `derived.search_plan.questions` 转换 |
| `numResults` | 默认 10，公开最大 100 | 控制 discovery 候选规模 |
| `includeDomains` | 只从指定域名返回 | primary source / site-specific search |
| `excludeDomains` | 排除域名 | 去掉低质量来源 |
| `startPublishedDate` / `endPublishedDate` | 按发布日过滤 | current facts / news 场景 |
| `startCrawlDate` / `endCrawlDate` | 按 Exa crawl / discover 时间过滤 | freshness audit 场景 |
| `contents.text` | 返回正文文本 | 将 discovery + reader 合并，成本和 token 增加 |
| `contents.highlights` | 返回 query-relevant snippets | 适合低 token 初筛 |
| `contents.summary` | 返回页面摘要 | 摘要要当作工具 synthesis，不当作原文 |
| `type` | `instant` / `fast` / `auto` / `deep-lite` / `deep` / `deep-reasoning` | 控制 latency、搜索深度和 synthesis |
| `category` | `company` / `research paper` / `news` / `personal site` / `financial report` / `people` 等 | 垂直搜索；部分 category 参数限制更严格 |
| `outputSchema` | 要求结构化 synthesized output | 只能作为辅助，claims 仍要回源 |
| `systemPrompt` | 指导 source preference / 去重 / 输出风格 | 可写“prefer official sources” |
| `maxAgeHours` | cache / livecrawl freshness 控制 | 正式接入前需按最新 schema 再核对 |

AgentReach 当前路由：

```bash
mcporter call 'exa.web_search_exa(query: "query", numResults: 5)'
mcporter call 'exa.get_code_context_exa(query: "code question", tokensNum: 3000)'
```

对本 workflow 的特殊价值：

- `startPublishedDate` / `endPublishedDate` 和 `startCrawlDate` / `endCrawlDate` 同时存在，能把“事实发生时间”和“Exa 抓取/发现时间”拆开审计。
- `category` 比 Tavily 的 `topic` 更贴近研究工作流，尤其是 `research paper`、`news`、`financial report`、`personal site`、`company`、`people`。
- 局限是 `company` / `people` category 不支持部分日期和排除域名过滤；不能把 category 当作无限制组合条件。

### 3.3 Tavily

定位：agent/RAG 友好的 Web Search API。返回 sorted results，可选 answer、raw content、images。

常用参数：

| 参数 | 含义 | route 设计含义 |
|---|---|---|
| `query` | 必填搜索 query | discovery 主输入 |
| `search_depth` | `ultra-fast` / `fast` / `basic` / `advanced` | `advanced` 更贵，官方写 2 credits |
| `chunks_per_source` | advanced 下每个 source 的 chunks 数，1-3 | 控制每条结果上下文长度 |
| `max_results` | 0-20，默认 5 | 控制候选数量 |
| `topic` | `general` / `news` / `finance` | 新闻/金融可显式指定 |
| `time_range` | `day` / `week` / `month` / `year` 及短写 | current facts |
| `start_date` / `end_date` | `YYYY-MM-DD` | 精确时间窗 |
| `include_answer` | `false` / `basic` / `advanced` / `true` | 是否要 LLM answer；研究审计时需标成 synthesis |
| `include_raw_content` | `false` / `markdown` / `text` / `true` | 是否读取正文 |
| `include_images` | 是否返回图片 | 图片发现 |
| `include_image_descriptions` | 图片描述 | 需要图像候选解释时使用 |
| `include_favicon` | favicon | UI / source cards |
| `include_domains` / `exclude_domains` | 域名 include/exclude | primary source / blacklist |
| `country` | 国家 boost，只在 `topic=general` 可用 | 本地化 |
| `auto_parameters` | 让 Tavily 自动配置参数，可能把 search_depth 设为 advanced | 方便但会影响成本，可控 route 不应默认打开 |
| `exact_match` | 要求 query 中引号短语精确匹配 | 人名、公司名、短语查证 |
| `include_usage` | 返回 credit usage | 计费审计建议打开 |
| `safe_search` | enterprise only | 不作为默认 route 依赖 |

对本 workflow 的判断：

- Tavily 有时间过滤、domain include/exclude、raw content 和 answer，参数整体比 OpenAI `web_search` 可控。
- 但 `topic` 当前只有 `general` / `news` / `finance`，领域划分明显少于 Exa；不适合作为“研究领域分类”的主控参数。
- `include_answer` 和 `include_raw_content` 方便，但必须在 search-round 里标明哪些是 Tavily synthesis，哪些是原文抽取。

### 3.4 Brave Search API

定位：独立搜索 index + search API，价格清晰，适合需要 raw search results / snippets 的 agent。

常用参数：

| 参数 | 含义 | route 设计含义 |
|---|---|---|
| `q` | 必填 query | discovery 主输入 |
| `freshness` | `pd` / `pw` / `pm` / `py` 或自定义日期范围 | 这是上一版遗漏的关键能力；适合最近 24 小时、7 天、31 天、1 年或精确日期窗 |
| `country` | 2 字母国家码 | 本地化 |
| `search_lang` | 内容语言 | 中英文结果控制 |
| `ui_lang` | response metadata/UI language | 多语言 UI / metadata |
| `count` | 每页结果数，默认/最大 20 | 控制候选数量 |
| `offset` | 分页 offset，最大 9 | 少量翻页 |
| `extra_snippets` | 每条结果最多额外 5 个 snippets | 提升初筛上下文 |
| `goggles` | 自定义 re-ranking / filtering | 强 route policy 可考虑 |
| `safesearch` | `off` / `moderate` / `strict` | 安全过滤 |
| `spellcheck` | 拼写纠错 | image 等 endpoint 示例中出现 |
| 搜索 operators | `site:`、`filetype:`、引号、`-term` 等写进 `q` | 与 Google 风格 query 接近 |

注意：

- Brave 还有 Answers endpoint，价格和 Web Search 不同；它更像 answer layer，不是纯 result list。
- 官网明确强调 snippets、Goggles、schema-enriched results、独立 index。
- Brave 没有 Exa 那种 `category` 参数；它的可控性更多来自 `freshness`、country/language、operators、Goggles 和 endpoint 选择。

### 3.5 SerpAPI

定位：多搜索引擎 / 多垂直 SERP API。它不是“AI search”，而是把 Google、Bing、YouTube、Maps、Shopping、Scholar 等 SERP 结构化。

Google Search API 常用参数：

| 参数 | 含义 | route 设计含义 |
|---|---|---|
| `engine=google` | 指定 Google Search API | 默认 Google SERP |
| `q` | query，支持 `site:` / `inurl:` / `intitle:` 等 | SERP discovery 主输入 |
| `location` | 模拟搜索发起位置 | local SERP |
| `uule` | Google encoded location | 精确位置控制 |
| `lat` / `lon` / `radius` | 经纬度和半径 | local pack / POI |
| `google_domain` | Google 域名，如 `google.com` | 地域 / 域名控制 |
| `gl` | 国家码 | 国家结果 |
| `hl` | 界面语言 | 语言控制 |
| `cr` | 限制结果国家 | country restrict |
| `lr` | 限制结果语言 | language restrict |
| `num` / `start` | 结果数 / 分页 | 扩展候选 |
| `safe` | SafeSearch | 安全过滤 |
| `device` | desktop / mobile / tablet | 模拟设备 |
| `tbm` 或对应 engine | images / news / videos / shopping 等 | 垂直 SERP |

适合：

- 需要 Google 原生 SERP 元素，如 `organic_results`、`people_also_ask`、`knowledge_graph`、`top_stories`、`local_pack`。
- SEO、平台监控、SERP 对齐。

不适合：

- 直接让 LLM 做综合答案。它返回 SERP 数据，synthesis 要自己做。

### 3.6 Serper

定位：低价 Google SERP API，覆盖 Search / Images / News / Maps / Places / Videos / Shopping / Scholar / Patents / Autocomplete。

公开主页能确认的控制面：

| 参数 / 能力 | 含义 | route 设计含义 |
|---|---|---|
| `q` | 搜索 query | discovery 主输入 |
| country / language | 官网 FAQ 写可通过国家和语言自定义 location | 本地化 |
| vertical endpoints | Search、Images、News、Maps、Places、Videos、Shopping、Scholar、Patents、Autocomplete | 按 source surface 选择 endpoint |
| realtime Google results | 官网 FAQ 写每次 API call 直接 query Google，不缓存 | current facts 友好，但要注意 Google SERP 波动 |
| credits | 成功响应扣 credit | 需要记录成本 |

常见实现还会用 `gl`、`hl`、`location`、`num`、`page`、`tbs` 等参数；但这份快照没有从当前公开静态页面完整抽出 live schema，正式实现前要重新打开 Serper dashboard / playground / OpenAPI schema 核对。

对本 workflow 的判断：

- Serper 的优势不是领域分类参数，而是低价、可得性、Google SERP、vertical endpoints。
- 如果 workflow 需要“论文 / 新闻 / 财报 / 公司 / 个人站点”这种研究对象分类，Serper 需要通过 endpoint、query operators、domain allowlist 和后处理 triage 实现。
- 如果 workflow 只需要稳定拿 Google results、News、Images、Scholar、Patents 等垂直入口，Serper 是现实候选。

### 3.7 Google Custom Search JSON API

定位：Google 官方 Programmable Search Engine 的 JSON API。当前不建议新接入。

常用参数：

| 参数 | 含义 | route 设计含义 |
|---|---|---|
| `key` | API key | 必需 |
| `cx` | Programmable Search Engine ID | 必需 |
| `q` | query | discovery 主输入 |
| `num` / `start` | 结果数 / 分页 | 候选规模 |
| `dateRestrict` | `d[number]` / `w[number]` / `m[number]` / `y[number]` | 时间过滤 |
| `exactTerms` | 必须包含短语 | 精确查证 |
| `excludeTerms` | 排除词 | 去噪 |
| `fileType` | 文件类型 | PDF / docs 搜索 |
| `filter` | duplicate content filter | 去重控制 |
| `gl` / `hl` | 地域 / UI 语言 | 本地化 |
| `cr` / `lr` | country restrict / language restrict | 限定来源国家 / 语言 |
| `searchType=image` | 图片搜索 | 图片发现 |
| `imgSize` / `imgType` / `imgColorType` / `imgDominantColor` | 图片过滤 | image route |
| `safe` | SafeSearch | 安全过滤 |
| `siteSearch` / `siteSearchFilter` | 指定或排除站点 | site-specific search |

限制：

- 官方写明 API 对新客户关闭。
- 既有客户迁移期限到 2027-01-01。
- 只能作为 legacy 方案记录，不适合作为新设计默认依赖。

## 4. 选择建议

| 需求 | 优先选择 | 原因 |
|---|---|---|
| Codex 内快速回答 current facts | OpenAI `web_search` / WebSearch | 最少接入成本，自带 citations；当前无需额外付费或外部 key |
| 本 repo 的理想 search route | Exa | 时间过滤、crawl/publish 区分、category、contents、deep search 最贴合 workflow |
| 大陆环境下现实可得的低价 Google SERP | Serper | 单价低，免费 query 多，淘宝 / 闲鱼可得性观察较好，vertical endpoints 多 |
| 需要可控、便宜、返回 snippets 的通用 search API | Brave Search API | 价格清晰，raw results 友好 |
| 需要 answer + raw content + domain/date controls 的 agent search | Tavily | 参数为 agent/RAG 场景设计 |
| 需要 Google SERP 结构，比如 PAA、local pack、knowledge graph、shopping | SerpAPI | SERP 覆盖最细，垂直 endpoint 多 |
| 旧项目已经用了 Google CSE | Google Custom Search JSON API | 只维护 legacy，别新建依赖 |

当前倾向：

1. 先验证 Codex 自带 `web_search` 是否足够：对于多数 current facts、官方文档核对、普通资料发现，它已经能满足，并且不需要额外采购。
2. 如果需要可审计的结构化 route adapter，Exa 是功能最优候选；关键阻碍是大陆充值和稳定额度。
3. 如果需要现实可得、低价、可批量的 Google SERP，Serper 是比 Exa 更容易落地的候选，但需要自己做分类、筛选和证据压缩。
4. Tavily / Brave 可作为备选。Tavily 的 topic 太少；Brave 有 freshness 和 Goggles，但缺少 Exa 式 category。
5. 不建议把淘宝 / 闲鱼共享 API key 写进长期自动化流程；可以用于短期试验，但要隔离查询内容和预算风险。

## 5. 对 workflow route adapter 的含义

1. Opening 阶段仍只写自然语言 `questions`、`source_surfaces`、`stop_when`。
2. Search Round route adapter 再选择具体服务和参数：
   - OpenAI `web_search`：适合低配置、需要 citations 的快速查证。
   - Exa / Tavily / Brave：适合可审计 search lane，记录 query、结果列表、source snippets。
   - SerpAPI / Serper：适合“我要看 Google SERP 长什么样”的场景。
3. Search Round 里必须记录：
   - 服务名和 endpoint；
   - query；
   - 参数快照；
   - 返回 URL 清单；
   - 哪些内容来自 search snippets，哪些来自 reader / browser；
   - 是否使用了工具自带 answer / summary / synthesis。
4. 对任何 answer / summary / synthesized output，都不要直接当成事实证据；关键 claim 仍要回源 URL。

## 6. 资料来源

| 来源 | 用途 | URL |
|---|---|---|
| OpenAI Web Search guide | `web_search` 类型、输出、citations、domain filters、sources、image search、live access、limitations | `https://developers.openai.com/api/docs/guides/tools-web-search` |
| OpenAI Pricing | built-in tools pricing、search content token 计费 | `https://developers.openai.com/api/docs/pricing` |
| Exa getting started | Exa 定位和 Search / Contents / Answer / Research 功能 | `https://exa.ai/docs/reference/getting-started` |
| Exa Search reference | Search endpoint 参数、contents、type、category、outputSchema | `https://exa.ai/docs/reference/search` |
| Exa Pricing | Search / Deep Search / Contents / Answer / Agent 价格 | `https://exa.ai/pricing` |
| Tavily Search docs | Search endpoint 参数和 credit 计费规则 | `https://docs.tavily.com/documentation/api-reference/endpoint/search` |
| Tavily Pricing | free credits、pay-as-you-go credit 价格 | `https://www.tavily.com/pricing` |
| Brave Search API docs | Web search parameters、country/language、extra snippets、Goggles、pagination、safesearch | `https://api-dashboard.search.brave.com/app/documentation/web-search/get-started` |
| Brave Search API pricing/product page | Search / Answers 价格、free credits、QPS、features | `https://brave.com/search/api/` |
| SerpAPI Google Search API | Google SERP endpoint、query/location/localization parameters | `https://serpapi.com/search-api` |
| SerpAPI Pricing | free / paid plans、monthly search quotas、计数规则 | `https://serpapi.com/pricing` |
| Serper homepage | supported verticals、free queries、pricing、realtime/country/language statements | `https://serper.dev/` |
| Google Custom Search JSON API overview | free quota、pricing、new-customer closure、2027 migration deadline | `https://developers.google.com/custom-search/v1/overview` |
| Google Custom Search REST reference | query parameters | `https://developers.google.com/custom-search/v1/reference/rest/v1/cse/list` |
| AgentReach local skill | 本机 route：Exa search、Jina Reader、GitHub search 等 | `C:\Users\cwt\.codex\skills\agent-reach\SKILL.md` |
| AgentReach search reference | `exa.web_search_exa`、`exa.get_code_context_exa` | `C:\Users\cwt\.codex\skills\agent-reach\references\search.md` |
| User observation | 中国大陆环境下充值、淘宝 / 闲鱼转售和共享 API key 可得性观察 | 2026-06-19 对话输入 |
