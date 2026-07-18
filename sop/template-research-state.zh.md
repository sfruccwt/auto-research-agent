# Research state 中文说明版

> 这份文件解释 `sop/template-research-state.md` 的字段含义。实际 run 里建议继续保留英文 key，方便后续迁移到 JSON Schema；中文说明用于人工阅读、review 和调试 opening、round、pre-memo 等各阶段的 state 更新。

## 总体规则

- 原始输入和派生判断必须分开：用户说过的话必须保真引用在 `original_user_words`，agent 的理解放在 `initial_topic`、`use_intent`、`objective`。
- 这份 state 贯穿整个 run：opening 建立第一版，round 后更新当前理解，pre-memo 前做最终充分性和动作边界 review。
- 缺口分三类处理：用户才能回答的高影响缺口先问；搜索能补的写进 `search_plan`；暂时不影响当前推进的标 `deferred`。
- 不使用空的 Markdown 子列表占位。未知写 `unknown`，不适用写 `n/a`，列表为空写 `[]`。

## 字段说明

### 元信息（metadata）

记录这份 state 属于哪个 run、处于哪个阶段、基于哪些输入生成。

- `run_id`：run 编号。
- `snapshot_stage`：当前状态类型，常见值是 `opening`、`round`、`pre-memo`。
- `snapshot_source`：这次 state 是手写、LLM 生成、legacy import，还是搜索轮次更新。
- `updated_at`：更新时间。
- `based_on`：这份 state 基于哪些 idea、search round、用户反馈。

### 来源上下文（origin_context）

保存问题从哪里来，避免后面忘记用户原始意图。

- `initial_topic`：从原始输入抽取出的短标题。它是 agent 的标题化理解，不是用户原话。
- `original_user_words`：用户原始输入。必须保真引用，不改写、不总结；过长时保留关键原句，并指向完整 `idea.md`。
- `problem_source`：问题来源，例如用户口述、wiki idea、已有 run、外部材料。
- `known_context`：进入本次 state 更新前已经成立、会约束理解的稳定背景。opening 时是开题前背景；round 后可以吸收已经确认的背景或用户补充，但不承载下一轮搜索的临时任务。
- `existing_materials`：已有材料路径或 URL。
- `user_feedback`：run 过程中用户补充、修正、确认或否定的内容。

### 研究形状（inquiry_shape）

把模糊主题整理成可搜索的问题形状。

- `research_object`：研究对象，例如某个工具、制度、合同、工作流、地点。
- `operation_type`：研究动作，例如比较、解释、验证、诊断、选型、规划、写作。
- `candidate_paths`：当前可能比较的路径、方案或动作。
- `key_terms`：当前轮次需要压测或保持一致理解的关键词。opening 可先列第一轮关键词，后续搜索后可更新。
- `map.key_variables`：影响判断的关键变量，可随每轮搜索更新。
- `map.major_paths`：主要路线或解释框架，可随每轮搜索更新。
- `map.frictions_or_conditions`：实践摩擦、限制条件、适用前提。
- `map.disagreements`：已知争议或竞争判断。
- `map.unknowns`：当前未知项，最好区分 `searchable` 和 `user-only`。

### 范围边界（scope_boundary）

定义这次研究回答什么、不回答什么、最多做到什么动作。

- `in_scope`：本 run 会回答的范围。
- `out_of_scope`：明确不回答的范围。
- `action_boundary`：动作上限，例如“只做只读研究”“只给建议，不替用户决策”“不写外部系统”。
- `user_only_decisions`：只能由用户决定的事项。

### 证据契约（evidence_contract）

定义什么证据才算够，防止用弱证据支撑强结论。

- `source_surfaces.official_or_primary`：官方或一手来源。
- `source_surfaces.market_or_news`：市场、新闻、公告、产品信息。
- `source_surfaces.academic`：论文、学术资料、方法论资料。
- `source_surfaces.community_or_cases`：社区经验、案例、投诉、实操记录。
- `evidence_principles.primary_source_preferred`：何时必须优先一手来源。
- `evidence_principles.method_fit`：什么证据适合回答这个问题。
- `evidence_principles.practice_friction`：是否必须覆盖实践摩擦和反例。
- `evidence_principles.cross_check`：交叉验证要求。
- `evidence_principles.evidence_downgrade`：证据弱时如何降级表述。
- `stop_criteria`：停止继续搜索的条件。

### 输出和动作契约（output_action_contract）

定义最后交付什么，以及哪些动作需要用户确认。

- `product_shape`：最终产物形态，例如 memo、清单、对比表、workflow、草稿。
- `audience`：产物给谁看、给谁用。
- `allowed_actions`：允许建议或执行的动作。
- `disallowed_actions`：不允许建议或执行的动作。
- `needs_user_confirmation`：推进前必须问用户确认的事项。

## 派生字段（derived）

这些字段不是直接抄用户原话，而是从上下文推导出来。

### 使用意图（use_intent）

回答“用户拿这次研究结果做什么”。

- `value`：用途判断。
- `derived_from`：推导来源，必须写明来自哪些字段，例如 `original_user_words + user_feedback`。
- `notes`：推导说明，尤其要说明是否只是临时判断。

### 研究目标（objective）

把主题转成可执行研究问题。

- `decision_or_action`：这次研究要支持的决定、推进的项目或解决的问题。
- `research_question`：为了这个目标，需要回答的问题。
- `current_formulation`：当前工作表述，搜索后可以更新。

### 搜索计划（search_plan）

定义当前搜索为什么发生，以及下一轮应该补什么。

- `source_surfaces`：当前或下一轮要开的来源面，不写具体工具路由。
- `first_round`：opening 生成的第一轮搜索意图，后续保留为起点记录。
- `gaps`：当前缺口，区分可搜索缺口和用户专属缺口。
- `next_round_focus`：下一轮搜索聚焦；opening 可写 `deferred`，round 后应随 state 更新。

### 充分性判断（enoughness）

记录当前证据是否足以收口。

- `current`：当前充分性状态。opening 通常是 `insufficient`，每轮搜索后都要更新。
- `enough_for`：当前证据足够支持什么。
- `not_enough_for`：当前证据不足以支持什么。
- `next_action`：下一步动作，例如 `search_next`、`ask_user`、`write_memo`。

## 子课题候选（child_runs）

只有当某个缺口需要独立开题、独立搜索、独立产出时，才记录为子课题候选。普通检索缺口不要过早拆子 run。

## 关键 facet 跟踪（tracked_facets）

不是每个字段都挂状态，只跟踪会影响搜索方向、用户意图、边界、证据标准、输出动作的关键 facet。

常见 facet：

- `use_intent`
- `objective`
- `scope_boundary`
- `evidence_contract`
- `output_action_contract`
- 会改变 `search_intent` 的 `inquiry_shape` 关键项
- 可能需要拆子 run 的 `child_runs.candidates`

常见状态：

- `missing`：没有有效值，也不能安全假设。
- `unresolved`：有多个候选值，而且选择会改变搜索方向、输出或动作边界。
- `temporary`：agent 选了一版临时工作值，可以先推进。
- `confirmed`：用户确认，或证据足以支持当前用途。
- `deferred`：知道缺口存在，但当前阶段故意不处理。

## Legacy import

只在恢复旧 run 时使用。新 run 通常写 `n/a` 或 `no`。导入旧 `task-card.md`、`judgment.md`、`memo.md` 时，只导入明确写出的内容，不因为旧文件存在就自动标成 `confirmed`。
