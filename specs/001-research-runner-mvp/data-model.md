# Phase 1 Data Model: Research Runner MVP

## Entities & 文件形态

### Idea（wiki 侧，runner 只读）

源 idea 文件在 `D:/Personal LLM Wiki/research/ideas/<slug>.md`（pending）或 `D:/Personal LLM Wiki/research/ideas/done/<slug>.md`（已归档）。

frontmatter（按 wiki `config/research-retire.md` 约定）：

```yaml
---
source: <来源>
captured: YYYY-MM-DD
route: research
route_reason: "..."
status: pending | done | abandoned
output:                          # done/abandoned 必填，列表
  - <wiki-page-name | "放弃：原因">
retired: YYYY-MM-DD              # 归档时写入
---
```

Runner 关心字段：`status`、`output`（异常呈报时显示）。其他字段透传不动。

---

### Run（runner 工作区）

物理目录 `runs/<run-id>/`，`run-id` 默认 = idea 文件 basename（含日期前缀、去 `.md` 后缀）。例如 idea 文件 `2026-05-01-modernity-wang-minan-thirteen-lectures.md` → `run-id = 2026-05-01-modernity-wang-minan-thirteen-lectures`。

```text
runs/2026-05-01-modernity-wang-minan-thirteen-lectures/
├── idea.md          # 冻结快照，run 启动时拷自 wiki，运行期不再读源
├── log.md           # 追加写，runner 自己记关键事件
├── notes/
│   ├── task-card.md   # SOP 模板 1：研究任务卡（开题门产物）
│   ├── judgment.md    # SOP 模板 2：判断单（中途门产物）
│   └── memo.md        # SOP 模板 3：决策导向研究备忘录（收尾门产物）
├── sources/         # 抓取的原文 / 引用截图等
└── output.md        # 综合定稿，反复迭代直到 user 认可，最终复制到 wiki inbox
```

`log.md` 行格式（追加，机器和人都能读）：

```text
2026-05-01 14:23 | event=run_init       | idea=2026-05-01-modernity-wang-minan-thirteen-lectures.md
2026-05-01 14:30 | event=gate_passed    | gate=opening | by=user
2026-05-01 15:15 | event=gate_passed    | gate=midway  | by=user
2026-05-01 16:40 | event=draft_ready    | revision=0
2026-05-01 17:05 | event=revision       | revision=1   | reason="补充 anti-modernity 视角"
2026-05-01 17:30 | event=gate_passed    | gate=closing | by=user
2026-05-01 17:32 | event=delivered      | inbox=D:/Personal LLM Wiki/sources/notes/inbox/2026-05-01-modernity-wang-minan-thirteen-lectures.md
```

Run 状态机：

```
created → researching → drafting → revising ↺ → delivered
                                            └─→ abandoned
```

状态不在 `log.md` 顶部冗余存储——通过最近事件推断。`scan-and-align` 不读 log，只读 queue。

---

### Output（成果文件）

run 期间在 `runs/<id>/output.md`；deliver 时复制到 `D:/Personal LLM Wiki/sources/notes/inbox/<YYYY-MM-DD>-<slug>.md`（同名冲突自动 +N 后缀）。

frontmatter 遵循 `templates/inbox-output.md`：

```yaml
---
source: auto_research_agent
source_idea: research/ideas/<idea-filename>.md   # FR-016: 反向定位
captured: YYYY-MM-DD
route: wiki
route_reason: "..."
status: pending
---
```

正文：内容定稿散文 + 行内来源引用。无 wikilink、无 Related。

---

### Queue Files（runner 工作区状态）

#### `queue/pending.json` — 用户可选维护的 shortlist

MVP 阶段是 user 自己写或不写的备忘录，runner 不强制读，**不据此判断**何为候选。Schema:

```json
{
  "version": 1,
  "items": [
    { "idea_slug": "2026-05-01-modernity-wang-minan-thirteen-lectures", "added": "2026-05-01" }
  ]
}
```

#### `queue/in_flight.json` — 当前 active run

```json
{
  "version": 1,
  "items": [
    {
      "run_id": "2026-05-01-modernity-wang-minan-thirteen-lectures",
      "idea_slug": "2026-05-01-modernity-wang-minan-thirteen-lectures",
      "started": "2026-05-01T14:23:00+08:00",
      "current_gate": "midway"
    }
  ]
}
```

MVP 假设 `items.length <= 1`。

#### `queue/done/<YYYY-QN>.json` — 已投递（按季归档）

```json
{
  "version": 1,
  "items": [
    {
      "run_id": "2026-05-01-modernity-wang-minan-thirteen-lectures",
      "idea_slug": "2026-05-01-modernity-wang-minan-thirteen-lectures",
      "delivered": "2026-05-01T17:32:00+08:00",
      "inbox_path": "D:/Personal LLM Wiki/sources/notes/inbox/2026-05-01-modernity-wang-minan-thirteen-lectures.md"
    }
  ]
}
```

#### `queue/abandoned/<YYYY-QN>.json` — 中途放弃（按季归档）

```json
{
  "version": 1,
  "items": [
    {
      "run_id": "2026-05-01-some-slug",
      "idea_slug": "2026-05-01-some-slug",
      "abandoned": "2026-05-01T16:00:00+08:00",
      "reason": "信息源不可得，等 SearXNG 接好再回头跑"
    }
  ]
}
```

---

### Alignment Report（瞬态，scan-and-align 输出）

不落盘，stdout JSON：

```json
{
  "scanned_at": "2026-05-01T14:00:00+08:00",
  "wiki_ideas_count": 12,
  "categories": {
    "runnable": [
      { "idea_slug": "2026-05-01-modernity-...", "wiki_status": "pending" }
    ],
    "awaiting_ingest": [
      { "idea_slug": "2026-04-30-llm-collab-...", "wiki_status": "pending", "delivered": "2026-04-30T18:00:00+08:00" }
    ],
    "previously_abandoned": [
      { "idea_slug": "2026-04-15-source-discovery-...", "wiki_status": "pending", "abandoned": "2026-04-20T10:00:00+08:00", "reason": "..." }
    ]
  }
}
```

`done` 与 `abandoned`（wiki 侧 status）象限**不出现在报告里**——已被过滤。

---

## 关系与不变量

- 一个 `Run` 1:1 对应一个 `Idea`（按 `idea_slug` 关联）。允许多 run 对应同一 idea，但需 user 显式确认重跑。
- 一个 `Run` 0..1 个 `Output`（中途 abandoned 则无 output）。
- `Output` 在 run 内（`runs/<id>/output.md`）与 wiki inbox 中各存一份，**git 是 run 内副本的版本历史**，wiki inbox 副本是投递快照。
- Queue items 按 `idea_slug` 唯一性约束：同一 `idea_slug` 在 `in_flight` 与某季 `done` 中可能并存（已投递但 wiki 未消化时不算），但 MVP 不强制查重，靠脚本调用顺序保证。
