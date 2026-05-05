# Quickstart: 跑通第一个 idea

走一遍 P1（端到端单 idea）的典型流程，作为 MVP 验收脚本。

## 前置

- 本工作区已初始化（spec/plan/scripts 都已落地）
- wiki 中至少有一个 `status: pending` 的 idea，例如 `D:/Personal LLM Wiki/research/ideas/2026-05-01-modernity-wang-minan-thirteen-lectures.md`
- 4 个脚本就位：`scripts/{scan-and-align,new-run,deliver,queue}.ps1`

## 操作

### 1. 看有什么可跑

```
你 → "有什么可以跑"
runner → 调 scripts/scan-and-align.ps1，呈报 alignment report
```

预期：列出 wiki 中所有 `pending` 且本地无记录的 idea，按四个迁移 idea 至少能看到。

### 2. 启动一个 run

```
你 → "跑现代性那个"
runner → 调 scripts/new-run.ps1 -IdeaPath <path>
```

预期：`runs/2026-05-01-modernity-wang-minan-thirteen-lectures/` 创建，含 `idea.md`（冻结快照）+ `log.md`（init 行），`queue/in_flight.json` 多一项。

### 3. 过开题门

```
runner → Read sop/workflow.md, sop/flow-card.md, sop/templates.md
runner → 按 SOP 起草研究任务卡，写入 runs/<id>/notes/task-card.md
runner → 呈给 user 看，等显式信号
你 → "OK，开题门过"
runner → 在 log.md 追加 event=gate_passed | gate=opening | by=user
```

### 4. 第一轮研究 + 中途门

```
runner → 用 agent-reach 搜索建图，按 SOP 第二步 / 第三步 / 第四步
runner → 写 runs/<id>/notes/judgment.md
runner → 呈给 user 看，等显式信号
你 → "中途门过"
runner → log.md 追加
```

### 5. 第二轮 + 收尾门 + 草稿

```
runner → 第二轮补关键缺口
runner → 写 notes/memo.md（按 SOP 模板 3）
runner → 等用户确认收尾门后，合成 runs/<id>/output.md（按 templates/inbox-output.md 渲染 frontmatter）
你 → 提修改意见
runner → 改 output.md（git commit 留痕）
... 多轮直到你认可
你 → "收尾门过，可以投了"
runner → log.md 追加
```

### 6. 投递

```
runner → 调 scripts/deliver.ps1 -RunId <id>
```

预期：
- `D:/Personal LLM Wiki/sources/notes/inbox/2026-05-01-modernity-...md` 出现
- 该文件 frontmatter 有 `source_idea` 反向引用
- `queue/done/2026-Q2.json` 多一项
- `queue/in_flight.json` 移除该项
- `runs/<id>/log.md` 多 `event=delivered` 行

### 7. 确认对齐生效

```
你 → "再扫一下"
runner → 调 scan-and-align
```

预期：刚跑完那个 idea 不再出现在 `runnable`，转到 `awaiting_ingest`（因为 wiki 那边还没 INGEST）。

## 验收标准

满足 spec SC-001 ~ SC-006 中至少：
- SC-001：单次会话内拿到第一版 draft（`output.md` 已写）
- SC-003：output.md 100% 含来源引用
- SC-005：跑期间未触碰 wiki `inbox/` 之外的任何位置
- SC-006：信息缺失时 output.md 显式标记，无编造
