# Contract: queue.ps1

共享的 queue 读写函数库。其他三个脚本通过 dot-source 调用：

```powershell
. "$PSScriptRoot/queue.ps1"
```

不直接作为命令行入口（无 `-Json` 输出、无 main 块）。

## Exposed Functions

### `Get-QueuePending`
读 `queue/pending.json`，返回 PSCustomObject 数组（items 字段）。文件不存在返回空数组。

### `Get-QueueInFlight`
读 `queue/in_flight.json`，返回 PSCustomObject 数组。

### `Get-QueueDone [-Quarter <YYYY-QN>]`
读 `queue/done/<quarter>.json`。不指定 `-Quarter` 时合并读所有季度文件，返回平铺数组。

### `Get-QueueAbandoned [-Quarter <YYYY-QN>]`
同上，对 abandoned 目录。

### `Add-QueueDone -Item <hashtable>`
向当季 `queue/done/<YYYY-QN>.json` 追加一项。文件不存在自动创建（带 `version: 1`）。

### `Add-QueueAbandoned -Item <hashtable>`
向当季 `queue/abandoned/<YYYY-QN>.json` 追加一项。

### `Add-QueueInFlight -Item <hashtable>`
追加 in_flight 项。

### `Remove-QueueInFlight -RunId <string>`
从 in_flight 移除对应 run_id。

### `Get-CurrentQuarter`
返回当前季度字符串，形如 `2026-Q2`。供其他 Add-* 函数定位文件。

## Invariants

- 所有写入函数 MUST 保留 `version` 字段
- 写入采用"读 → 修改 → 整体覆盖写"模式（无锁，MVP 假设单进程）
- JSON 缩进 2 空格、UTF-8 无 BOM
- items 时间戳一律 ISO 8601 with timezone（如 `2026-05-01T17:32:00+08:00`）

## 不做的事（明确）

- 不维护 `queue/pending.json` 的写入函数（MVP 由 user 手动维护，runner 只读不写 pending）
- 不做去重 / 索引 / 锁定 / 事务
