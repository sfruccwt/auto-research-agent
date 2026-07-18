# SOP Backlog

## 待改进

- [ ] 修正 active 指令中的旧 gate 规则残留（2026-06-12）
  - 背景：SOP v0.8 已经把新 run 主线改为 `research-state.md` + `state-history/`，但 `AGENTS.md` 仍残留 `task-card.md -> opening`、`judgment.md -> midway` 的旧流程过门说明。
  - 改进方向：将 active 指令同步到 `research-state.md`、`research-state-opening.md`、`output.md` 两个 queue gate；明确 `midway` 只作为 legacy gate。
  - 纳入范围：`sop/tasks/workflow-cli-tooling-overhaul-plan.md` 阶段 0。
- [ ] 修复 `scan-and-align.ps1` 的 Windows PowerShell 路径拼接兼容问题（2026-06-12）
  - 背景：当前脚本扫描 `runs/*/notes/derived-ideas.md` 时，`Join-Path` 多参数写法会在 Windows PowerShell 下报错，导致 JSON 输出混入错误信息。
  - 改进方向：改成兼容 PowerShell 5.1 / 7 的嵌套路径拼接，并增加 smoke test。
  - 纳入范围：`sop/tasks/workflow-cli-tooling-overhaul-plan.md` 阶段 0。
- [ ] CLI 化后增加 gate artifact / state consistency 校验（2026-06-12）
  - 背景：当前 `Update-QueueGate` 只负责写 queue 和 log，不校验标志产物；这在现有脚本定位下是正常的，但当 workflow 总控升级为 CLI 后，需要把固定 gate 条件移到脚本层。
  - 改进方向：新增 `ara run validate` / `ara run gate`，校验 `research-state.md`、`state-history/`、`search-round-N.md` 和 `output.md` 的存在性与基础一致性。
  - 纳入范围：`sop/tasks/workflow-cli-tooling-overhaul-plan.md` 阶段 2。
- [ ] in-flight queue 增加 audit / repair 机制（2026-06-12）
  - 背景：当前 queue 中存在 legacy `midway` 和 `current_gate = done` 但仍在 in-flight 的记录。直接迁移风险较高，但 CLI 总控需要先能报告这些异常。
  - 改进方向：先新增只读 audit，报告 queue、log、run dir、active artifacts 的不一致；repair 命令后续单独设计并默认 dry-run。
  - 纳入范围：`sop/tasks/workflow-cli-tooling-overhaul-plan.md` 阶段 1 / 阶段 7。
- [ ] 工具上下文隔离不能只依赖检索子 agent（2026-06-12）
  - 背景：实际使用中观察到检索子 agent 不一定触发；子 agent 内部调用 in-app browser / browser route lane 等工具时可能报错；复杂检索或动态网页检索容易超时。
  - 改进方向：保留子 agent 作为默认隔离路径，同时设计工具侧 reader / wrapper / adapter 隔离；母 agent 直接搜索只作为最后 fallback，并必须记录原因。
  - 纳入范围：`sop/tasks/tool-context-isolation-plan.md` 与 `sop/tasks/workflow-cli-tooling-overhaul-plan.md` 阶段 4。
- [ ] 调整 `search-round-N-human.md` 的发现颗粒度（2026-06-10）
  - 背景：现有 human companion summary 已解决“queries/source_notes/state_delta 不适合放在阅读主位”的问题，但当前写法过度压缩，发现颗粒度不如审计版 `search-round-N.md` 的 `key_findings` 合适。
  - 观察：审计版 key findings 的颗粒度更接近理想状态：每个发现能独立说明一个机制、边界或可行动判断；human 版不应把这些压成泛泛摘要。
  - 改进方向：human 版保留“问题驱动组织、来源放后、去掉检索/状态表”的结构，但每个“本轮发现”应继承审计版 key finding 的信息密度和论证颗粒度。
  - 模板候选：在 `sop/template-search-round-human.md` 中增加约束：不要低于审计版 key findings 的解释密度；每个发现至少包含机制/边界/例子/结论之一，避免只写一句抽象概括。
  - 触发案例：`runs/2026-06-10-cli-skill-reuse-principle/sources/search-round-*-human.md` 相比对应 `search-round-*.md` 更易读，但牺牲了部分关键发现的颗粒度。

## 已改进

- [x] 为每轮 search round 增加面向人阅读的 companion summary（2026-06-10，文档层已实施）
  - 背景：现有 `sources/search-round-N.md` 模板适合 AI 维护状态和追踪来源，但对人阅读不友好；`queries_and_sources`、`source_notes`、`search_round_summary` 更像检索日志和状态机记录，不应放在阅读主位。
  - 决策：每轮强制生成 `sources/search-round-N-human.md`，与 `sources/search-round-N.md` 成对出现。
  - 模板：新增 `sop/template-search-round-human.md`；结构为“本轮问题 → 本轮发现 → 这一轮读完后的简要结论 → 来源 → 检索日志”。
  - 边界：human 文件内容优先、来源附属；不搬运 gaps / state delta，不替代 `research-state.md`。
  - 范围：不回填历史 run；本次不同步 `CLAUDE.md`。
  - 触发案例：`runs/2026-06-10-cli-skill-reuse-principle/sources/search-round-1.md` 中 Codex/Claude/Gemini CLI 命令比较、CLI 可复用性机制、MCP 协议边界混在 key findings 中，读者难以建立结构。
- [x] Research state / slot lifecycle 接入 SOP（2026-06-01，文档层已实施）
  - 目标：把 slot 从 opening clarification 字段升级为贯穿 run 的 `research-state.md`，并让每轮搜索产生 `search_round_summary.state_delta`。
  - 任务文档：`sop/tasks/research-state-slot-lifecycle.md`
  - 迁移计划：`sop/tasks/research-state-slot-lifecycle-migration-plan.md`
  - 测试方案：`sop/tasks/research-state-slot-lifecycle-test-cases.md`
  - 来源 run：`runs/2026-05-24-llm-web-search-principles-auto-research-optimization/sub/research-agent-sop-design-patterns/`
- [x] 开题卡：关键词压测（FR-120，2026-05-10）
- [x] 搜索路径：社区/案例面默认开 agent-reach 路搜索（FR-115，2026-05-10）
- [x] Motivation 持续捕获机制（FR-116，2026-05-10）
- [x] 路径定义清晰度（FR-122，2026-05-10）
- [x] 备忘录/产出物的核心概念必须展开（FR-117 + FR-121，2026-05-10）
- [x] 备忘录 vs output 文件区分（FR-119，2026-05-10）
- [x] 不可靠信息直接删除，不展示（FR-118，2026-05-10）
- [x] 备忘录模板增加"关键概念展开"区块（FR-117e，2026-05-10）
- [x] 开题卡迭代式填写（FR-114，2026-05-10）
- [x] 子课题拆分检查（FR-120a，2026-05-10）
- [x] 子课题拆分触发位置前移（2026-05-14，改为持续触发 + 中途门兜底）
- [x] 搜索笔记/来源记录时机（2026-05-14，改为全阶段来源标注规则）
- [x] 产出后追问/补查机制（2026-05-14，log 记 amendment 事件，轻量处理）
- [x] 关键词探针阶段——移除，搜索方向调整是正常行为（2026-05-14）
- [x] usefulness 判断模式提炼——移至 context-infrastructure 工作区（2026-05-14）
