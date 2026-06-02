# 研究能力总流程卡 v0.8

定位：以 `research-state.md` 作为 run 的当前状态主线，用每轮 `search-round-N.md` 记录证据与 state delta，最后通过 memo 收口到 output。
目标：拿到一个主题后，围绕真实问题快速建立 state、用搜索更新 state、在证据足够时转成行动。

---

## 1 道门 + memo review + done

| 节点 | 标志产物 | 动作 |
|---|---|---|
| **opening** | `notes/research-state.md` + `notes/state-history/research-state-opening.md` | `Update-QueueGate -RunId <id> -Gate opening` |
| **memo review** | `notes/state-history/research-state-pre-memo.md` + `notes/memo.md` | 交用户审阅确认，不是 queue gate |
| **done** | `output.md` | `Update-QueueGate -RunId <id> -Gate done` |

`midway` 是旧流程 gate。新 run 不再调用 `Update-QueueGate -Gate midway`。

---

## 主线

1. **开题：建初始 state**
   - 初始化 `notes/research-state.md`。
   - 保存 `notes/state-history/research-state-opening.md`。
   - 只要求能安全进入第一轮搜索，不要求所有 slot 都 confirmed。

2. **搜索：每轮更新 state**
   - 先委托检索子 agent 执行双轨搜索，母 agent 只接收压缩结果。
   - 写 `sources/search-round-N.md`。
   - 在 `search_round_summary.state_delta` 说明本轮改变了什么。
   - 更新 `notes/research-state.md`。
   - 保存 `notes/state-history/research-state-rNN.md`。
   - 给出 `continue_search / pivot / ask_user / write_memo / stop` 建议。

3. **收口：pre-memo state → memo**
   - 当建议进入 memo 且用户确认后，保存 `research-state-pre-memo.md`。
   - 写 `notes/memo.md`，确认 enoughness 和 action boundary。
   - memo 经用户审阅后才写 output。

4. **完成：output**
   - output 面向读者，结论先行。
   - 不展示过程 state。
   - 写完后过 done。

> 记忆口令：**先建 state；委托搜索；搜索后更新 state；memo 前确认 enoughness；output 只写最终稿。**

---

## 每轮搜索快检

1. 这轮搜索回应了哪个 state gap？
2. 本轮是否由检索子 agent 完成，或是否在 `source_notes` / `备注` 说明了 fallback？
3. 本轮发现改变了哪个 slot / facet？
4. 哪些值从 `temporary` 变成 `confirmed`，哪些仍是 `unresolved`？
5. 当前证据足够支持什么，不足以支持什么？
6. 下一步应该 continue、pivot、ask_user、write_memo，还是 stop？

任一答不清，就不要进入下一轮或 memo。

---

## 用户阻塞点

以下情况必须暂停给用户确认：

- `agent_recommendation = pivot`
- `agent_recommendation = write_memo`
- `agent_recommendation = stop`
- `action_boundary` 扩张
- high-impact + user-only 缺口
- 两个 scope 会导向不同 output

---

## Legacy 兼容

旧 run 可能已有：

- `notes/task-card.md`
- `notes/judgment.md`
- `current_gate = midway`

恢复旧 run 时，不批量迁移。若没有 `notes/research-state.md`，按需从旧文件做 legacy import，生成：

```text
notes/research-state.md
notes/state-history/research-state-legacy-import.md
```

导入值的 `basis` 使用 `legacy_doc`，不得自动标成用户刚刚确认。
