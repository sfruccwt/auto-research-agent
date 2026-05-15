# Contract 变更: queue.ps1

**变更类型**: 扩展（新增函数，不修改已有函数）

## 新增函数

### `Add-QueueClosed -Item <hashtable>`

向当季 `queue/closed/<YYYY-QN>.json` 追加一项。文件不存在自动创建（带 `version: 1`）。

Item schema:
```json
{
  "run_id": "string",
  "idea_slug": "string",
  "closed": "ISO 8601",
  "summary": "string",
  "reason": "string"
}
```

### `Get-QueueClosed [-Quarter <YYYY-QN>]`

读 `queue/closed/<quarter>.json`。不指定 `-Quarter` 时合并读所有季度文件，返回平铺数组。与 `Get-QueueDone` 完全对称。

### `Remove-QueueClosed -RunId <string>`

从 `queue/closed/` 所有季度文件中移除指定 run_id 的记录。用于 closed → delivered 状态迁移时调用。

## 已有函数

不修改。

## 不做的事

- 不维护跨状态一致性（如 closed 和 done 互斥由调用方保证）
