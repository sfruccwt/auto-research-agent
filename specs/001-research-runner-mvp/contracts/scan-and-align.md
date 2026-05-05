# Contract: scan-and-align.ps1

扫描 wiki 全部 idea，与本地 queue 状态对齐，输出 alignment report。

## Invocation

```
pwsh scripts/scan-and-align.ps1 [-WikiRoot <path>] [-AsJson]
```

| 参数 | 默认值 | 说明 |
|---|---|---|
| `-WikiRoot` | `D:/Personal LLM Wiki` | wiki 根目录 |
| `-AsJson` | `$true` | 输出 JSON（MVP 唯一支持的格式） |

## Behavior

1. 列出 `<WikiRoot>/research/ideas/*.md` 与 `<WikiRoot>/research/ideas/done/*.md`
2. 逐个读 frontmatter（YAML）的 `status` 字段
3. 读本地 `queue/done/*.json` 与 `queue/abandoned/*.json` 全部 items
4. 按 spec FR-022 表分类：
   - `wiki_status=pending` & 无本地记录 → `runnable`
   - `wiki_status=pending` & 本地有 done 记录 → `awaiting_ingest`
   - `wiki_status=pending` & 本地有 abandoned 记录 → `previously_abandoned`
   - `wiki_status=done` 或 `abandoned` → 过滤，不出现在报告
5. 输出 JSON 到 stdout（schema 见 `data-model.md` Alignment Report 节）

## Exit codes

- `0` — 正常
- `1` — wiki 路径不存在或不可读
- `2` — 本地 queue JSON 解析失败

## 不做的事（明确）

- 不缓存。每次全量扫。
- 不 flag "wiki done 但本地无记录" 的异常（按 spec 已被过滤）。
- 不写任何文件。
