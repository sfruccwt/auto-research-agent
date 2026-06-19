# Workflow CLI 改造文档索引

状态：简化草案

## 0. 目的

这个目录记录 research runner 的新工作流方向：半自动研究，而不是无人值守的自动研究。

核心原则：

- 每个关键推进点都要给用户一个可审阅的 brief。
- LLM 负责理解、检索、归纳和提出下一步计划。
- 脚本只负责状态封账：`validate` / `snapshot` / `log` / `status` / `seal`。
- 脚本不自动调用 LLM，不连续执行 search round，不替用户批准下一轮。

## 1. 目录结构

| 目录 | 文档 | 用途 | 不做什么 |
|---|---|---|---|
| `00-overview/` | `workflow-cli-target-flow.md`、`workflow-cli-tooling-overhaul-plan.md`、`workflow-cli-use-scenarios.md` | 维护总流程、改造计划和用户使用场景 | 不展开阶段模板字段 |
| `10-opening/` | `opening-intake-split-prompt-v2-review.md`、`split-summary-template-v2-review.md`、`opening-note-template-v2-review.md`、`opening-brief-template-v2-review.md` | 维护 Opening 阶段的拆题、问题框架、首轮计划和用户审阅 brief | 不执行检索，不维护 search round 记录 |
| `20-search-round/` | `search-plan-and-route-design-review.md`、`search-round-template-v2-review.md` | 维护一轮检索的 query / route 设计和 search round 审计模板 | 不改 opening 模板字段 |
| `30-state-and-handoff/` | `research-state-template-v2-review.md`、`research-state-json-template.v2.json`、`workflow-cli-state-log-model.md`、`workflow-cli-taskpack-contract.md` | 维护跨阶段状态、JSON 模板、state/log/seal/handoff/review packet 边界 | 不替 LLM 推导语义，不替用户批准下一步 |
| `90-knowledge/` | `ai-search-tooling-knowledge-review.md`、`search-api-service-comparison.md`、`web-search-step-implementation-knowledge.md`、`how-to-draw-langgraph-workflow.md`、`langgraph-local-deployment-evaluation.md` | 保存支撑设计判断的工具知识、画图方法和部署评估 | 不作为执行规范反向覆盖阶段模板 |
| `verification/` | `codex-cli-log-probe/` 等验证材料 | 保存 probe 输出、日志样本和验证证据 | 不承载设计入口 |

## 2. 唯一流程图来源

流程图只审 `00-overview/workflow-cli-target-flow.md`。总流程、Opening node、Search round node、Round Review node、Program / Controller node、Memo / Output / Closing、Child Run / backfill 的图都统一维护在该文件。

其他文档只维护模板、字段、状态、路由、资料和实施说明，不再维护独立 Mermaid 流程图。

`90-knowledge/` 只保存背景知识和设计依据。它可以解释为什么这么设计，但不直接覆盖 `10-opening/`、`20-search-round/`、`30-state-and-handoff/` 里的阶段模板和运行契约。

## 3. 两类用户审阅 brief

### Opening brief

Opening 阶段展示用户意图和首轮检索计划。批准后写入 `notes/search-opening.md`。

如果原始输入混有多个可独立研究的主题，先用 `10-opening/opening-intake-split-prompt-v2-review.md` 拆出所有候选 run，再让用户决定是开多个平行 run，还是开一个母 run 并拆 child runs。每份 `10-opening/opening-note-template-v2-review.md` 仍只针对一个具体主题填写。

Opening 阶段的四份文档需要一起看：`10-opening/opening-intake-split-prompt-v2-review.md`、`10-opening/split-summary-template-v2-review.md`、`10-opening/opening-note-template-v2-review.md`、`10-opening/opening-brief-template-v2-review.md`。

`10-opening/opening-note-template-v2-review.md` 是内部待填写模板；`10-opening/opening-brief-template-v2-review.md` 是给用户展示的 brief 模板，并记录 brief 字段从 opening note 哪些字段抽取。

### Round N brief

每轮 search round 后展示本轮发现、enoughness 和下一轮建议。它是审阅视图，不要求新增独立文件；可由 `sources/search-round-N.md`、`sources/search-round-N-human.md` 和 `notes/research-state` 渲染得到。

最小字段：

- `original_intent`
- `previous_search_intent`
- `what_this_round_found`
- `enough_for`
- `not_enough_for`
- `state_changed`
- `remaining_gaps`
- `proposed_next_round`
- `recommendation`
- `user_decision_needed`

## 4. 命名约定

- `search-opening`：opening 批准后的首轮检索计划，路径为 `notes/search-opening.md`。它不是已执行检索记录。
- `search-round-N`：第 N 轮已执行检索的审计记录，路径为 `sources/search-round-N.md`。
- `proposed_next_round`：下一轮计划草案，必须进入用户审阅，不能自动执行。
- `seal opening` / `seal round`：脚本做结构校验、快照和日志封账，不做语义判断。

## 5. 不再采用的旧方向

- 不做全自动 search loop。
- 不把脚本设计成自动推进器。
- 不让脚本自动生成和推进 taskpack。
- 不把外部 deep research demo 的自动 follow-up query 机制直接搬进本项目。
- 不在 opening 阶段扩写完整变量图、证据策略或复杂 clarification taxonomy。
