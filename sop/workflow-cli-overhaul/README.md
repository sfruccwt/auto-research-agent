# Workflow CLI 改造文档索引

状态：简化草案

## 0. 目的

这个目录记录 research runner 的新工作流方向：半自动研究，而不是无人值守的自动研究。

核心原则：

- 每个关键推进点都要给用户一个可审阅的 brief。
- LLM 负责理解、检索、归纳和提出下一步计划。
- 脚本只负责状态封账：`validate` / `snapshot` / `log` / `status` / `seal`。
- 脚本不自动调用 LLM，不连续执行 search round，不替用户批准下一轮。

## 1. 文档分层

| 类型 | 文档 | 用途 | 不做什么 |
|---|---|---|---|
| 系统总流程 | `workflow-cli-target-flow.md` | 说明一次 run 从启动到收口的半自动流转 | 不展开阶段内部字段 |
| 阶段流程 | `stage-startup.md` | 说明启动阶段如何保存 raw intake 并创建 run | 不做语义理解 |
| 阶段流程 | `stage-opening-clarification.md` | 说明 opening brief 和 `notes/search-opening.md` 如何产生 | 不执行搜索 |
| 阶段流程 | `stage-search.md` | 说明每轮 search round 如何执行、封账、进入用户审阅 | 不自动进入下一轮 |
| 阶段流程 | `stage-output-closing.md` | 说明 memo、output、done gate、deliver / close | 不回头定义搜索策略 |
| 局部设计 | `opening-clarification-technical-design.md` | 定义 opening brief 最小字段和写回边界 | 不扩写完整 schema |
| 局部设计 | `search-question-derivation-design.md` | 定义如何从 round 结果派生 `proposed_next_round` | 不自动执行下一轮 |
| 状态模型 | `workflow-cli-state-log-model.md` | 说明 state、snapshot、log、seal 的职责 | 不设计自动推进器 |
| 状态封账 | `workflow-cli-controller-technical-design.md` | 旧 controller 文档的降级版：state ledger / round sealer | 不调用 LLM |
| 交接契约 | `workflow-cli-taskpack-contract.md` | 定义可选 handoff packet / review packet 的最小边界 | 不作为自动执行协议 |
| 改造计划 | `workflow-cli-tooling-overhaul-plan.md` | 记录当前简化后的实施方向 | 不保留旧全自动路线 |
| 场景记录 | `workflow-cli-use-scenarios.md` | 记录用户启动、审阅、继续、收口场景 | 不定义最终流程 |

## 2. 四张核心流程图

本轮用户只审四张核心流程图：

1. 总流程图：`workflow-cli-target-flow.md`
2. Opening 阶段图：`stage-opening-clarification.md`
3. Search round 阶段图：`stage-search.md`
4. Search question 派生图：`search-question-derivation-design.md`

其他文档只跟随这四张图调整措辞和职责，不另设一套流程。

## 3. 两类用户审阅 brief

### Opening brief

Opening 阶段展示用户意图和首轮检索计划。批准后写入 `notes/search-opening.md`。

最小字段：

- `user_intent`
- `research_object`
- `operation_type`
- `scope_boundary`
- `use_intent`
- `output_shape / action_boundary`
- `source_surfaces`
- `first_search_questions`
- `stop_when`
- `temporary_or_default_fields`

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
