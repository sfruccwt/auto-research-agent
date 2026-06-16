# State ledger / Round sealer 技术设计

状态：简化草案

## 0. 定位

旧的自动推进设想已降级。本项目不再设计一个自动推进 run 的脚本。

新的脚本层定位是 state ledger / round sealer：

- 记录状态。
- 校验必要产物。
- 保存快照。
- 写 log。
- 报告当前 run 卡在哪一步。

脚本不调用 LLM，不自动执行 search，不替用户批准下一轮计划。

## 1. 脚本职责

| 动作 | 作用 | 是否做语义判断 |
|---|---|---|
| `validate` | 检查必要文件、字段、路径是否存在 | 否 |
| `snapshot` | 保存当前 `notes/research-state.md` 的历史快照 | 否 |
| `log` | 记录 seal / user review / done 等事件 | 否 |
| `status` | 展示当前 run 的结构性状态 | 否 |
| `seal opening` | 封存 opening brief 和 `notes/search-opening.md` | 否 |
| `seal round` | 封存 search round 产物和 state 更新 | 否 |

## 2. Seal opening

Seal opening 前应满足：

- `notes/research-state.md` 存在。
- `notes/search-opening.md` 存在。
- opening brief 已记录用户批准或修改。
- 必要字段能被结构性读取。

Seal opening 做：

```text
validate opening artifacts
  -> snapshot notes/research-state.md as notes/state-history/research-state-opening.md
  -> log seal opening
  -> report ready for search round 1
```

## 3. Seal round

Seal round 前应满足：

- `sources/search-round-N.md` 存在。
- `sources/search-round-N-human.md` 存在。
- `notes/research-state.md` 当前态已记录本轮更新。
- 本轮已生成 `proposed_next_round`、`write_memo`、`pivot`、`child_run` 或 `stop` 建议之一。

Seal round 做：

```text
validate round artifacts
  -> snapshot notes/research-state.md as notes/state-history/research-state-rNN.md
  -> log seal round N
  -> report waiting for user review
```

## 4. Status 输出

Status 只报告结构性信息：

- 当前 run 是否已完成 startup / opening / round seal / memo / done。
- 当前缺哪些产物。
- 当前是否等待用户审阅。
- 下一步有哪些允许动作。

Status 不判断：

- 研究结论是否正确。
- 证据是否语义上足够。
- 应不应该继续搜。

这些判断属于 LLM brief 和用户审阅。
