# Contract 变更: scan-and-align.ps1

**变更类型**: 扩展（新增扫描范围和分类，保持向后兼容）

## 新 Invocation

```
pwsh scripts/scan-and-align.ps1 [-WikiRoot <path>] [-AsJson]
```

参数不变。

## Behavior 变更

### 新增 Step 1a: 扫描本地池

在 Step 1（扫描 wiki ideas）之后，增加：
- 列出 `ideas/*.md` 文件
- 读 frontmatter 的 `status` 字段

### 新增 Step 3a: 加载 closed 记录

在 Step 3（加载 done/abandoned）之后，增加：
- 读 `queue/closed/*.json` 全部 items，建立 `closedSlugs` 索引

### 新增 Step 3b: 扫描派生 idea

遍历 `runs/*/notes/derived-ideas.md`（如存在），解析每条记录，筛出 `child_run` 为空的条目。

### Step 4 扩展: 分类规则

在原有三类基础上新增三类：

| 新分类 | 条件 | 来源 |
|---|---|---|
| `runnable_local` | 本地池 idea，无对应 done/closed/abandoned 记录 | 本地池 |
| `derived_ideas` | 任意 run 的 derived-ideas.md 中 child_run 为空 | runs |
| `closed` | queue/closed/ 中的记录 | queue |

本地池 idea 有 done 记录 → `awaiting_ingest`（加 `source: local`）
本地池 idea 有 closed 记录 → `closed`
本地池 idea 有 abandoned 记录 → `previously_abandoned`（加 `source: local`）

### Step 5 扩展: 输出 JSON

输出增加 `local_ideas_count` 字段，`categories` 增加 `runnable_local`、`derived_ideas`、`closed` 三个数组。Schema 见 `data-model.md`。

## Exit codes

不变。

## 不做的事（延续 + 新增）

- 不做跨池去重检测（FR-104 备注）
- 不修改任何 idea 文件
- derived-ideas.md 解析失败时跳过该文件，不报错
