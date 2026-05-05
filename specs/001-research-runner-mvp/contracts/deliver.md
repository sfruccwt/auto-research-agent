# Contract: deliver.ps1

把 run 的 `output.md` 投递到 wiki inbox，更新本地 done 记录，从 in_flight 移除。

## Invocation

```
pwsh scripts/deliver.ps1 -RunId <run-id> [-WikiRoot <path>]
```

| 参数 | 默认值 | 说明 |
|---|---|---|
| `-RunId` | （必填） | 形如 `2026-05-01-modernity-...` |
| `-WikiRoot` | `D:/Personal LLM Wiki` | wiki 根目录 |

## Behavior

1. 校验 `runs/<RunId>/output.md` 存在且非空
2. 解析其 frontmatter，校验必含字段：`source`、`source_idea`、`captured`、`route`、`route_reason`、`status`
3. 计算目标路径 `<WikiRoot>/sources/notes/inbox/<YYYY-MM-DD>-<slug>.md`：
   - `<YYYY-MM-DD>` 取自 frontmatter `captured`
   - `<slug>` 取自 RunId（去日期前缀）或 frontmatter 显式字段（如有）
4. 同名冲突时自动加后缀：`<slug>-2.md`、`<slug>-3.md` ...
5. 把 `runs/<RunId>/output.md` 拷到目标路径
6. 在 `queue/done/<YYYY-QN>.json` 追加一条 item（含 run_id / idea_slug / delivered 时间戳 / inbox_path）
7. 从 `queue/in_flight.json` 移除对应 run_id
8. 在 `runs/<RunId>/log.md` 追加一行 `event=delivered | inbox=<path>`
9. 输出投递目标路径到 stdout

## Exit codes

- `0` — 正常
- `1` — RunId 对应目录不存在 / output.md 不存在或为空
- `2` — frontmatter 缺必需字段
- `3` — wiki inbox 目录不存在或不可写
- `4` — 本地 queue JSON 写入失败

## 不做的事（明确）

- 不修改源 idea 文件（spec FR-018）
- 不修改 wiki 中除 inbox 外的任何位置
- 不主动通知 wiki INGEST——投递就完事，runner 不关心后续
