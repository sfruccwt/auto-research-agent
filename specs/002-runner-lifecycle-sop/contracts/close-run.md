# Contract: close-run.ps1（新建）

轻量结项：记录结论、标记 run 为 closed，不投递到 wiki inbox。

## Invocation

```
pwsh scripts/close-run.ps1 -RunId <run-id> -Summary <string> -Reason <string> [-NextSteps <string>]
```

| 参数 | 默认值 | 说明 |
|---|---|---|
| `-RunId` | （必填） | run 目录名 |
| `-Summary` | （必填） | 结论摘要（1-3 句话） |
| `-Reason` | （必填） | 不投递原因 |
| `-NextSteps` | `""` | 后续方向建议（可选） |

## Behavior

1. 校验 `runs/<RunId>/` 目录存在
2. 校验该 run 不在 `queue/done/` 中（已投递的 run 不能再 close）
3. 在 `runs/<RunId>/notes/` 下写入 `closing-summary.md`：
   ```markdown
   # 结项总结

   ## 结论摘要
   <Summary>

   ## 不投递原因
   <Reason>

   ## 后续方向建议
   <NextSteps，为空则写"无">

   ## 关联
   - 派生 idea: （由 Claude 后续补填）
   - 母课题: （由 Claude 后续补填）
   ```
4. 在 `runs/<RunId>/log.md` 追加：
   ```
   YYYY-MM-DD HH:MM | event=closed | reason=<Reason 前 50 字符>
   ```
5. 在 `queue/closed/<YYYY-QN>.json` 追加一条 item：
   ```json
   {
     "run_id": "<RunId>",
     "idea_slug": "<从 RunId 或 idea.md 推断>",
     "closed": "<ISO 8601>",
     "summary": "<Summary>",
     "reason": "<Reason>"
   }
   ```
6. 从 `queue/in_flight.json` 移除对应 run_id（如存在）
7. 输出 `closing-summary.md` 的绝对路径到 stdout

## Exit codes

- `0` — 正常
- `1` — RunId 对应目录不存在
- `2` — 本地 queue JSON 写入失败
- `3` — 该 run 已投递（不允许 close 已 delivered 的 run）

## 不做的事（明确）

- 不删除 run 中的任何中间产物（FR-108）
- 不修改 idea 文件的状态
- 不阻止从任何中间状态转入 closed（FR-105）
- 不创建 output.md
