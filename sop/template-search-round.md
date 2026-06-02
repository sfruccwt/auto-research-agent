# Search round 模板

> 作用：记录一轮搜索为什么发生、发现了什么、怎样改变 `research-state.md`。每轮搜索写一份 `sources/search-round-N.md`。

## search_intent

- 本轮为什么搜:
- 对应 state gap:
- 本轮不做什么:

## queries_and_sources

| 来源面 | 检索通道 | 查询 / 入口 | 来源 | 备注 |
|---|---|---|---|---|
| official_or_primary | agent-reach:web / browser:google / browser:bing |  |  |  |
| market_or_news | agent-reach:search / agent-reach:web / browser:google / browser:bing |  |  |  |
| academic | agent-reach:web / browser:google / browser:bing |  |  |  |
| community_or_cases | agent-reach:social / agent-reach:dev / browser:site-search / browser:google / browser:bing |  |  |  |

检索通道可用值：

- `agent-reach:search`
- `agent-reach:web`
- `agent-reach:social`
- `agent-reach:dev`
- `agent-reach:video`
- `browser:google`
- `browser:bing`
- `browser:site-search`
- `browser:skipped`

## key_findings

-
-
-

## source_notes

| 来源 | 说明了什么 | 来源层级 | 对当前判断的作用 |
|---|---|---|---|
|  |  | official / primary / market / academic / community |  |

> 如 browser lane 使用登录态、个性化结果、站内搜索，或遇到站点风控 / App 扫码 / 授权缺失，必须在这里记录。

## search_round_summary

### state_before

`notes/state-history/research-state-<stage-or-round>.md`

### state_delta

| slot / facet | before | after | resolution_state | update_reason |
|---|---|---|---|---|
|  |  |  |  |  |

### state_after

`notes/state-history/research-state-rNN.md`

### new_gaps

| 缺口 | 类型 | next_action | 说明 |
|---|---|---|---|
|  | searchable / user_only / deferrable | ask_user / search_next / defer |  |

### enoughness_current

- 当前证据足够支持什么:
- 当前证据不足以支持什么:
- 是否足够进入 memo:

### next_search_options

- continue_search:
- pivot:
- ask_user:
- write_memo:
- stop:

### agent_recommendation

`continue_search | pivot | ask_user | write_memo | stop`

### required_user_confirmation

-

## 依据

[1] 作者/机构. "标题." 年份.
    URL: example.com/path
