# Browser 搜索双轨路由修改方案

## 0. 背景与当前结论

当前研究 runner 的检索路由是文档/SOP 规则型路由，不是代码里的独立 router：

- `AGENTS.md` / `CLAUDE.md` 注入硬规则：所有检索默认加载并使用 `agent-reach`，不直接调 `WebSearch`。
- `sop/stages/0-global.md` 解释搜索工具选择，并规定 `agent-reach` 的使用方式。
- `sop/stages/2-research.md` 规定 `research-state.md` 只记录来源面和搜索意图，不记录工具路由。
- `sop/template-search-round.md` 记录每轮搜索的查询、来源和发现，但当前没有单独记录“检索通道”。
- 文档层静态检查需要覆盖当前双轨路由规则，避免回退到 `agent-reach` 单线表述。

已实测 Chrome extension backend 能复用用户 Chrome profile 的登录态。即使用户关闭原有知乎/小红书 tab，runner 新开 Chrome extension tab 仍可使用已登录状态进入站内搜索，并读取搜索结果列表。

因此，这次改动不是新增一个代码 router，而是修改全局检索规则、SOP、搜索轮次模板和文档层测试，让 runner 对所有检索动作都强制形成“`agent-reach` 主线 + browser search 辅助线”的双轨检索。只有 browser 工具损坏或不可用时，才记录 browser lane fallback / skipped。

## 1. 修改计划

### 1.1 目标路由

把现有“`agent-reach` 单主线检索”改成强制“`agent-reach` + browser search 双轨检索”：

1. `agent-reach` 仍是必跑主线，负责覆盖 search / web / dev / social / video 等平台化入口。
2. 所有检索动作都必须额外启用 browser search lane。
3. browser search lane 使用 Chrome extension backend，优先复用用户 Chrome 登录态。
4. browser search lane 可执行 Google / Bing / 站内搜索，并把结果与 `agent-reach` 结果合并判断。
5. `research-state.md` 继续不记录工具路由；具体用了哪些检索通道，记录到 `sources/search-round-N.md`。

### 1.2 执行流程

研究 run 进入搜索阶段后，按以下流程执行：

1. 先根据 `research-state.md` 或 opening 阶段产物确认本轮要打开的来源面，例如官方/原始、市场/新闻、学术、社区/案例。
2. 对每个来源面启动 `agent-reach lane`，按 `agent-reach` 路由表选择 search / web / dev / social / video 等具体入口。
3. 同一轮强制启动 `browser-search lane`，使用 Chrome extension backend 新开临时 tab，执行 Google / Bing / 站内搜索之一或组合。
4. 即使本轮主题是官方文档、论文、法规或已知 URL，也要用 browser lane 做一次人类搜索入口复核；查询可以更窄，例如站点名 + 标题、URL 片段、官方文档名。
5. 访问公共 Google / Bing 可默认只读启用；复用用户登录态的站内搜索必须有目标域名级授权。未授权时不尝试绕过，改用公共搜索引擎 browser lane，并把目标站内搜索写成 `browser:skipped - auth not granted`。
6. 将两条 lane 的结果写入同一份 `sources/search-round-N.md`，并在 `queries_and_sources` 表里标明 `检索通道`。
7. 在 `key_findings` 和 `search_round_summary.state_delta` 中说明两条 lane 是否互相印证、互相冲突、或带来新增缺口。
8. 只有 Chrome/browser backend 损坏或不可用时，整条 browser lane 才能写成 `browser:skipped` 或 fallback；目标站内搜索缺少授权时，只跳过该站内搜索子项，并改用公共 Google / Bing 完成 browser lane。

### 1.3 强制执行与 fallback 规则

强制执行 browser search lane：

- 所有检索动作都必须有 browser search lane 记录。
- 常规路径至少跑 Google 或 Bing 之一。
- 对社区/案例、一线经验、市场舆情、登录态站点、动态渲染站点、站内搜索类问题，应优先考虑站内搜索或目标平台页面。
- 对官方文档、论文、法规、已知 URL 类问题，也要通过 browser lane 做人类搜索入口复核。

整条 browser lane 允许 fallback / skipped 的情况只限：

- Chrome extension backend 不可用、连接失败或工具损坏。

fallback / skipped 时必须记录原因，例如：`browser:skipped - Chrome extension unavailable`、`browser:skipped - auth not granted`。

目标站内搜索子项允许 skipped 的情况：

- 目标站内搜索需要登录态或域名授权，但当前未授权。
- 此时不能跳过整个 browser lane，必须改用公共 Google / Bing，并且只把目标站内搜索子项记录为 `browser:skipped - auth not granted`。

登录态站内搜索的授权规则更严格：

- Google / Bing 等公共搜索引擎可默认只读启用。
- 知乎、小红书、LinkedIn、Gmail、内部系统等复用登录态的站内搜索，必须已有目标域名级授权或用户在当前任务中明确授权。
- 未授权时记录 `browser:skipped - auth not granted`，不得通过其他浏览器方式绕过。

### 1.4 安全边界

browser search lane 默认只读：

- 允许：打开新 tab、搜索、点击搜索结果、滚动、读取页面文本、读取标题/作者/摘要/链接、截图辅助判断。
- 不允许：发帖、评论、点赞、收藏、关注、私信、下载敏感文件、修改账号设置、提交表单、购买/支付。
- 遇到登录、验证码、权限确认、App 扫码、支付或隐私区域时暂停并告知用户。
- 不读取或总结私信、通知、账号设置、支付信息、密码、密钥、Cookie/localStorage/sessionStorage。

### 1.5 非目标

- 不恢复直接调用通用 `WebSearch` 作为默认主线。
- 不把搜索路由写进 `research-state.md` 的 slot。
- 不要求每个问题都跑 Google + Bing + 站内搜索全套；强制的是至少有一个 browser search lane。
- 不承诺所有站点详情页都能稳定读取。小红书等平台可能对网页详情页做风控或要求 App 扫码。

## 2. 实施细节

### 2.1 分支与工作边界

建议新建分支：

```text
codex/browser-search-route
```

当前仓库已有 dirty worktree。实施前应先确认哪些变更属于当前任务，避免把既有无关改动混入 PR。

本次实施只改文档和文档层测试，不新增运行时代码。

### 2.2 `AGENTS.md`

修改 `## 硬规则：搜索工具`：

- 保留“所有检索必须加载并使用 `agent-reach`，不要直接调 `WebSearch`”。
- 新增“所有检索必须额外启用 browser search lane；只有 Chrome/browser backend 损坏或不可用时才允许整条 browser lane fallback / skipped”。
- 说明 browser lane 使用 Chrome extension backend，可复用登录态。
- 明确 browser lane 只读，失败时记录 skipped/fallback。
- 更新子 agent prompt 要求。

子 agent prompt 规则从单句：

```text
加载并使用 agent-reach skill 搜索，不要直接调 WebSearch
```

扩展为两句：

```text
加载并使用 agent-reach skill 搜索，不要直接调 WebSearch。
同时强制使用 Chrome browser search lane 做 Google / Bing / 站内搜索之一或组合；只读，不操作账号状态。只有 Chrome/browser backend 损坏或不可用时，才记录 browser:skipped/fallback 及原因。
```

### 2.3 `CLAUDE.md`

与 `AGENTS.md` 同步修改，保持 Codex 与 Claude Code 的搜索路由规则一致。

### 2.4 `sop/stages/0-global.md`

重写“搜索工具选择”小节，建议结构：

```markdown
## 搜索工具选择

### 硬规则

### 双轨检索

### Browser search lane 强制规则

### Browser search lane fallback 条件

### Browser search lane 安全边界

### 子 agent 搜索规则
```

关键内容：

- `agent-reach lane` 是必跑主线。
- `browser-search lane` 也是必跑辅助线。
- `WebSearch` 仍不是默认工具。
- browser lane 的结果需要标注登录态/个性化可能性。
- Chrome backend 不可用时记录 skipped/fallback，不阻塞主线。

### 2.5 `sop/stages/2-research.md`

在“检索面设计”中补充：

- `research-state.md` 只记录来源面和搜索意图，不记录工具通道。
- 每轮实际使用的工具通道写入 `sources/search-round-N.md`。
- 每轮搜索都应在 `search_round_summary.state_delta` 中说明 browser lane 是否改变了 slot / facet；没有新增也要写明未改变。
- browser lane 产生的个性化、登录态或站点风控限制，写入 `source_notes`。

### 2.6 `sop/template-search-round.md`

把 `queries_and_sources` 表从：

```markdown
| 来源面 | 查询 / 入口 | 来源 | 备注 |
|---|---|---|---|
```

改为：

```markdown
| 来源面 | 检索通道 | 查询 / 入口 | 来源 | 备注 |
|---|---|---|---|---|
```

`检索通道` 建议枚举：

- `agent-reach:search`
- `agent-reach:web`
- `agent-reach:social`
- `agent-reach:dev`
- `agent-reach:video`
- `browser:google`
- `browser:bing`
- `browser:site-search`
- `browser:skipped`

### 2.7 `sop/template-task-card.md`

不修改。该模板现在是 legacy import 用途，不恢复为新 run 的 active artifact；本次强制双轨规则只落在 `AGENTS.md` / `CLAUDE.md` / SOP / `template-search-round.md` / 测试断言里。

### 2.8 `sop/tasks/research-state-slot-lifecycle.md`

只做最小文字调整：

- 保持“不新增 `search_plan.tool_routing`”。
- 把“默认检索工具规则由 `AGENTS.md` 注入：所有检索加载并使用 `agent-reach`”更新为“强制双轨规则由 `AGENTS.md` 注入；`research-state` 不记录工具路由”。

### 2.9 `sop/tasks/research-state-slot-lifecycle-test-cases.md`

同步测试说明：

- `工具分配` 仍不迁入 slot。
- 默认检索规则仍由 `AGENTS.md` 负责。
- 新规则是强制 `agent-reach` 主线 + browser search 辅助 lane。

### 2.10 静态文档检查

检查项：

- `research-state` 模板仍不包含 `tool_routing`。
- lifecycle task doc 仍说明不把工具路由放进 `research-state`。
- task doc 包含 `agent-reach`。
- task doc 包含 `browser search` 或 `browser-search`。
- `AGENTS.md` 包含强制双轨规则。
- `CLAUDE.md` 包含强制双轨规则。
- `AGENTS.md` / `CLAUDE.md` 仍保留“检索子 agent 不调用 `new-run.ps1`，直接返回搜索结果”的 run 边界。
- `sop/stages/0-global.md` 包含 `browser-search lane`。
- `sop/stages/0-global.md` 明确 browser search lane 是强制动作。
- `sop/stages/0-global.md` 明确整条 browser lane fallback 只限 Chrome/browser backend 损坏或不可用。
- `sop/template-search-round.md` 包含 `检索通道`。
- `sop/template-search-round.md` 包含 `browser:google`、`browser:bing`、`browser:site-search`、`browser:skipped`。
- `sop/template-search-round.md` 保留 `source_notes`，用于记录登录态、个性化或站点风控限制。

### 2.11 `sop/backlog.md`

`sop/backlog.md` 有历史完成项记录“社区/案例面默认开 agent-reach 路搜索”。实施时二选一：

- 若保持 backlog 作为历史记录，不改原完成项，但在静态检查说明中把 historical backlog 标为豁免。
- 若希望减少误读，在该条后补一句“后续由 browser-search 双轨规则取代单线表述”。

## 3. 测试方案

### 3.1 静态文档检查

实施后运行：

```powershell
rg -n "browser-search|browser search|检索通道|agent-reach" AGENTS.md CLAUDE.md sop
```

验收点：

- `research-state` 模板仍不包含 `tool_routing`。
- lifecycle task 文档仍说明工具路由不进入 slot。
- 全局规则里能看到 `agent-reach`。
- 全局规则里能看到 `browser-search lane`，且明确它是强制动作。
- 全局规则明确整条 browser lane fallback 只限 Chrome/browser backend 损坏或不可用。
- search round 模板包含 `检索通道` 列。
- 原有 lifecycle 断言仍通过。

### 3.2 静态一致性检查

实施后运行：

```powershell
rg -n "browser-search|browser search|检索通道|agent-reach" AGENTS.md CLAUDE.md sop scripts
```

验收点：

- `AGENTS.md` 和 `CLAUDE.md` 都包含双轨规则。
- `AGENTS.md` 和 `CLAUDE.md` 都明确 browser search lane 是强制动作，而非可选动作。
- `sop/stages/0-global.md` 是最完整的规则说明。
- `sop/stages/2-research.md` 没有要求把工具路由写进 `research-state.md`。
- 没有残留表述把默认规则说成“只有 agent-reach 单线”。
- 历史 backlog / fixture 中的旧表述如需保留，必须明确是历史记录或 legacy fixture，不作为当前运行规则。

### 3.3 自执行 smoke test

实施者可以自派一个低风险模拟课题执行一轮搜索记录，不需要用户手动出题，也不需要正式投递：

- query 示例：`AI agent 落地案例`
- `agent-reach lane`：记录至少 2 条结果。
- `browser:google` 或 `browser:bing`：用 Chrome extension backend 打开 Google 或 Bing，记录至少 2 条结果。
- `browser:site-search`：用 Chrome extension backend 验证论坛/社区站点浏览或站内搜索能力，优先知乎和小红书，记录至少 2 条列表结果或可读帖子/回答结果。
- 如果详情页被风控，只记录列表页，并在 `source_notes` 说明限制。

用户手动参与不是必需项。只有要验收某个具体账号页面、具体私域登录态或用户关心的真实 query 时，才建议用户提供题目或授权目标域名；普通知乎/小红书站内搜索 smoke 由实施者自执行。

写入边界：

- 使用本仓库内 throwaway run 或 fixture 记录 smoke test。
- 不写 wiki inbox。
- 不修改 wiki idea 文件。
- 不投递测试产物。
- PR 前确认 smoke test 产物是保留为 fixture，还是清理掉。

验收点：

- `sources/search-round-N.md` 能区分 `agent-reach:*` 与 `browser:*`。
- browser lane 成功时必须产生结果；只有工具损坏、不可用或未授权目标站内搜索时，才能写成 `browser:skipped`，且不会阻塞主线。
- smoke test 同时覆盖商业搜索引擎和论坛/社区站点功能，不能只测 Google/Bing。
- 结果合并判断时能说明两条 lane 的一致点、冲突点和新增线索。

### 3.4 PR 前检查

PR 前确认：

- `git diff` 只包含本任务相关文件。
- 没有误改 wiki inbox、idea 文件或 run 产物。
- 没有把登录态、账号页面内容、私信/通知内容写入测试产物。
- 自执行 smoke test 产生的临时 tab 已关闭或释放。

## 4. 验收标准

- 文档规则从“agent-reach 单线”变成强制“agent-reach 主线 + browser search 辅助线”。
- 修改计划明确说明“为什么改、改成什么、何时 fallback”。
- 实施细节明确到文件级和关键句级。
- `research-state.md` 仍不承担工具路由职责。
- `sources/search-round-N.md` 能记录每条检索来自哪个通道。
- browser lane 有明确只读边界。
- 自动化文档测试通过。
- 至少一次 smoke test 证明双轨结果能被同一轮搜索记录承载。

## 5. 风险与处理

| 风险 | 处理 |
|---|---|
| Browser 结果受登录态和个性化影响 | 在 `source_notes` 标注 browser lane 与登录态/个性化可能性 |
| 小红书等站点详情页打不开 | 允许只记录搜索列表；详情页失败写明限制 |
| 双轨检索增加噪音 | 不跳过 browser lane；通过更窄 query、只记录高相关结果、在 `source_notes` 标注噪音来源来控制 |
| 子 agent 忘记 browser lane | 在母 agent prompt 规则中明确写入双轨要求 |
| 文档漂移 | 同步改 `AGENTS.md`、`CLAUDE.md`、SOP、模板和测试断言 |
