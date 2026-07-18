# Search API eval test cases

状态：测试设计草案
创建日期：2026-06-19

## 0. 原始 motivation

当前 workflow 需要选择一个适合长期接入的搜索 API。选型重点不是单次回答是否看起来完整，而是搜索服务能否稳定支持 search round 所需的三个控制面：

- 时间过滤：能否按最近时间窗或明确起止日期筛选结果。
- 来源面控制：能否分别面向 `primary`、`community`、`web` 找到可复核来源。
- 地域控制：能否在中国和美国两个地域语境下产生可区分、可解释的结果。

本测试只设计实测用例和调用形式，不注册账号、不调用 API、不写最终选型结论。

## 1. 测试主题

统一测试主题：

> AI coding agents / CLI agents 在真实开发或研究工作流中的能力、限制和使用反馈。

主题覆盖对象包括 Codex、Claude Code、Gemini CLI、Cursor / Windsurf agent、open-source coding agents，以及围绕这些工具的 workflow、tool use、MCP / skills / hooks、browser/search integration、日志、成本、可靠性和真实使用反馈。

选择该主题的原因：

- `primary` 有明确官方来源，例如官方文档、release notes、pricing / availability 页面、官方 GitHub repo。
- `community` 有真实讨论来源，例如 GitHub issues / discussions、Reddit、Hacker News、V2EX、知乎、小红书、Stack Overflow。
- `web` 有普通网页、新闻、博客、教程、测评和对比文章。
- 中国和美国两个地域都有相关材料，不会把测试变成单一国家政策或法规问题。

## 2. 候选与排除

本轮候选：

| 服务 | 是否测试 | 说明 |
|---|---|---|
| OpenAI Responses `web_search` | yes | 可编程 OpenAI API baseline。 |
| Codex WebSearch baseline | yes | 当前 Codex 会话能力 baseline，不视为稳定外部 adapter API。 |
| Exa / AgentReach | yes | 本机 AgentReach 现有路线和 Exa API 能力。 |
| Tavily | yes | agent / RAG 友好的搜索 API。 |
| Brave Search API | yes | 独立 search index，参数较接近传统 search API。 |
| Serper.dev | yes | Google SERP API 候选。 |
| SerpAPI | no | 注册不可用，本轮排除。 |

## 3. 测试矩阵

三个维度：

| 维度 | 取值 |
|---|---|
| 来源面 | `primary`、`community`、`web` |
| 地域 | `CN`、`US` |
| 时间 | `relative_15d`、`absolute_may` |

时间窗口固定为：

| 时间模式 | 起止日期 | 说明 |
|---|---|---|
| `relative_15d` | `2026-06-04..2026-06-19` | 以当前测试设计日 2026-06-19 回推 15 天。 |
| `absolute_may` | `2026-05-01..2026-05-31` | 明确绝对日期窗，与最近 15 天不重叠。 |

每个服务执行 12 个 case：

| case id 模板 | 来源面 | 地域 | 时间 |
|---|---|---|---|
| `{surface}_{region}_{time_mode}` | `primary/community/web` | `CN/US` | `relative_15d/absolute_may` |

示例：

- `primary_cn_relative_15d`
- `community_us_absolute_may`
- `web_cn_absolute_may`

## 4. 来源面定义

| 来源面 | 定义 | 典型来源 |
|---|---|---|
| `primary` | 研究对象本身或直接责任方的一手来源。 | 官方 docs、API reference、release notes、pricing / availability 页面、官方博客、官方 GitHub repo。 |
| `community` | 围绕问题有持续讨论、经验交换或问题复现的社区入口。 | GitHub issues / discussions、Reddit、Hacker News、V2EX、知乎、小红书、Stack Overflow、专业论坛。 |
| `web` | 普通网页和二手整理。 | 新闻、博客、教程、测评、对比文章、资料汇总。 |

`web` 本轮包含 news，但不单独使用 news endpoint。目标是测试普通 web 搜索对二手来源的覆盖，而不是测试新闻专用搜索。

## 5. 通用 prompt 模板

### 5.1 `primary`

```text
Find official or first-party sources about AI coding agents or CLI agents
such as Codex, Claude Code, Gemini CLI, Cursor agent, Windsurf agent, or open-source coding agents.
Focus on official capabilities, release notes, docs, pricing/availability, workflow integration,
tool use, browser/search support, MCP/skills/hooks, logs, and limitations.

Region focus: {REGION_LABEL}.
Time focus: {TIME_LABEL}.

Only use official or first-party sources: official docs, API reference, release notes,
official blogs, official pricing/availability pages, official GitHub repositories,
or official announcements.

Exclude community discussions, ordinary blogs, SEO pages, news reposts, and comparison articles.

Return title, URL, visible publication/update date if available, and a short reason why each source is primary.
```

### 5.2 `community`

```text
Find community discussions and real user cases about AI coding agents or CLI agents
such as Codex, Claude Code, Gemini CLI, Cursor agent, Windsurf agent, or open-source coding agents.
Focus on real workflow problems, agent loops, tool failures, context limits, search/browser integration,
cost, reliability, logs, MCP/skills/hooks, and daily usage experience.

Region focus: {REGION_LABEL}.
Time focus: {TIME_LABEL}.

Only use community/case sources: GitHub issues/discussions, Reddit, Hacker News, V2EX,
Zhihu, Xiaohongshu, Stack Overflow, forums, or similar user discussion pages.

Exclude official docs, official pricing pages, and ordinary news/blog articles unless they are linked from a discussion.

Return title, URL, visible date if available, platform, and what user problem or experience it shows.
```

### 5.3 `web`

```text
Find ordinary web, news, blog, tutorial, review, or comparison sources about AI coding agents
or CLI agents such as Codex, Claude Code, Gemini CLI, Cursor agent, Windsurf agent,
or open-source coding agents.

Focus on practical comparisons, workflow advice, limitations, adoption, product updates,
and independent analysis.

Region focus: {REGION_LABEL}.
Time focus: {TIME_LABEL}.

Exclude official docs and community threads when possible.

Return title, URL, visible publication date if available, publisher/site, and what the page contributes.
```

### 5.4 变量填充

| 变量 | CN | US |
|---|---|---|
| `{REGION_LABEL}` | `China / Chinese-language web / mainland China user context` | `United States / English-language web / US user context` |

| 变量 | `relative_15d` | `absolute_may` |
|---|---|---|
| `{TIME_LABEL}` | `published or updated between 2026-06-04 and 2026-06-19, or clearly discussing changes in the last 15 days` | `published or updated between 2026-05-01 and 2026-05-31` |

## 6. 通用域名集合

域名集合用于服务支持 include / exclude domains 时的来源面控制。执行前可以按最新实际情况调整。

### 6.1 Primary domains

```text
openai.com
developers.openai.com
platform.openai.com
docs.anthropic.com
anthropic.com
github.com/openai
github.com/anthropics
github.com/google-gemini
github.com/google
github.com/features
cursor.com
docs.cursor.com
windsurf.com
docs.windsurf.com
```

### 6.2 Community domains

```text
github.com
reddit.com
news.ycombinator.com
v2ex.com
zhihu.com
xiaohongshu.com
stackoverflow.com
discuss.python.org
dev.to
```

### 6.3 Web exclusion domains

`web` 来源面尽量排除官方和社区入口。若服务不支持 blocked domains，则在 query 中使用 `-site:`。

```text
openai.com
developers.openai.com
platform.openai.com
docs.anthropic.com
anthropic.com
github.com
reddit.com
news.ycombinator.com
v2ex.com
zhihu.com
xiaohongshu.com
stackoverflow.com
```

## 7. 每家调用设计

### 7.1 OpenAI Responses `web_search`

固定策略：

- `search_context_size`: `medium`
- `tool_choice`: `required`
- `include`: `["web_search_call.action.sources"]`
- 返回长度：使用默认模型输出控制，不额外要求长答案。

地域参数：

```json
{
  "user_location": {
    "type": "approximate",
    "country": "CN"
  }
}
```

或：

```json
{
  "user_location": {
    "type": "approximate",
    "country": "US"
  }
}
```

来源面参数：

```json
{
  "type": "web_search",
  "search_context_size": "medium",
  "filters": {
    "allowed_domains": ["<primary domains>"]
  },
  "user_location": {
    "type": "approximate",
    "country": "CN or US"
  }
}
```

`community` 使用 `allowed_domains` 填 community domains。

`web` 使用 `blocked_domains` 排除 primary + community domains：

```json
{
  "type": "web_search",
  "search_context_size": "medium",
  "filters": {
    "blocked_domains": ["<primary + community domains>"]
  },
  "user_location": {
    "type": "approximate",
    "country": "CN or US"
  }
}
```

时间控制：

- OpenAI Responses `web_search` 没有显式 publish-date 参数。
- `relative_15d` 和 `absolute_may` 写入 prompt。
- 执行后通过 `sources` 和页面日期做后验判断。

请求骨架：

```json
{
  "model": "<model>",
  "tools": [
    {
      "type": "web_search",
      "search_context_size": "medium",
      "filters": {},
      "user_location": {
        "type": "approximate",
        "country": "CN or US"
      }
    }
  ],
  "tool_choice": "required",
  "include": ["web_search_call.action.sources"],
  "input": "<surface prompt>"
}
```

### 7.2 Codex WebSearch baseline

定位：

- 作为当前 Codex 会话搜索能力 baseline。
- 不当作可长期稳定接入的外部 search adapter API。

参数策略：

- `relative_15d`：如果工具支持 `recency`，设置 `recency = 15`。
- `absolute_may`：将绝对日期写入 query / prompt，并做后验判断。
- 来源面：如果工具支持 `domains`，用 domain include 控制；否则通过 prompt 和 query operators 控制。
- 地域：写入 query / prompt，例如 `China Chinese-language` 或 `United States English-language`。
- 返回长度：使用默认返回长度。

示例查询：

```text
AI coding agents CLI agents workflow limitations community discussions China Chinese-language published between 2026-06-04 and 2026-06-19
```

### 7.3 Exa / AgentReach

时间参数：

`relative_15d`：

```json
{
  "startPublishedDate": "2026-06-04",
  "endPublishedDate": "2026-06-19"
}
```

`absolute_may`：

```json
{
  "startPublishedDate": "2026-05-01",
  "endPublishedDate": "2026-05-31"
}
```

可选补测：

```json
{
  "startCrawlDate": "2026-06-04",
  "endCrawlDate": "2026-06-19"
}
```

来源面参数：

- `primary`: `includeDomains = primary domains`
- `community`: `includeDomains = community domains`
- `web`: `excludeDomains = primary + community domains`

地域控制：

- 无稳定 country/location 参数时，在 query 中写明地域。
- CN query 加入 `China`、`Chinese-language`、`中国`、`中文`。
- US query 加入 `United States`、`US`、`English-language`。

内容策略：

- 返回长度使用默认或中档。
- 优先使用 snippets / highlights。
- 不默认拉全文。

请求骨架：

```json
{
  "query": "<surface prompt rewritten as search query>",
  "startPublishedDate": "YYYY-MM-DD",
  "endPublishedDate": "YYYY-MM-DD",
  "includeDomains": [],
  "excludeDomains": [],
  "contents": {
    "highlights": true
  }
}
```

### 7.4 Tavily

时间参数：

```json
{
  "start_date": "2026-06-04",
  "end_date": "2026-06-19"
}
```

或：

```json
{
  "start_date": "2026-05-01",
  "end_date": "2026-05-31"
}
```

地域参数：

```json
{
  "country": "china"
}
```

或：

```json
{
  "country": "united states"
}
```

来源面参数：

- `primary`: `include_domains = primary domains`
- `community`: `include_domains = community domains`
- `web`: `exclude_domains = primary + community domains`

固定策略：

```json
{
  "topic": "general",
  "include_answer": false,
  "include_raw_content": false
}
```

返回长度：使用默认 `max_results`，不主动调大。

请求骨架：

```json
{
  "query": "<surface prompt rewritten as search query>",
  "topic": "general",
  "country": "china or united states",
  "start_date": "YYYY-MM-DD",
  "end_date": "YYYY-MM-DD",
  "include_domains": [],
  "exclude_domains": [],
  "include_answer": false,
  "include_raw_content": false
}
```

### 7.5 Brave Search API

时间参数：

- `relative_15d`: 优先使用自定义 `freshness` 日期范围 `2026-06-04to2026-06-19`；若 API 不接受该格式，记录失败并降级到 query 日期约束。
- `absolute_may`: 优先使用自定义 `freshness` 日期范围 `2026-05-01to2026-05-31`；若 API 不接受该格式，记录失败并降级到 query 日期约束。

地域和语言：

```json
{
  "country": "CN",
  "search_lang": "zh",
  "ui_lang": "zh-CN"
}
```

或：

```json
{
  "country": "US",
  "search_lang": "en",
  "ui_lang": "en-US"
}
```

来源面 query operators：

`primary`：

```text
(site:openai.com OR site:developers.openai.com OR site:docs.anthropic.com OR site:anthropic.com OR site:cursor.com OR site:windsurf.com) AI coding agents CLI agents workflow limitations
```

`community`：

```text
(site:github.com OR site:reddit.com OR site:news.ycombinator.com OR site:v2ex.com OR site:zhihu.com OR site:stackoverflow.com) AI coding agents CLI agents workflow problems
```

`web`：

```text
AI coding agents CLI agents workflow limitations reviews tutorials comparisons -site:openai.com -site:developers.openai.com -site:docs.anthropic.com -site:github.com -site:reddit.com -site:news.ycombinator.com -site:v2ex.com -site:zhihu.com -site:stackoverflow.com
```

返回长度：

- 使用默认 `count`。
- 第一轮不开 `extra_snippets`。

请求骨架：

```json
{
  "q": "<operator query>",
  "freshness": "YYYY-MM-DDtoYYYY-MM-DD",
  "country": "CN or US",
  "search_lang": "zh or en",
  "ui_lang": "zh-CN or en-US"
}
```

### 7.6 Serper.dev

endpoint：

- 第一轮统一使用 `search` endpoint。
- 不使用 `news` endpoint，避免把 `web` 来源面变成 news-only 测试。

地域参数：

```json
{
  "gl": "cn",
  "hl": "zh-cn",
  "location": "China"
}
```

或：

```json
{
  "gl": "us",
  "hl": "en",
  "location": "United States"
}
```

时间参数：

`relative_15d`：

```json
{
  "tbs": "qdr:d15"
}
```

`absolute_may`：

```json
{
  "tbs": "cdr:1,cd_min:05/01/2026,cd_max:05/31/2026"
}
```

来源面 query operators：

`primary`：

```text
(site:openai.com OR site:developers.openai.com OR site:docs.anthropic.com OR site:anthropic.com OR site:cursor.com OR site:windsurf.com) AI coding agents CLI agents workflow limitations
```

`community`：

```text
(site:github.com OR site:reddit.com OR site:news.ycombinator.com OR site:v2ex.com OR site:zhihu.com OR site:stackoverflow.com) AI coding agents CLI agents workflow problems
```

`web`：

```text
AI coding agents CLI agents workflow limitations reviews tutorials comparisons -site:openai.com -site:developers.openai.com -site:docs.anthropic.com -site:github.com -site:reddit.com -site:news.ycombinator.com -site:v2ex.com -site:zhihu.com -site:stackoverflow.com
```

返回长度：

- 使用默认 `num`。
- 不主动分页；第一页不够再记录为后续补测。

请求骨架：

```json
{
  "q": "<operator query>",
  "gl": "cn or us",
  "hl": "zh-cn or en",
  "location": "China or United States",
  "tbs": "<date filter>"
}
```

## 8. JSON 保存结构

每次调用保存一个 JSON。文件名建议：

```text
<service>__<surface>_<region>_<time_mode>.json
```

示例：

```text
openai_web_search__primary_cn_relative_15d.json
tavily__community_us_absolute_may.json
```

JSON 结构：

```json
{
  "case_id": "primary_cn_relative_15d",
  "service": "openai_web_search",
  "run_at": "2026-06-19T00:00:00+08:00",
  "source_surface": "primary",
  "region": "CN",
  "time_mode": "relative_15d",
  "time_window": {
    "start": "2026-06-04",
    "end": "2026-06-19"
  },
  "prompt": "",
  "request_params": {},
  "raw_response": {},
  "normalized_results": [
    {
      "rank": 1,
      "title": "",
      "url": "",
      "date": "",
      "snippet": "",
      "source_surface_guess": "",
      "notes": ""
    }
  ],
  "operator_notes": {
    "date_filter_applied": "",
    "region_filter_applied": "",
    "source_surface_filter_applied": "",
    "fallbacks": []
  }
}
```

真实 API key、headers、cookies、账号信息不得写入 JSON。

## 9. 执行记录要求

每个 case 至少记录：

- 实际服务和 endpoint。
- 实际 prompt / query。
- 实际参数。
- 原始返回 JSON。
- normalized results。
- 时间过滤是否由 API 参数执行，还是只能后验判断。
- 地域控制是否由 API 参数执行，还是只能 query/prompt 约束。
- 来源面控制是否由 API 参数执行，还是只能 query/prompt / operators 约束。
- 失败或降级原因。

## 10. 清理步骤

如果本测试后续创建临时测试资产，统一使用 `test-` 前缀，并在收尾时执行：

1. 删除临时测试输出。
2. 清理不应保留的 raw JSON。
3. 确认没有 API key、cookies、headers、账号信息进入仓库。
4. 如后续引入索引或缓存，按对应脚本 rebuild index。
