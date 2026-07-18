# Search API eval parameter capabilities

状态：参数能力快照草案
创建日期：2026-06-19

## 0. 用途

本文件单独记录待测试服务的参数能力摘要，供 `search-api-eval-test-cases.md` 将测试意图翻译为各家 API 调用时使用。

参数和价格会变化。正式实测前，应重新打开各服务官方文档或 dashboard 核对最新 schema。涉及价格或免费额度时，采信日期应尽量在两周以内。

## 1. 对照总览

| 服务 | 时间过滤 | 来源面控制 | 地域 / 语言控制 | 返回内容控制 | 备注 |
|---|---|---|---|---|---|
| OpenAI Responses `web_search` | 无显式 publish-date 参数；靠 prompt + 后验判断 | `filters.allowed_domains`、`filters.blocked_domains` | `user_location` | `search_context_size`、`include` sources | 本轮固定 `search_context_size=medium`。 |
| Codex WebSearch baseline | 当前会话工具可用 `recency`；绝对日期靠 prompt + 后验判断 | 当前会话工具可用 `domains` 时使用 | 主要靠 query / prompt | 工具默认 | 只作当前环境 baseline。 |
| Exa / AgentReach | `startPublishedDate`、`endPublishedDate`、`startCrawlDate`、`endCrawlDate` | `includeDomains`、`excludeDomains`、`category` | 主要靠 query / prompt | `contents.highlights`、`contents.text` 等 | 功能最贴近可控 route adapter。 |
| Tavily | `time_range`、`start_date`、`end_date` | `include_domains`、`exclude_domains`、`topic` | `country` | `include_raw_content`、`include_answer` | 本轮默认关闭 answer/raw content。 |
| Brave Search API | `freshness` | query operators、endpoint、Goggles 可选 | `country`、`search_lang`、`ui_lang` | `count`、`extra_snippets` | 本轮第一轮不开 `extra_snippets`。 |
| Serper.dev | `tbs` | query operators、endpoint | `gl`、`hl`、`location` | `num`、`page` | 第一轮统一使用 `search` endpoint。 |

## 2. OpenAI Responses `web_search`

### 2.1 关键参数

| 参数 | 用途 | 本测试用法 |
|---|---|---|
| `search_context_size` | 控制搜索结果上下文量，取值通常为 `low` / `medium` / `high`。 | 固定 `medium`。 |
| `filters.allowed_domains` | 限定只从指定域名召回。 | `primary` / `community` 来源面使用。 |
| `filters.blocked_domains` | 排除指定域名。 | `web` 来源面排除官方和社区域名。 |
| `user_location` | 设置近似用户位置。 | CN / US 地域测试使用。 |
| `include: ["web_search_call.action.sources"]` | 返回 consulted URLs。 | 固定开启，便于审计。 |
| `external_web_access` | 控制 live access 或 cache-only。 | 默认不设置；需要可复现补测时再使用。 |
| `tool_choice` | 控制是否必须调用工具。 | 固定 `required`。 |

### 2.2 限制

- 没有显式 publish-date filter。
- 时间窗只能写入 prompt，并通过返回来源日期后验判断。
- `search_context_size` 不保证固定来源数量。
- `sources` 比 inline citations 更适合 search-round 审计。

## 3. Codex WebSearch baseline

### 3.1 关键能力

| 能力 | 用途 | 本测试用法 |
|---|---|---|
| `recency` | 相对时间过滤。 | `relative_15d` 使用 `recency=15`。 |
| `domains` | 域名过滤。 | 服务支持时用于 `primary` / `community` 来源面。 |
| query / prompt 约束 | 绝对日期、地域、来源面软约束。 | `absolute_may` 和地域控制使用。 |

### 3.2 限制

- 这是当前 Codex 会话能力 baseline，不是稳定外部 API adapter。
- 工具返回结构和参数能力由当前环境决定。
- 绝对时间窗需要后验判断。

## 4. Exa / AgentReach

### 4.1 关键参数

| 参数 | 用途 | 本测试用法 |
|---|---|---|
| `startPublishedDate` | 发布日期起点。 | 两个时间窗都使用。 |
| `endPublishedDate` | 发布日期终点。 | 两个时间窗都使用。 |
| `startCrawlDate` | Exa crawl / discover 日期起点。 | 作为可选补测。 |
| `endCrawlDate` | Exa crawl / discover 日期终点。 | 作为可选补测。 |
| `includeDomains` | 限定域名。 | `primary` / `community` 来源面使用。 |
| `excludeDomains` | 排除域名。 | `web` 来源面使用。 |
| `category` | 垂直类别，如 `news`、`research paper`、`company`、`personal site` 等。 | 本轮不作为硬过滤主轴，只记录可用性。 |
| `contents.highlights` | 返回 query-relevant snippets。 | 优先使用。 |
| `contents.text` | 返回正文文本。 | 第一轮默认不开。 |

### 4.2 限制

- 地域控制主要靠 query / prompt。
- 部分 `category` 与日期、domain 参数可能不能任意组合，实测时要记录失败或降级。
- AgentReach 路由如果只暴露部分 Exa 参数，需要以实际工具能力为准。

## 5. Tavily

### 5.1 关键参数

| 参数 | 用途 | 本测试用法 |
|---|---|---|
| `time_range` | 相对时间，如 day/week/month/year。 | 本轮主测 `start_date` / `end_date`，`time_range` 作为可选对照。 |
| `start_date` | 绝对日期起点。 | 两个时间窗都使用。 |
| `end_date` | 绝对日期终点。 | 两个时间窗都使用。 |
| `country` | 国家偏好。 | CN / US 地域测试使用。 |
| `topic` | `general` / `news` / `finance` 等。 | 固定 `general`。 |
| `include_domains` | 限定域名。 | `primary` / `community` 来源面使用。 |
| `exclude_domains` | 排除域名。 | `web` 来源面使用。 |
| `include_raw_content` | 返回正文内容。 | 第一轮固定 `false`。 |
| `include_answer` | 返回工具合成答案。 | 第一轮固定 `false`。 |

### 5.2 限制

- `topic` 来源分类粒度少，不等于 workflow 的 `primary/community/web`。
- `include_answer` 是 synthesis，不应作为事实证据直接写入 search round。
- `country` 的适用范围和强度需以实测结果为准。

## 6. Brave Search API

### 6.1 关键参数

| 参数 | 用途 | 本测试用法 |
|---|---|---|
| `freshness` | 相对或绝对时间过滤。 | 两个时间窗都使用，优先自定义日期范围。 |
| `country` | 国家。 | CN / US 地域测试使用。 |
| `search_lang` | 搜索结果语言。 | CN 用 `zh`，US 用 `en`。 |
| `ui_lang` | response metadata / UI language。 | CN 用 `zh-CN`，US 用 `en-US`。 |
| `count` | 返回结果数。 | 第一轮使用默认。 |
| `extra_snippets` | 每条结果额外 snippets。 | 第一轮不开。 |
| query operators | `site:`、`-site:`、引号等。 | 来源面控制主手段。 |

### 6.2 限制

- 没有 Exa 式 `category`。
- 来源面主要靠 query operators 和后验判断。
- 自定义 `freshness` 日期格式需要实测确认；失败时记录 fallback。

## 7. Serper.dev

### 7.1 关键参数

| 参数 | 用途 | 本测试用法 |
|---|---|---|
| `gl` | Google country。 | CN / US 地域测试使用。 |
| `hl` | Google language。 | CN 用 `zh-cn`，US 用 `en`。 |
| `location` | 位置字符串。 | CN 用 `China`，US 用 `United States`。 |
| `num` | 返回数量。 | 第一轮使用默认。 |
| `page` | 分页。 | 第一轮不主动分页。 |
| `tbs` | Google search tools 参数，常用于时间过滤。 | 两个时间窗都使用。 |
| query operators | `site:`、`-site:`、引号等。 | 来源面控制主手段。 |

### 7.2 `tbs` 时间参数

`relative_15d`：

```text
qdr:d15
```

`absolute_may`：

```text
cdr:1,cd_min:05/01/2026,cd_max:05/31/2026
```

### 7.3 限制

- `tbs` 是否完全透传并稳定生效需要实测确认。
- 来源面控制主要靠 Google query operators。
- 第一轮统一用 `search` endpoint，不用 `news` endpoint。

## 8. SerpAPI

本轮不测。

原因：注册不可用。

如果后续恢复可用，应另行补充参数能力，不混入本轮基线。
