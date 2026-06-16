# Workflow CLI 工具化改造计划

状态：简化草案

## 0. 当前结论

本轮改造不再追求全自动 research runner。目标改为：

- 每轮都有用户审阅 brief。
- Opening 批准后写 `notes/search-opening.md`。
- Search round 后生成 `proposed_next_round`。
- 脚本只负责状态封账，不负责自动推进。

当前先收敛 `research-state` 与 `search-round` 的核心字段边界；opening brief 和 Round N brief 的具体呈报模板后置设计。brief 是审阅视图，不反过来牵引 state / round 模板膨胀。

## 1. 职责分工

| 层 | 职责 | 示例 |
|---|---|---|
| LLM | 生成 opening brief、执行检索、写 search round、提出 `proposed_next_round` | `notes/search-opening.md`、`sources/search-round-N.md` |
| 用户 | 审阅 opening brief、round brief、memo，决定继续、修改、pivot、子 run 或收口 | 批准或修改 `proposed_next_round` |
| 脚本 | validate / snapshot / log / status / seal | `seal opening`、`seal round`、done gate |

脚本不做：

- 自动调用 LLM。
- 连续执行 search round。
- 替用户批准下一轮。
- 语义判断证据是否足够。

## 2. 当前文档改造范围

优先保持四张核心图一致：

1. `workflow-cli-target-flow.md`
2. `stage-opening-clarification.md`
3. `stage-search.md`
4. `search-question-derivation-design.md`

其他文档只跟随这些图调整职责、命名和最小契约。

## 3. Artifact 约定

| Artifact | 作用 | 写入者 |
|---|---|---|
| `notes/search-opening.md` | opening 批准后的首轮检索计划 | LLM，用户审阅后保留 |
| `notes/research-state.md` | 当前态：研究问题框架、全局回答草稿、下一步检索 / 收口编排 | LLM |
| `sources/search-round-N.md` | 第 N 轮审计记录 | LLM |
| `sources/search-round-N-human.md` | 第 N 轮人类阅读摘要 | LLM |
| `notes/state-history/*` | 当前态历史快照，例如 opening / round / pre-memo | 脚本 |
| `log.md` | seal、review、done、deliver / close 事件 | 脚本 |

`notes/search-opening.md` 不是已执行检索记录，也不放入 `sources/`。

### `research-state` 与 `search-round` 分工

`research-state` 不承担上一轮 evidence audit，也不承担 run status / log 职责。它维护的是 run 的当前问题框架、对原始问题的全局回答草稿，并把这个草稿压成下一步可执行的编排建议：

- opening 时记录用户意图、研究对象、operation type、scope、输出和动作边界。
- search 前给出本轮或下一轮 `search_intent`、可搜索缺口和用户专属缺口。
- search 后维护一个核心全局字段：`global_progress.current_synthesis`。它回答“吸收本轮后，对原始问题的当前主要解释、方案或答案是什么”。
- 如果研究目标是出方案，`current_synthesis` 就维护当前全局方案；如果研究目标是解释原因，就维护当前主要解释；如果研究目标是比较选型，就维护当前比较结论。
- search 后只吸收会改变后续动作的状态变化，例如 objective 收窄、scope 改变、remaining gaps、`proposed_next_round`、`write_memo` / `pivot` / `ask_user` 建议。
- 不复制本轮来源清单、证据覆盖表或逐条证据强度判断。

`search-round-N.md` 承担上一轮检索记录和证据判断：

- 记录本轮实际查询、来源、工具通道和 browser / lane 限制。
- 判断本轮 `search_intent` 是否被回答。
- 记录本轮 evidence coverage、source limits、enoughness、new gaps。
- 说明本轮对本轮 `search_intent` 的帮助，以及本轮发现怎样改变或不改变 `research-state.global_progress.current_synthesis`。
- 提出可回写到 `research-state` 的 `state_delta` 和 `proposed_next_round`。

因此 enoughness / progress 也分层：

- `search-round-N.md` 的 enoughness 是本轮 enoughness：本轮 search intent 是否足够、证据缺口是什么。
- `research-state` 的 progress 是跨轮回答草稿：原始问题目前的主答案、主解释或主方案是什么，以及下一步应继续搜、问用户、pivot、写 memo 或 stop。

Evidence 相关细节默认放在 `search-round-N.md`。`research-state` 只保留会影响全局回答草稿或下一步编排的压缩结果，不把 evidence 字段扩写成第二份 search round。

## 4. 建议命令边界

命令名可以后续再定，但能力边界应保持：

```powershell
ara run status <run-id>
ara run validate <run-id>
ara state snapshot <run-id> --stage opening
ara state snapshot <run-id> --round <N>
ara run seal-opening <run-id>
ara run seal-round <run-id> --round <N>
ara run gate <run-id> done
ara run deliver <run-id>
ara run close <run-id>
```

这些命令只做机械封账，不生成语义内容。

## 5. 实施顺序

### 阶段 1：文档对齐

- 重写四张核心流程图。
- 删除旧自动推进、自动循环、复杂 clarification/gap taxonomy 叙述。
- 统一 `search-opening`、`proposed_next_round`、`round brief`、`seal opening`、`seal round` 命名。

### 阶段 2：模板最小化

- 先固定 `research-state` 通用字段稿。
- 再固定 `search-round-N.md` 单轮审计字段稿。
- 暂不设计 opening brief 和 Round N brief 的完整呈报模板；后续只从 state / round 已有字段中抽取审阅视图。

### 阶段 3：状态封账命令

- 实现或调整 validate / snapshot / log / status / seal 能力。
- opening seal 校验 `notes/research-state.md` 与 `notes/search-opening.md`，并快照当前态。
- round seal 校验 `search-round-N`、`search-round-N-human` 与 `notes/research-state.md` 当前态更新，并快照当前态。

### 阶段 4：检索执行仍保持 lane 隔离

- 每轮 search round 仍通过检索子 agent。
- 保留 `agent-reach lane` + `browser route lane`。
- 母 agent 只接收压缩结果。

## 6. 验收点

- 总流程图没有自动 search loop。
- Opening 图包含 `notes/search-opening.md`。
- Search 图在用户审阅前不进入下一轮。
- Search question 派生图输出 `proposed_next_round`，不输出自动执行。
- 文档中不再把脚本称为自动推进器。
