# 研究工作流 v0.8（索引版）

> 目标：围绕一个真实问题，研究到足够支持行动、判断或项目推进；不把研究变成无止境的信息囤积。
> 定位：这是主版本。学术研究方法只作为参考来源，不再作为主线模板。

---

## 阶段文件路由

详细的运行时指引已拆分到 `sop/stages/` 下，按当前阶段读取：

| 文件 | 内容 | 何时读 |
|---|---|---|
| `stages/0-global.md` | 全阶段通用规则（来源标注、搜索工具、概念确认制） | 每次过门都重读 |
| `stages/1-opening.md` | 开题：初始化 `research-state.md` + opening 快照 | run 启动时 |
| `stages/2-research.md` | 搜索、状态更新与收尾：search round → state delta → memo → output | opening 门通过后 |

---

## Active artifacts

| 文件 | 作用 |
|---|---|
| `notes/research-state.md` | 当前最新研究状态，继续 run 时优先读取 |
| `notes/state-history/*.md` | 不可变历史快照，用于复盘和测试 |
| `sources/search-round-N.md` | 每轮搜索、证据、`state_delta`、阶段性 enoughness |
| `notes/memo.md` | output 前最终 review，确认 enoughness 和 action boundary |
| `output.md` | 面向读者的最终投递物 |

新 run 不再生成 `notes/task-card.md` 和 `notes/judgment.md`。

---

## 口令版

> 先建 state；
> 每轮搜索后更新 state；
> 只补会改变 state / 路径排序 / action boundary 的缺口；
> memo 前确认 enoughness；
> output 只写最终稿。

---

## 两个核心抓手

### A. Motivation

问任何信息、任何观点，先问：

- 它为什么值得研究？
- 它为什么值得我看？
- 它到底在回应什么问题？

Motivation 写回 `origin_context.user_feedback` 或 `change_log`，不是另开阶段文档。

### B. Insight

再问：

- 它真正说出了什么？
- 它提供了什么关键洞察？
- 它到底解释了什么？

如果一个东西 Motivation 弱、Insight 也弱，那大概率不值得细读。

---

## 哪些东西值得细读

默认流程是：先粗读 → 再筛选 → 只把值得的拿去细读。

优先细读：

- Motivation 很强的
- Insight 很强的
- 对当前 `enoughness.stop_criteria` 帮助很直接的
- 能给出更好解释框架的

如果只是知道它“在干什么”就够了，那粗读即可。

---

## 因果推断意识

当前不把学术型计量细节当主线，但必须保留这些习惯：

- 不要太快把相关性当因果性。
- 问清楚真正变化的是哪个变量。
- 问清楚还有哪些关键因素没控制。
- 问清楚对比对象到底是什么。
- 问清楚当前结论依赖哪些前提。

---

## 恢复中断 run

恢复 run 时：

1. 读 `runs/<run-id>/idea.md`。
2. 读 `runs/<run-id>/log.md`。
3. 优先读 `runs/<run-id>/notes/research-state.md`。
4. 按需读 `runs/<run-id>/notes/state-history/`。
5. 读最新 `sources/search-round-N.md`，检查它是否和当前 state 一致。

如果旧 run 没有 `notes/research-state.md`，但有 `notes/task-card.md`、`notes/judgment.md` 或 `notes/memo.md`，先做 legacy import：

```text
notes/research-state.md
notes/state-history/research-state-legacy-import.md
```

旧 run 的 `current_gate = midway` 只视为 legacy 阶段标记；新流程不继续推进 midway gate。

---

## 一句话总结

> 研究的目标不是把资料查全，而是围绕一个真实问题维护一份当前 state，让每轮搜索改变它、解释它，最后在 enoughness 足够时转成 memo 和 output。
