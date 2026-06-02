# 搜索子 agent 上下文隔离修改方案

状态：已实施（文档层）
创建时间：2026-06-02
分支：`codex/search-subagent-token-isolation`

## 背景

长 run 中，如果母 agent 直接执行多轮搜索，`agent-reach`、Chrome/browser 等工具返回会持续留在母 agent 上下文里。后续轮次只需要少量 URL、结论和缺口，但上下文仍携带大量原始搜索输出，造成无效 token 消耗。

已有路由规则已经明确：每轮检索必须走 `agent-reach lane` + `browser-search lane`。本次改动不改变双轨路由，而是在双轨之上新增“检索子 agent 隔离”层。

## 目标

- 每轮搜索默认由检索子 agent 执行，母 agent 不直接调用搜索或浏览器工具。
- 原始工具输出停留在检索子 agent 上下文里。
- 母 agent 只接收结构化压缩结果和 URL 清单，再写入 `sources/search-round-N.md` 的现有字段。
- `research-state.md` 继续只记录研究状态、来源面和搜索意图，不记录工具路由或检索执行日志。
- 不新增 search round 字段；子 agent 返回内容直接用于填写 `queries_and_sources`、`key_findings`、`source_notes`、`search_round_summary.state_delta`。
- 保留现有强制双轨：`agent-reach lane` + `browser-search lane`。

## 修改计划

### 1. 全局 agent 指令

文件：

- `AGENTS.md`
- `CLAUDE.md`

修改内容：

- 在“搜索工具”硬规则里新增：所有检索动作必须通过检索子 agent 隔离执行。
- 明确母 agent 可选两种执行方式：
  - 派 1 个检索子 agent 同时跑 `agent-reach lane` 和 `browser-search lane`。
  - 同步派 2 个 lane 子 agent，分别跑 `agent-reach lane` 和 `browser-search lane`。
- 更新检索子 agent prompt，强制写明：
  - 不调用 `new-run.ps1`。
  - 加载并使用 `agent-reach`，不直接调 WebSearch。
  - 强制使用 Chrome browser search lane。
  - 只读，不操作账号状态。
  - 只返回结构化压缩结果和 URL 清单，不返回原始工具输出。

### 2. 运行时 SOP

文件：

- `sop/stages/0-global.md`
- `sop/stages/2-research.md`

修改内容：

- 在全阶段规则里新增“检索上下文隔离”小节。
- 在阶段 2 的固定顺序中，把“委托检索子 agent”放到写 `sources/search-round-N.md` 之前。
- 明确 fallback：只有当前环境没有可用 Agent / sub-agent 能力时，才允许母 agent 直接检索；必须在 `source_notes` 或 `queries_and_sources.备注` 里记录 `delegation:skipped - Agent tool unavailable`，并且仍然不得把原始工具输出写入文档。

### 3. Search round 模板

文件：

- `sop/template-search-round.md`
- `sop/templates.md`

修改内容：

- 不新增字段。
- 保持 `sop/template-search-round.md` 的现有结构。
- 明确子 agent 返回的压缩结果直接填入现有字段：`queries_and_sources`、`key_findings`、`source_notes`、`search_round_summary.state_delta`。
- 如果 Agent / sub-agent 工具不可用，fallback 原因写入 `source_notes` 或 `queries_and_sources.备注`。

### 4. 任务说明和测试说明

文件：

- `sop/tasks/research-state-slot-lifecycle.md`
- `sop/tasks/research-state-slot-lifecycle-test-cases.md`

修改内容：

- 明确检索委托不迁入 `research-state.md`，也不新增 search round 字段。
- 检查 AGENTS / CLAUDE / SOP 都包含检索子 agent 隔离规则。

## 测试方案

### 1. 静态文档验证

运行：

```powershell
rg -n "retrieval_delegation|raw_tool_output_policy|execution_mode" AGENTS.md CLAUDE.md sop scripts --glob "!sop/tasks/search-subagent-token-isolation-plan.md"
```

验收点：

- 输出为空，说明没有残留新 search round 字段。
- `template-search-round.md` 不新增检索委托字段。

### 2. 静态一致性检查

运行：

```powershell
rg -n "检索子 agent|原始工具输出|browser-search|agent-reach|不新增 search round 字段" AGENTS.md CLAUDE.md sop
```

验收点：

- 所有 active 规则都指向“检索子 agent 隔离 + 强制双轨”。
- 没有 active 规则要求母 agent 直接执行搜索工具。
- 没有 active 规则要求新增 search round 字段。
- 旧模板和历史 fixture 中的“工具分配”只作为 legacy 记录存在。

### 3. PR 前检查

运行：

```powershell
git diff --check
git status --short
```

验收点：

- diff 不包含 wiki inbox、wiki idea 或 run 产物写入。
- 没有把账号态页面、私信、通知、Cookie、localStorage 等敏感内容写入文档。
- 只提交本任务相关文件；既有无关 dirty worktree 不混入提交。

## 非目标

- 不新增真实搜索 router 代码。
- 不改变 `new-run.ps1`、`Update-QueueGate` 或 queue schema。
- 不把检索工具路由写入 `research-state.md`。
- 不要求每轮同时跑 Google、Bing、站内搜索全套；强制的是至少有 browser search lane。
- 不把子 agent 的原始工具输出保存为 fixture。
