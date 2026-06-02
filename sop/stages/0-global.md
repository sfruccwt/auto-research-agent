# 全阶段通用规则

> 每次进入新阶段时必须重读本文件。

---

## 来源标注

所有写入文档（notes/、sources/、output.md）的搜索结果都必须标注来源，格式：正文 inline 数字引用 `[1]`、`[2]` + 文末来源列表（含 URL）。

## 搜索工具选择

### 检索上下文隔离

所有检索动作必须通过检索子 agent 隔离执行，母 agent 默认不直接调用搜索或浏览器工具。这样 `agent-reach`、Chrome/browser 的原始工具返回留在子 agent 上下文里，母 agent 只接收可写入 `sources/search-round-N.md` 的压缩结果，避免长 run 反复携带原始搜索输出消耗上下文。

母 agent 每轮可选两种执行方式：

1. 派 1 个检索子 agent 同时跑 `agent-reach lane` 和 `browser-search lane`，由该子 agent 合并结果。
2. 同步派 2 个 lane 子 agent：一个跑 `agent-reach lane`，一个跑 `browser-search lane`，母 agent 只合并两个压缩返回。

子 agent 只能返回结构化压缩结果：查询 / 入口、标题 / 作者 / 日期 / URL、来源层级、1-3 句关键发现、冲突或新增缺口、`source_notes`、browser fallback / skipped 原因。母 agent 用这些结果填写现有 `queries_and_sources`、`key_findings`、`source_notes`、`search_round_summary.state_delta` 字段，不新增 search round 字段。禁止返回原始工具输出、长页面转储、无筛选搜索列表或大段引用。

如果当前环境没有可用 Agent / sub-agent 能力，可以 fallback 为母 agent 直接检索，但必须在 `source_notes` 或 `queries_and_sources.备注` 记录 `delegation:skipped - Agent tool unavailable`。这种 fallback 只用于继续推进 run；即便母 agent 被迫直接检索，也必须立即压缩，不得把原始工具输出写入 notes/、sources/ 或 output。

### 硬规则

所有检索动作必须走强制双轨：

1. `agent-reach lane`：加载并使用 `agent-reach` skill，不要直接调 WebSearch。
2. `browser-search lane`：使用 Chrome browser search lane 做 Google / Bing / 站内搜索之一或组合。

`agent-reach` 是 skill 名称，不是 slash command、外部命令或 MCP 服务名；执行时按该 skill 的路由表选择具体工具。

理由：agent-reach 覆盖 17 个平台（小红书、抖音、微博、Twitter、Reddit、GitHub、B 站、YouTube 等），能按检索面精准选择信源；browser search lane 复核人类搜索入口、商业搜索引擎结果、站内搜索和登录态页面，补足单一工具的盲区。

### 双轨检索

每轮搜索都必须记录两条 lane：

| lane | 作用 | 常见通道 |
|---|---|---|
| `agent-reach` | 主线覆盖多平台、多信源、结构化检索 | `agent-reach:search` / `agent-reach:web` / `agent-reach:social` / `agent-reach:dev` / `agent-reach:video` |
| `browser-search` | 模拟人类浏览器检索，复用 Chrome 登录态和站内入口 | `browser:google` / `browser:bing` / `browser:site-search` |

即使本轮主题是官方文档、论文、法规或已知 URL，也要用 browser lane 做一次人类搜索入口复核；查询可以更窄，例如站点名 + 标题、URL 片段、官方文档名。

### Browser search lane 强制规则

- 所有检索动作都必须有 browser search lane 记录。
- 常规路径至少跑 Google 或 Bing 之一。
- 对社区/案例、一线经验、市场舆情、登录态站点、动态渲染站点、站内搜索类问题，应优先考虑站内搜索或目标平台页面。
- browser lane 默认只读：允许搜索、点击结果、滚动、读取标题/作者/摘要/链接和页面文本；不允许发帖、评论、点赞、收藏、关注、私信、下载敏感文件、修改账号设置、提交表单、购买/支付。
- 复用用户登录态的站内搜索必须已有目标域名级授权或用户在当前任务中明确授权。

### Browser search lane fallback 条件

整条 browser lane 只有在 Chrome/browser backend 损坏、不可用或连接失败时，才能写成 `browser:skipped` 或 fallback，并必须记录原因。

目标站内搜索缺少授权时，不能跳过整条 browser lane；必须改用公共 Google / Bing 完成 browser lane，并且只把目标站内搜索子项记录为 `browser:skipped - auth not granted`。

### 结果记录

每轮搜索的 `sources/search-round-N.md` 仍使用现有模板字段记录结果。`queries_and_sources` 表中必须标明 `检索通道`，例如 `agent-reach:search`、`browser:google`、`browser:site-search`。browser lane 产生的登录态、个性化、站点风控限制或检索委托 fallback，写入 `source_notes` 或 `queries_and_sources.备注`。

### 子 agent 搜索规则

母 agent 派出检索子 agent 时，必须在 prompt 中显式写明：**"不要调用 new-run.ps1，直接返回搜索结果；加载并使用 agent-reach skill 搜索，不要直接调 WebSearch；同时强制使用 Chrome browser search lane 做 Google / Bing / 站内搜索之一或组合；只读，不操作账号状态；只返回结构化压缩结果和 URL 清单，不返回原始工具输出；只有 Chrome/browser backend 损坏或不可用时，才记录 browser:skipped/fallback 及原因。"** 子 agent 不会自动继承母 agent 读过的 SOP，必须在 prompt 里把关键约束带过去。

## 核心概念清晰描述

在任何阶段的产出中（搜索笔记、判断单、备忘录、output），遇到可能需要展开的术语时：
1. **标记**：标记出该术语
2. **确认**：向用户确认"这个概念需不需要展开"
3. **展开**（用户确认后）：一半严肃定义 + 一半类比或具体例子
4. **跳过**（用户确认不需要后）：继续推进

哪些概念需要展开，不硬性界定，随 run 次数增多逐步积累经验。
