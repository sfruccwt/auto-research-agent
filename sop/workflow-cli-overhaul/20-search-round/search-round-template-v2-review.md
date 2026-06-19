# Search round v2 中文模板

> 这份文件说明新版 `sources/search-round-N.md` 怎么写。它只记录“上一轮搜索”：本轮为什么搜、搜到了什么、证据能支撑什么、本轮还有什么缺口。全局研究状态和最终下一步编排交给 `research-state`。

## 总体规则

| 规则 | 说明 |
|---|---|
| 不写 metadata | run id、round id、时间、作者等可由路径、文件名、log 或 seal 机制提供；模板正文不单独维护。 |
| 不做全局判断 | 本文件只判断本轮 `search_intent`；原始问题整体进展由 `research-state.global_progress` 维护。 |
| 先结论后审计 | `search_intent` 后直接写 `key_findings`；查询和来源清单放到最后的审计附录。 |
| 证据来源放本轮 | 官方 / 学术 / 新闻 / 社区等来源依据在本文件说明；不单独维护证据强度字段。 |
| 不写 review packet | 给用户呈现什么应单独设计，可能同时使用 search round 和 research-state。 |

## search_intent

| 字段 | 怎么填 |
|---|---|
| `question` | 本轮要回答的自然语言问题，不写裸 query。 |
| `linked_state_gap` | 来自 `research-state` 的哪个可搜索缺口；没有写 `n/a`。 |
| `why_this_round` | 为什么现在查这个问题；用 1 句话说明。 |
| `out_of_scope_this_round` | 本轮明确不查什么，防止扩散。 |
| `stop_when` | 本轮搜到什么程度可以停。这是执行前口径，不是结果判断。 |

## key_findings

`key_findings` 要紧扣 `search_intent.question`，按回答逻辑排序，不按搜索顺序堆材料。

建议顺序：

1. 先写直接回答 search intent 的发现。
2. 再写补充机制、条件、边界。
3. 最后写反例、限制、未证实内容。

| 字段 | 怎么填 |
|---|---|
| `finding` | 主要发现。可以写成短段落，不限制为一句话；不要为了简短牺牲必要论证。 |
| `brief_reasoning` | 简要论证：为什么这些来源能推出这个发现，或它与 search intent 的关系是什么。 |
| `answers_part` | 它回答 search intent 的哪一部分。 |
| `evidence_basis` | 支撑它的来源类型或来源编号，例如 `official_or_primary`、`academic`、`community_or_cases`、`[1]`。 |
| `limit` | 主要限制；没有写 `n/a`。 |

示例格式：

| finding | brief_reasoning | answers_part | evidence_basis | limit |
|---|---|---|---|---|
| 官方文档确认该接口支持 JSON Schema 约束，但这个约束主要作用在字段形状和 schema 合规性上。 | 官方文档直接描述 JSON Schema 约束机制，因此可以回答“能否限制字段形状”；但文档没有声称它能保证字段内事实永远正确。 | 是否能限制字段形状 | official_or_primary, [1] | 不能证明字段内容一定事实正确。 |

## round_answer

判断本轮 search intent 被回答到什么程度。

| 字段 | 怎么填 |
|---|---|
| `status` | `answered`、`partially_answered`、`not_answered`、`reframed`。 |
| `short_answer` | 本轮对 search intent 的短回答。即使只部分回答，也要写当前能说什么。 |
| `enough_for_this_round` | 本轮证据足够支持什么。 |
| `not_enough_for_this_round` | 本轮证据不足以支持什么。 |
| `why_not_enough` | 如果不是 `answered`，写缺什么；否则写 `n/a`。 |
| `remaining_gaps` | 本轮未解决项，按 `searchable`、`user_only`、`deferred`、`blocked` 分类；没有写 `[]`。 |
| `suggested_handling` | 对这些未解决项的处理建议：`search_next`、`ask_user`、`defer`、`pivot`、`child_run`、`none`。 |

注意：这里的 enoughness 只针对本轮 search intent，不判断整个 run 是否可以收口。

## source_and_route_log

来源与路由记录放后面。快速阅读时可以跳过；需要复核本轮怎么搜、查到哪些来源、哪些通道受限时再看。

### queries_and_sources

记录本轮实际查了什么。

| 来源面 | 检索通道 | 查询 / 入口 | 来源标题 | URL / 路径 | 日期 | 备注 |
|---|---|---|---|---|---|---|
| official_or_primary | agent-reach:web / browser:iab-dom |  |  |  |  |  |

来源面可用值：

| 值 | 含义 |
|---|---|
| `official_or_primary` | 官方、一手、原文、文档、合同、源码等。 |
| `academic` | 论文、survey、benchmark、学术资料。 |
| `market_or_news` | 新闻、公告、产品页、市场信息。 |
| `community_or_cases` | 社区经验、issue、投诉、案例。 |
| `local_or_user_materials` | 用户文件、本地材料、已有 run。 |
| `other` | 其他来源。 |

检索通道可用值：

| 值 | 含义 |
|---|---|
| `agent-reach:search` / `agent-reach:web` | agent-reach 搜索或网页读取。 |
| `agent-reach:social` / `agent-reach:dev` / `agent-reach:video` | 社交、开发平台、视频平台检索。 |
| `browser:iab-dom` / `browser:iab-js` / `browser:iab-text` | in-app browser DOM / JS / text 路径。 |
| `browser:iab-screenshot` | in-app browser 截图 / 视觉路径。 |
| `browser:chrome-auth` | Chrome 登录态路径。 |
| `browser:google` / `browser:bing` / `browser:site-search` | 浏览器搜索入口。 |
| `browser:skipped` | browser lane 跳过，必须在 route notes 说明原因。 |
| `local:file` | 本地文件。 |

### source_notes

记录关键来源对本轮判断的作用。

| 来源编号 | 来源 | 来源层级 | 说明了什么 | 对本轮判断的作用 | 限制 |
|---|---|---|---|---|---|
| [1] |  | official / primary / academic / market / community / local |  | supports / contradicts / context / friction_signal |  |

填写要求：

| 要求 | 说明 |
|---|---|
| 只写关键来源 | 不需要每个搜索结果都写。 |
| 能对应 key_findings | `对本轮判断的作用` 应能支撑前面的 `key_findings.evidence_basis`。 |
| 限制要具体 | 例如无日期、样本少、旧版本、登录态、转述。 |

### route_notes

记录工具、浏览器和 lane 层面的限制。

| 字段 | 怎么填 |
|---|---|
| `agent_reach_lane` | 是否完成；如果 skipped / partial，说明原因。 |
| `browser_route_lane` | 是否完成；使用 in-app browser、Chrome extension、screenshot、site search 的原因。 |
| `fallbacks` | 是否发生 fallback，为什么。 |
| `personalization_or_login` | 是否使用登录态、个性化结果或用户 Chrome。 |
| `raw_output_handling` | 确认原始工具输出没有进入 run 文档，只保留压缩结果。 |

必须记录的情况：

| 情况 | 要求 |
|---|---|
| 使用 `browser:chrome-auth` | 说明为什么 in-app browser 不适用。 |
| 使用 screenshot / vision | 说明为什么 DOM / text 不够。 |
| 遇到站点风控、扫码、授权缺失、backend 不可用 | 说明影响了哪个来源面。 |
| browser lane skipped | 说明是 backend / 授权 / 连接问题，还是单个目标站点无法访问。 |

### references

最终参考来源列表。

| 字段 | 怎么填 |
|---|---|
| 编号 | 与 `source_notes` 中的来源编号一致，例如 `[1]`。 |
| 作者 / 机构 | 没有写 `unknown`。 |
| 标题 | 来源标题。 |
| 日期 | 来源日期；没有写 `日期不明` 或访问日期。 |
| URL / 路径 | 网页 URL 或本地路径。 |

示例：

```markdown
[1] OpenAI. "Structured Outputs." 2025.
    URL: https://platform.openai.com/docs/...
```

## 与 research-state 的边界

| 内容 | 写入位置 |
|---|---|
| 本轮为什么搜 | `search-round-N.search_intent` |
| 本轮发现什么 | `search-round-N.key_findings` |
| 本轮 search intent 是否回答 | `search-round-N.round_answer` |
| 本轮证据来源与限制 | `search-round-N.key_findings` 与 `search-round-N.round_answer` |
| 本轮产生的新 gap | `search-round-N.round_answer.remaining_gaps` |
| 当前全局状态 | `research-state.global_progress` |
| 下一步最终编排 | `research-state.next_step` |
