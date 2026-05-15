# Data Model: Runner Lifecycle & SOP Refinement

**Feature**: 002-runner-lifecycle-sop | **Date**: 2026-05-10

---

## Entity: Idea（扩展）

### 新增：本地池 Idea 文件

**位置**: `ideas/<YYYY-MM-DD-slug>.md`

**Frontmatter schema**: 复用 Wiki idea 的 schema，保持两池结构一致。

```yaml
---
source: runner-local                    # 区别于 wiki 的 "随手记" 等来源
source_file:                            # 可空（口述创建无源文件）
captured: YYYY-MM-DD                    # 创建日期，与 wiki 同名字段
route: research                         # 固定 research
route_reason: "<一句话说明为什么值得研究>"
status: pending                         # pending | done
---
```

**Body**: 用户口述的研究主题描述（以 `# <标题>` 开头，后跟正文）。

**设计理由**: 与 Wiki 池使用同一套 frontmatter schema，好处有三：
1. 扫描对齐脚本只需一套解析逻辑
2. 用户想迁移本地 idea 到 Wiki 时，直接移文件即可
3. `source: runner-local` 足以区分来源，不需要额外字段

**与 Wiki 池的区别**:

| 属性 | Wiki 池 | 本地池 |
|---|---|---|
| 位置 | `D:/Personal LLM Wiki/research/ideas/` | `ideas/` |
| 管理方 | wiki INGEST | runner / 用户 |
| frontmatter | 同一 schema | 同一 schema（`source` 值不同） |
| 生命周期 | 长期孵化，跨项目 | 临时，与当前工作直接相关 |
| runner 写权限 | 无（只读） | 有（可创建） |

---

## Entity: Run（扩展）

### 状态机扩展

```
created → researching → drafting → revising → delivered
                                             → closed     ← 新增
                                             → abandoned
```

`closed` 可从**任何中间状态**转入（FR-105），不限于 revising。

### 目录约定

| 子目录 | 用途 | 示例文件 |
|--------|------|---------|
| `notes/` | runner 的工作文档（任务卡、判断单、备忘录等） | `task-card.md`, `judgment.md`, `memo.md` |
| `sources/` | 检索结果与外部材料 | `search-round1.md`, `search-round2.md` |

### 新增文件

#### `runs/<id>/notes/closing-summary.md`

轻量结项时的总结产物。

```markdown
# 结项总结

## 结论摘要
[1-3 句话]

## 不投递原因
[为什么不适合产出正式 output]

## 后续方向建议
- 

## 关联
- 派生 idea: 
- 母课题: 
```

#### `runs/<id>/notes/derived-ideas.md`

母课题 run 过程中派生出的新研究点。追加式文件。

**单条记录格式**:

```
---
title: <标题>
description: <一句话描述>
relation: <与母课题的关系>
recorded: <ISO 8601>
child_run: 
---
```

字段说明：
- `title`: 派生 idea 的标题
- `description`: 一句话描述研究方向
- `relation`: 与母课题的关系（如"子概念需独立解释"、"发现的相邻问题"）
- `recorded`: 记录时间
- `child_run`: 当该派生 idea 被启动为新 run 后，回填 run-id

#### `runs/<id>/notes/child-results.md`（可选）

子课题完成后，用户指示将结论回填到母 run 时使用。由 Claude 在对话中创建和写入。

```markdown
# 子课题结论回填

## <子 run-id>: <主题>
- 关键结论: 
- 产出位置: runs/<子run-id>/output.md 或 closing-summary.md
- 回填时间: <ISO 8601>
```

### run 的 `idea.md` 扩展字段

当从派生 idea 启动新 run 时，`idea.md` frontmatter 新增：

```yaml
derived_from: <母 run-id>     # 来源 run
source_idea: ideas/<filename> # 或 wiki 路径
```

当从本地池启动时：

```yaml
source_idea: ideas/<filename>
```

当从 Wiki 池启动时（不变）：

```yaml
source_idea: D:/Personal LLM Wiki/research/ideas/<filename>
```

---

## Entity: Queue（扩展）

### 新增目录：`queue/closed/`

与 `queue/done/` 和 `queue/abandoned/` 并列。

**`queue/closed/<YYYY-QN>.json` schema**:

```json
{
  "version": 1,
  "items": [
    {
      "run_id": "string",
      "idea_slug": "string",
      "closed": "ISO 8601 timestamp",
      "summary": "string (结论摘要)",
      "reason": "string (不投递原因)"
    }
  ]
}
```

---

## Entity: Alignment Report（扩展）

`scan-and-align.ps1` 的输出 JSON schema 从 3 类扩展为 6 类：

```json
{
  "scanned_at": "ISO 8601",
  "wiki_ideas_count": 0,
  "local_ideas_count": 0,
  "categories": {
    "runnable": [
      { "idea_slug": "", "wiki_status": "", "source": "wiki" }
    ],
    "runnable_local": [
      { "idea_slug": "", "source": "local", "path": "ideas/<filename>" }
    ],
    "awaiting_ingest": [
      { "idea_slug": "", "wiki_status": "", "delivered": "" }
    ],
    "previously_abandoned": [
      { "idea_slug": "", "wiki_status": "", "abandoned": "", "reason": "" }
    ],
    "derived_ideas": [
      {
        "title": "",
        "description": "",
        "relation": "",
        "source_run": "",
        "recorded": ""
      }
    ],
    "closed": [
      {
        "run_id": "",
        "idea_slug": "",
        "closed": "",
        "summary": ""
      }
    ]
  }
}
```

---

## Entity: SOP 三件套（修订，非新建）

不新增实体。修改 `sop/workflow.md`、`sop/flow-card.md`、`sop/templates.md` 的内容，详见 contracts。
