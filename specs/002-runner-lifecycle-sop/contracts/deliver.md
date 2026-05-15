# Contract 变更: deliver.ps1

**变更类型**: 小幅修改（支持 closed → delivered 状态迁移）

## Invocation

不变。

## Behavior 变更

### Step 7 扩展: 处理 closed → delivered 迁移

在原有 Step 7（Remove from in_flight）之后，增加：
- 检查 `queue/closed/` 中是否有该 RunId 的记录
- 有则调用 `Remove-QueueClosed -RunId $RunId` 移除

**目的**: 当用户对一个已轻量结项的 run 说"正式投递"时，Claude 生成 output.md 后调用 deliver.ps1。此时 run 不在 in_flight 中（Remove-QueueInFlight 静默无操作），但在 closed 中，需要清理。

### 其他

无变更。output.md 的 frontmatter `source_idea` 字段现在可以是本地池路径（如 `ideas/2026-05-10-topic.md`），deliver.ps1 不校验该路径的有效性（只透传），不受影响。
