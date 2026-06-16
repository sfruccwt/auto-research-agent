# Workflow CLI 状态与日志模型

状态：简化草案

## 0. 定位

这份文档说明 state、snapshot、log 和 seal 的职责。它不设计自动推进器。

## 1. 文件职责

| 文件 | 写入者 | 职责 |
|---|---|---|
| `runs/<run-id>/idea.md` | 脚本 | frozen raw intake / idea snapshot |
| `notes/research-state.md` | LLM | 当前态：问题框架、scope、`global_progress.current_synthesis`、下一步编排 |
| `notes/search-opening.md` | LLM | opening 批准后的首轮检索计划 |
| `notes/state-history/*` | 脚本 | 当前态快照，例如 `research-state-opening.md`、`research-state-rNN.md`、pre-memo 快照 |
| `sources/search-round-N.md` | LLM | 第 N 轮检索审计记录 |
| `sources/search-round-N-human.md` | LLM | 第 N 轮用户阅读摘要 |
| `notes/memo.md` | LLM | output 前的 enoughness / action boundary review |
| `output.md` | LLM | 最终交付正文 |
| `runs/<run-id>/log.md` | 脚本 | seal、user review、done、deliver / close 等生命周期事件 |
| `queue/in_flight.json` | 脚本 | 结构性状态，不记录语义判断 |

## 2. Seal 与 Snapshot

原则：

- LLM 可以写语义产物。
- 脚本封存语义产物的当前版本。
- LLM 不直接写 queue、log 或 snapshot。
- seal 只说明结构性完成，不说明研究质量足够。

Opening 示例：

```text
LLM writes notes/research-state.md current state
LLM writes notes/search-opening.md
  -> seal opening
  -> script validates artifacts
  -> script snapshots notes/research-state.md to notes/state-history/research-state-opening.md
  -> script writes log event
```

Search round 示例：

```text
LLM writes sources/search-round-N.md
LLM writes sources/search-round-N-human.md
LLM overwrites notes/research-state.md current state
  -> seal round N
  -> script validates artifacts
  -> script snapshots notes/research-state.md to notes/state-history/research-state-rNN.md
  -> script writes log event
```

`notes/research-state.md` 始终是最新当前态。每轮 search 后由 LLM 覆盖更新；每次 seal 后由脚本把当时版本写入 `notes/state-history/`，历史编号属于快照文件，不属于当前态文件。

## 3. 推荐状态

第一版只需要这些结构性状态：

- `startup_done`
- `opening_waiting_review`
- `opening_sealed`
- `round_waiting_review`
- `memo_pending`
- `output_pending`
- `done_ready`
- `delivered`
- `closed`
- `blocked`

状态只表达 run 卡在哪一步，不表达“系统自动要做什么”。
