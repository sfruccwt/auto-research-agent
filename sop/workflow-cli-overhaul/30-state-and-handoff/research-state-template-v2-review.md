# Research state v2 中文字段稿

> 这份文件说明新版 `research-state` 可以记录哪些通用字段。它不是 opening brief 或 Round N brief 模板；brief 只是后续从 `research-state` 与 `sources/search-round-N.md` 渲染出来的审阅视图，字段可以另行设计。
>
> `research-state` 也不是一轮检索的证据审计；本轮查了什么、证据够不够、来源覆盖情况，主要写在 `sources/search-round-N.md`。`research-state` 只维护跨轮之后对原始问题的当前回答草稿，以及少量会影响下一步动作的编排信息。

## 总体定位

| 作用 | 说明 |
|---|---|
| 维护全局回答草稿 | 当前 run 到底在研究什么、边界是什么、经过多轮搜索后对原始问题的当前主要解释、方案或答案是什么。 |
| 编排下一步动作 | 下一步是继续搜索、问用户、pivot、写 memo、开子 run，还是停止。 |

| 不承担的职责 | 说明 |
|---|---|
| 不复制 search round 来源清单 | 本轮查了哪些 URL、路径、工具通道，放在 `sources/search-round-N.md`。 |
| 不记录逐条证据强弱判断 | 每条证据的支持、反驳、限制，放在 search round。 |
| 不写完整 evidence audit | 官方、学术、社区、新闻等来源面覆盖情况，默认由 search round 承担。 |
| 不定义 brief 呈报字段 | Opening brief / Round N brief 是审阅视图，可从 state 和 search round 抽取。 |
| 不承担 status / log 职责 | 结构性进度、封账状态、事件历史由脚本日志、queue gate 和 state history 负责。 |

## 通用填写规则

| 规则 | 填写方式 |
|---|---|
| 用户原话 | 只写在 `problem_frame.original_user_words`，不要在其他字段改写成“用户确认”。 |
| Agent 工作理解 | 写在 `problem_frame.current_topic`、`problem_frame.objective`、`problem_frame.use_intent`。 |
| 空值约定 | 未知写 `unknown`，不适用写 `n/a`，暂缓写 `deferred`，空列表写 `[]`。 |
| Search round 后写回 | 只把影响全局回答草稿或后续动作的压缩结果写回 state；证据细节留在 `sources/search-round-N.md`。 |
| 历史版本 | 每轮 seal 时由脚本把当前 state 快照到 `notes/state-history/`，保留历史版本。 |

## 元信息（metadata）

记录这份 state 的生命周期信息。

| 字段 | 何时填写 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|---|
| `run_id` | 每次 state 都填写 | run 编号 | 例如 `2026-06-16-example` | 与 run 目录一致。 |
| `stage` | 每次 state 都填写 | 当前阶段的结构性投影 | `opening`、`searching`、`round_review`、`memo_ready`、`output_ready`、`done`、`blocked` | 只用于恢复上下文；权威状态仍以 log / queue gate 为准。 |
| `updated_at` | 每次更新后填写 | 更新时间 | ISO 8601 | 例：`2026-06-16T21:30:00+08:00`。 |
| `updated_by` | 每次更新后填写 | 谁更新了这份 state | `llm`、`manual`、`legacy_import` | 不写工具名细节。 |
| `based_on.idea` | opening 起填写 | 本 state 基于哪个 `idea.md` | 路径；没有写 `n/a` | 用来追溯完整原始输入。 |
| `based_on.search_rounds` | search round 后更新 | 已吸收哪些 search round | 路径列表；opening 写 `[]` | 只列已吸收进当前 state 的轮次。 |
| `based_on.user_feedback` | 吸收用户反馈时填写 | 本次更新吸收了哪些用户反馈 | 文本；没有写 `n/a` | 不要把 agent 推断写成用户确认。 |
| `based_on.other_materials` | 有其他材料时填写 | 其他输入材料路径或 URL | 列表；没有写 `[]` | 可包含本地材料、用户提供 URL、旧 run 产物。 |

示例：

```yaml
metadata:
  run_id: 2026-06-16-example
  stage: round_review
  updated_at: 2026-06-16T21:30:00+08:00
  updated_by: llm
  based_on:
    idea: runs/2026-06-16-example/idea.md
    search_rounds:
      - sources/search-round-1.md
    user_feedback: "用户确认继续补官方文档，不扩大到实现代码。"
    other_materials: []
```

## 问题框架（problem_frame）

记录这个 run 当前“在研究什么”。这部分主要来自 opening，也可以在用户反馈或搜索结果导致问题重构时更新。

| 字段 | 何时填写 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|---|
| `original_user_words` | opening 时填写，之后保持保真 | 用户原始输入 | 原句；输入过长时保留关键原句 | 完整输入由 `metadata.based_on.idea` 指向。不要后续改写。 |
| `current_topic` | opening 时填写，问题重构时可更新 | 当前短标题 | agent 的工作标题 | 不是用户原话。 |
| `research_object` | opening 时填写，必要时更新 | 研究对象 | 工具、制度、合同、地点、流程、问题等 | 帮助限定“研究什么东西”。 |
| `operation_type` | opening 时填写 | 研究动作 | 解释、比较、验证、诊断、选型、规划、写作等 | 用来影响搜索和产物组织方式。 |
| `objective` | opening 时填写，scope 变化时更新 | 核心问题 | 建议写成“为了 X，需要回答 Y” | 不要写成宽泛主题，要可判断。 |
| `use_intent` | opening 时填写 | 用户拿结果做什么 | 做决策、写 SOP、形成 checklist、进入实现等 | 区分“知道一下”和“要采取行动”。 |
| `current_formulation` | 原问题被收窄、拆分或重构时填写 | 当前工作表述 | 文本；没有重构时可与 objective 接近 | 如果搜索后发现原问题需要重构，只改这里，不改 `original_user_words`。 |

| 填写要点 | 说明 |
|---|---|
| 临时 search intent 不放这里 | 本轮搜索的临时问题放到 `next_step.search_next.questions` 或 `search-round-N.md` 的 `search_intent`。 |
| objective 要可判断 | 应能判断是否回答到位，而不是只写主题名。 |
| 用户原话不可被覆盖 | 问题变形写进 `current_formulation`。 |

## 范围边界（scope_boundary）

定义本 run 回答什么、不回答什么、动作上限是什么。

| 字段 | 何时填写 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|---|
| `in_scope` | opening 时填写，scope 变化时更新 | 本 run 会回答的范围 | 列表 | 写成可检查的范围项。 |
| `out_of_scope` | opening 时填写，必要时更新 | 明确不回答的范围 | 列表 | 防止搜索扩散。 |
| `action_boundary` | opening 时填写，用户授权变化时更新 | 动作上限 | `research_only`、`write_notes`、`draft_sop`、`edit_sop`、`edit_code`、`deliver_to_wiki` | 会改变写入范围或外部动作的边界必须写清楚。 |
| `user_only_decisions` | 有用户专属取舍时填写 | 只能由用户决定的事项 | 列表；没有写 `[]` | 例如是否签约、是否采用某方案、风险偏好取舍。 |
| `assumptions` | 需要先假设推进时填写 | 当前允许先假设推进的事项 | 列表；没有写 `[]` | 只写低风险或已明确默认的假设。 |

| 填写要点 | 说明 |
|---|---|
| 用户专属取舍不要伪装成搜索问题 | 应放在 `user_only_decisions` 或 `next_step.ask_user`。 |
| 可搜索缺口不要放进 `user_only_decisions` | 应放到 `next_step.search_next`；本轮新缺口先由 `sources/search-round-N.md` 记录。 |
| 动作边界优先明确 | 尤其是是否允许改 SOP、改代码、投递 wiki。 |

## 全局回答草稿（global_progress）

记录 run 到当前为止对原始问题的累计回答。它不是本轮 search round 摘要，也不维护 status；它维护的是吸收多轮搜索后的当前“主解释 / 主方案 / 主答案”。

| 字段 | 何时填写 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|---|
| `current_synthesis` | opening 后可初始化；每轮 search 后更新 | 当前对原始问题的全局回答草稿 | 可直接给用户审阅的短摘要 | 面向原始问题，不是只面向上一轮 search intent。 |

| 填写要点 | 说明 |
|---|---|
| 每轮吸收 search round | 用本轮 `search_intent` 和本轮发现更新全局草稿；如果本轮只回答局部问题，也要说明它怎样改变或没有改变全局答案。 |
| 按研究类型写主答案 | 出方案时维护当前全局方案；解释原因时维护当前主要解释；比较选型时维护当前比较结论。 |
| 不列完整证据 | 不在这里列完整 evidence、不维护每条 finding 的置信度、不记录所有 open questions。 |
| 缺口放到 next_step | 仍未解决但影响下一步的问题，放到 `next_step.search_next` 或 `next_step.ask_user`；本轮新 gap 先写在 `sources/search-round-N.md`。 |

示例：

```yaml
global_progress:
  current_synthesis: >
    当前方案应保持 controller-first：脚本只做 validate / snapshot / log / seal，
    LLM 负责 opening 与 search round 的语义判断。第一轮检索确认
    `codex exec --output-schema` 适合承载受约束的结构化输出，但下一步还需要
    明确 state 与 search-round 的字段边界，避免把本轮 evidence audit 复制进 state。
```

## 下一步编排（next_step）

记录下一步应该做什么。这个部分是 `research-state` 对 search 阶段最直接的编排输出，不承担 run status 职责。

### 顶层字段

| 字段 | 何时填写 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|---|
| `recommendation` | 每次更新 next step 时填写 | 下一步建议 | `search_next`、`ask_user`、`pivot`、`write_memo`、`child_run`、`stop` | 这是编排建议，不是脚本 status。 |
| `reason` | 每次更新 next step 时填写 | 为什么推荐这个动作 | 短句 | 不写长篇证据摘要。 |

| `recommendation` 值 | 含义 |
|---|---|
| `search_next` | 继续下一轮搜索。 |
| `ask_user` | 先问用户。 |
| `pivot` | 需要重构问题或转向。 |
| `write_memo` | 进入 memo / output 草稿。 |
| `child_run` | 开子 run。 |
| `stop` | 停止。 |

`reason` 示例：

| 示例 | 适用场景 |
|---|---|
| `仍有一个影响结论强度的 searchable gap。` | 推荐继续搜索。 |
| `下一步取决于用户是否允许扩大 scope。` | 推荐 ask_user 或 pivot。 |
| `当前证据已足够支持 memo，但需要明示两个限制。` | 推荐 write_memo。 |

### `search_next`

只有 `recommendation: search_next` 时填写；否则写 `n/a`。

| 字段 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|
| `questions[].question` | 下一轮自然语言问题 | 文本 | 不写裸 query。 |
| `questions[].why_this_matters` | 为什么这个问题会影响原始 objective 或下一步动作 | 文本 | 要能回扣 original intent。 |
| `questions[].derived_from` | 来自哪些信息 | `search-round-1.gaps_found`、`global_progress.current_synthesis`、`user_feedback` 等 | 用来追溯问题来源。 |
| `questions[].expected_source_surfaces` | 预计需要哪些来源面 | `official_or_primary`、`market_or_news`、`academic`、`community_or_cases`、`local_or_user_materials` | 这是搜索编排字段，不是 evidence audit。 |
| `questions[].stop_when` | 这个问题搜到什么程度可以停 | 文本 | 是执行前口径。 |
| `source_route_notes` | 路由约束或优先级 | 文本；没有写 `n/a` | 具体查询入口在 `search-round-N.md` 执行时记录。 |

| 填写要点 | 说明 |
|---|---|
| 控制问题数量 | 每轮最多 1-3 个问题。 |
| 只放高影响 searchable gap | 问题必须能影响 original objective 或下一步动作。 |
| 用户取舍不放这里 | 如果问题实际需要用户决定，放 `ask_user`。 |

### `ask_user`

只有 `recommendation: ask_user` 时填写；否则写 `n/a`。

| 字段 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|
| `questions[].question` | 要问用户的问题 | 文本 | 问题要能直接被用户回答。 |
| `questions[].why_needed` | 为什么必须问用户，而不是搜索 | 文本 | 明确 user-only 原因。 |
| `questions[].blocks` | 它阻塞哪个动作 | `search_next`、`memo_scope`、`action_boundary` 等 | 用来判断是否真的需要现在问。 |

| 填写要点 | 说明 |
|---|---|
| 只问高影响 user-only 问题 | 不要把低影响偏好问题放进主流程。 |
| 不要把可搜索问题包装成用户问题 | 能搜索就走 `search_next`。 |

### `pivot`

只有 `recommendation: pivot` 时填写；否则写 `n/a`。

| 字段 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|
| `proposed_reframe` | 建议改写后的研究问题 | 文本 | 应能替代当前 `problem_frame.current_formulation`。 |
| `why_pivot` | 为什么需要转向 | 文本 | 说明触发原因。 |
| `requires_user_confirmation` | 是否需要用户确认 | `yes` / `no`；通常写 `yes` | scope 或 action boundary 变化时必须确认。 |

### `memo`

只有 `recommendation: write_memo` 时填写；否则写 `n/a`。

| 字段 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|
| `memo_scope` | memo 准备回答哪些问题 | 列表或短段落 | 不要扩大到未确认 scope。 |
| `must_include_limits` | memo 必须明示哪些限制 | 列表；没有写 `[]` | 包括证据不足、来源限制、适用边界。 |
| `source_rounds_to_use` | memo 应主要引用哪些 search round | 路径列表 | 只列会实际支撑 memo 的轮次。 |

### `child_run`

只有 `recommendation: child_run` 时填写；否则写 `n/a`。

| 字段 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|
| `topic` | 子 run 主题 | 文本 | 应是独立研究问题。 |
| `why_separate` | 为什么不能作为普通下一轮搜索处理 | 文本 | 说明独立产出的必要性。 |
| `parent_gap` | 它对应哪个全局缺口 | 文本或字段引用 | 应能回扣母 run 的 current synthesis 或 remaining gap。 |
| `requires_user_confirmation` | 是否需要用户确认 | `yes` / `no` | 通常写 `yes`。 |

## 子课题候选（child_runs）

记录可能需要拆出去的独立子课题。普通搜索缺口不要过早拆子 run。

| 字段 | 何时填写 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|---|
| `candidates[].topic` | 出现子课题候选时填写 | 子课题题目 | 文本 | 不要写普通搜索问题。 |
| `candidates[].parent_gap` | 每个候选都填写 | 对应哪个全局缺口 | 文本或字段引用 | 可指向 `global_progress.current_synthesis` 中尚不能成立的部分。 |
| `candidates[].why_separate` | 每个候选都填写 | 为什么需要独立 run | 文本 | 说明与普通下一轮搜索的区别。 |
| `candidates[].decision_state` | 每个候选都填写 | 决策状态 | `candidate`、`approved`、`rejected`、`opened`、`done`、`deferred` | 不等同于 run status。 |
| `candidates[].child_run_id` | 已打开子 run 时填写 | 子 run id | 没有写 `n/a` | opened 后回填。 |

## 关键 facet 跟踪（tracked_facets）

不是每个字段都挂语义澄清状态，只跟踪会影响搜索方向、用户意图、边界、输出动作的关键项。这里的 `resolution_state` 不是 run status。

| 建议跟踪的 facet | 何时跟踪 |
|---|---|
| `problem_frame.objective` | objective 仍不稳定或被搜索结果重构时。 |
| `problem_frame.use_intent` | 用户使用意图影响 scope、memo 形态或 action boundary 时。 |
| `scope_boundary` | in/out scope 或动作边界影响后续检索时。 |
| `global_progress.current_synthesis` | 主答案仍是临时判断或存在关键替代解释时。 |
| `next_step.recommendation` | 下一步动作有多个可能路线时。 |
| `child_runs.candidates` | 是否拆子 run 需要后续确认时。 |

| 字段 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|
| `facet` | 被跟踪的关键项 | 字段路径或短名称 | 不要给所有字段都加 tracking。 |
| `value` | 当前值或摘要 | 文本 | 保持简短。 |
| `resolution_state` | 澄清状态 | `missing`、`unresolved`、`temporary`、`confirmed`、`deferred` | 不是 run status。 |
| `basis` | 当前判断依据 | `user`、`search_round`、`inference`、`default`、`mixed`、`legacy_doc` | 不要把 inference 写成 user。 |
| `alternatives` | 其他可能值 | 列表；没有写 `[]` | 只写高影响备选。 |
| `next_action` | 下一步动作 | `ask_user`、`search_next`、`defer`、`none`、`write_memo` | 应能对应 `next_step` 或后续处理。 |
| `update_reason` | 为什么这次更新或保持不变 | 文本 | 只写有意义变化。 |

| 填写要点 | 说明 |
|---|---|
| 控制使用范围 | 只有会改变搜索方向、scope、动作边界或进入 memo 的关键项才 tracking。 |
| 不做全字段状态机 | 避免 state 膨胀。 |

## Legacy import

只在恢复旧 run 时使用。新 run 通常写 `n/a` 或 `no`。

| 字段 | 何时填写 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|---|
| `imported_from_task_card` | 恢复旧 run 时填写 | 是否从旧 task-card 导入 | `yes` / `no` | 新 run 写 `no`。 |
| `imported_from_judgment` | 恢复旧 run 时填写 | 是否从旧 judgment 导入 | `yes` / `no` | 新 run 写 `no`。 |
| `imported_from_memo` | 恢复旧 run 时填写 | 是否从旧 memo 导入 | `yes` / `no` | 新 run 写 `no`。 |
| `import_notes` | 有导入行为时填写 | 导入说明 | 文本；新 run 写 `n/a` | 说明导入范围和限制。 |

| 导入规则 | 说明 |
|---|---|
| 只导入旧文件明确写出的内容 | 不因旧文件存在就自动标成 `confirmed`。 |
| 不搬运旧证据细节 | 旧文件中的证据细节不要全部搬进 state；只搬会影响当前全局回答草稿或下一步动作的摘要。 |

## change_log

记录 state 的重要变化，不记录普通措辞调整。

| 字段 | 填写方式 | 取值 / 默认值 | 注意事项 |
|---|---|---|---|
| `time` | 变更时间 | ISO 8601 | 与本次 state 更新一致。 |
| `source` | 变更来源 | `user_feedback`、`search-round-1`、`manual_review` 等 | 说明变化从哪里来。 |
| `change` | 改了什么 | 文本 | 只记录重要语义变化。 |
| `reason` | 为什么改 | 文本 | 不记录普通措辞调整。 |

示例：

| time | source | change | reason |
|---|---|---|---|
| 2026-06-16T21:30:00+08:00 | search-round-1 | `next_step.recommendation` 从 `search_next` 改为 `write_memo` | 本轮已回答核心 objective，剩余缺口可在 memo 中作为限制说明 |

## 与 search-round 的边界

| 内容 | 写入位置 |
|---|---|
| 本轮 search intent | `sources/search-round-N.md` |
| 本轮实际查询、入口、工具通道 | `sources/search-round-N.md` |
| 本轮 evidence coverage / source limits | `sources/search-round-N.md` |
| 本轮 enoughness | `sources/search-round-N.md` |
| 本轮对 original intent 的贡献 | `sources/search-round-N.md`，必要时压缩进 `global_progress.current_synthesis` |
| 当前全局回答草稿 | `research-state.global_progress.current_synthesis` |
| 下一步需要补的高影响问题 | `research-state.next_step.search_next` 或 `research-state.next_step.ask_user` |
| 下一步 search / ask / pivot / memo 编排 | `research-state.next_step` |
