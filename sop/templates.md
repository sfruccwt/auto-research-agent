# 研究模板索引 v0.8

每个模板已拆为独立文件，按需读取。

| 模板 | 文件 | 用途 |
|---|---|---|
| Research state | `sop/template-research-state.md` | 新 active 模板：当前研究状态、slot、派生项、历史快照 |
| Search round | `sop/template-search-round.md` | 新 active 模板：每轮搜索、证据、state delta、enoughness 初判 |
| 决策导向备忘录 | `sop/template-memo.md` | output 前最终 review：enoughness、action boundary、路径分流 |
| Output 投递模板 | `sop/template-output.md` | 投递到 wiki inbox 的 frontmatter + 写作规范 |
| 资产配置附加槽位 | `sop/template-investment-addon.md` | 按需启用：资产/投资类主题的额外约束 |
| Legacy 研究任务卡 | `sop/template-task-card.md` | 仅用于旧 run legacy import；新 run 不再生成 |
| Legacy 判断单 | `sop/template-judgment.md` | 仅用于旧 run legacy import；新 run 不再生成 |

## 来源引用格式（全模板通用）

所有写入文档的搜索结果都必须标注来源，格式：

- 正文用 `[N]` 标注引用位置
- 文末来源列表按编号排序，每条之间空一行
- URL 显式写出，不用 markdown 超链接

```text
[1] 作者/机构. "标题." 年份.
    URL: example.com/path

[2] 作者/机构. "标题." 年份.
    URL: example.com/path
```

适用于：`notes/research-state.md`、`notes/memo.md`、`sources/search-round-N.md`、`output.md`。

---

## 版本说明

v0.8 设计意图：

- `research-state.md` 替代新 run 中的 `task-card.md` 和 `judgment.md`。
- 每轮搜索必须写 `search_round_summary.state_delta`，并更新当前 state。
- `midway` 不再是新流程 gate；旧 run 中的 `midway` 只作为 legacy gate 值处理。
- `memo.md` 保留为 output 前的最终 enoughness / action boundary review。
- `工具分配` 不迁入 slot；默认检索工具规则由 `AGENTS.md` 注入。
