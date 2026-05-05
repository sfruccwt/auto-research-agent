# Contract: new-run.ps1

为指定 idea 创建一个新 run 工作目录，冻结 idea 快照，初始化 log。

## Invocation

```
pwsh scripts/new-run.ps1 -IdeaPath <path> [-Force]
```

| 参数 | 默认值 | 说明 |
|---|---|---|
| `-IdeaPath` | （必填） | wiki 中 idea 文件的绝对或相对路径，例如 `D:/Personal LLM Wiki/research/ideas/2026-05-01-modernity-...md` |
| `-Force` | `$false` | 已对该 idea 投递过时是否仍创建新 run。默认拒绝并报错；带 `-Force` 时绕过检查 |

## Behavior

1. 校验 `IdeaPath` 存在且是 .md 文件
2. 解析 `idea_slug = <basename without .md>`，`run_id = $idea_slug`（MVP：用 idea slug 直接作 run id；同 idea 重跑由 `-Force` + 自动 +N 后缀处理）
3. 检查 `queue/done/*.json` 是否含此 idea_slug：
   - 是，且未带 `-Force`：报错退出（exit 3），提示用户该 idea 已投递过
   - 是，且带 `-Force`：`run_id = $idea_slug-rerun-<N>`（N 取下一个空闲序号）
4. 创建目录 `runs/<run_id>/`，子目录 `notes/`、`sources/`
5. 复制 idea 文件到 `runs/<run_id>/idea.md`（冻结快照）
6. 写入 `runs/<run_id>/log.md`，第一行：
   ```
   YYYY-MM-DD HH:MM | event=run_init | idea=<basename>
   ```
7. 在 `queue/in_flight.json` 追加一条 item（current_gate 设 `opening`）
8. 输出 run 目录绝对路径到 stdout

## Exit codes

- `0` — 正常
- `1` — IdeaPath 不存在或不是 .md
- `2` — 本地 queue JSON 写入失败
- `3` — 该 idea 已投递过且未带 `-Force`

## 不做的事（明确）

- 不读 wiki idea frontmatter 之外的任何 wiki 内容
- 不启动研究——研究是 Claude 在对话中接管
- 不创建空的 `output.md`（由 Claude 在草稿阶段第一次 Write 创建）
