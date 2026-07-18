# 阶段 2：搜索、状态更新与收尾（opening → done）

> 适用：opening 门通过后，直到研究完成。每轮搜索都更新 research state；新 run 不推进 legacy midway gate。

---

## 每轮搜索的固定产物

每一轮搜索都必须产生：

```text
sources/search-round-N.md
sources/search-round-N-human.md
notes/research-state.md
notes/state-history/research-state-rNN.md
```

顺序固定：

1. 根据当前 `research-state.md` 明确本轮 `search_intent` 和要补的 state gap。
2. 委托检索子 agent 执行搜索；母 agent 默认不直接调用 `agent-reach`、Chrome/browser 或 WebSearch。
3. 检索子 agent 必须执行强制双轨，并只返回结构化压缩结果和 URL 清单，不返回原始工具输出。
4. 按 `sop/template-search-round.md` 写 `sources/search-round-N.md`，用子 agent 返回的压缩结果填写现有字段。
5. 按 `sop/template-search-round-human.md` 写 `sources/search-round-N-human.md`，基于同轮问题和发现生成面向人的阅读摘要。
6. 在 `search_round_summary.state_delta` 里说明本轮改变了哪些 slot / facet。
7. 更新 `notes/research-state.md`。
8. 保存完整快照到 `notes/state-history/research-state-rNN.md`。
9. 给出 `agent_recommendation`：`continue_search / pivot / ask_user / write_memo / stop`。

---

## 检索面设计

`research-state.md` 只记录要开的来源面和搜索意图，不记录默认工具分配。强制双轨检索规则由 `AGENTS.md` 注入：检索时必须同时使用 `agent-reach lane` 和 `browser route lane`。

每轮实际使用的工具通道写入 `sources/search-round-N.md` 的 `queries_and_sources.检索通道`，不写入 `research-state.md`。每轮搜索都应在 `search_round_summary.state_delta` 中说明 browser route lane 是否改变了 slot / facet；没有新增也要写明未改变。browser route lane 产生的登录态、个性化、站点风控限制、截图原因、Chrome extension 触发条件或 skipped/fallback 原因，写入 `source_notes`。

`sources/search-round-N-human.md` 是人类阅读层，只按本轮问题组织发现、关键依据和简要结论。它不复制 `queries_and_sources`、`source_notes` 或 `search_round_summary` 表格，不承担状态迁移职责，也不替代 `research-state.md`。

母 agent 不得把检索子 agent 的原始工具输出、网页全文转储或无筛选搜索列表粘贴进 `sources/`、`notes/` 或 `output.md`。如果 Agent / sub-agent 工具不可用，在 `source_notes` 或 `queries_and_sources.备注` 写明 fallback 原因。

常用来源面：

- 官方 / 原始
- 市场 / 新闻
- 学术
- 社区 / 案例

每一面要说明角色：

- 哪些面负责第一轮建图。
- 哪些面负责找现实摩擦 / 原始规则 / 动作条件。
- 哪些面只在后续轮次补关键缺口时开启。
- 哪些面只能当线索，不能直接支撑判断。

---

## 搜索——建立全貌

目标是：

- 看看大家怎么讨论这个问题。
- 找到主流观点 / 路径 / 方案。
- 发现自己还缺哪些背景信息。
- 让问题本身变得更清楚。

看到成熟观点后，不要只收藏链接。至少拆成：

1. 它的结论是什么。
2. 它的逻辑链条是什么。
3. 它的支撑事实 / 数据 / 例子是什么。
4. 它依赖哪些前提。

---

## 主动找反对意见和攻击点（硬要求）

如果有一个观点 A：

- 看支持它的人在说什么。
- 也必须看反对它的人在攻击什么。

重点问：

- 反对方是在打逻辑，还是在打事实？
- 反对方打到的是边缘点，还是核心前提？
- 这些攻击成立吗？

反对意见通常更切中要害，能帮助识别哪些因素更主导、哪些理由只是表面上有说服力、哪些结论在关键前提上其实很脆弱。

---

## Motivation 持续校准

用户看到搜索结果后才可能联想到关键约束。每轮搜索后都检查：

- 这些发现跟用户实际处境 / 动机有什么关系？
- 有没有用户之前没提到、但会改变搜索方向或 action boundary 的约束？

用户补充的约束写回 `notes/research-state.md` 的 `origin_context.user_feedback`，并在 `change_log` 记录。

---

## 子课题拆分（持续触发）

研究过程中发现需要独立搜索 / 验证的子问题时，即时向用户提示是否拆分。

候选子课题记录到：

```text
notes/research-state.md -> child_runs.candidates
```

必须写清：

- 对应缺口是什么。
- 影响哪个 slot。
- 是否已经问过用户。
- 子 run 完成后预计如何回填母 run。

---

## 每轮结束的用户阻塞点

出现以下情况必须暂停交给用户确认：

- `agent_recommendation = pivot`
- `agent_recommendation = write_memo`
- `agent_recommendation = stop`
- `action_boundary` 扩张
- high-impact + user-only 缺口
- 两个 scope 会导向不同 output

没有用户确认，不要自行扩大动作边界或进入 output。

---

## 后续轮次：只补关键缺口

只补会改变 state、路径排序或动作选择的缺口：

- 一手 / 高信任来源。
- 真正会改变路径比较结果的关键变量。
- 能确认或打掉竞争判断的证据。
- 机制 / 文献 / 方法层面的必要补证。

如果缺口不会改变 `research-state.md`、路径排序或 action boundary，优先 `defer`。

---

## 收口：pre-memo state → memo → 用户审阅 → output

当 `agent_recommendation = write_memo` 且用户确认后，先保存：

```text
notes/state-history/research-state-pre-memo.md
```

然后写 `notes/memo.md`。memo 面向研究者自己，是 output 前的最终 review，必须写清：

- 当前判断 + 最短证据链。
- enoughness：当前证据足够支持什么、不足以支持什么。
- action boundary：当前允许建议什么、不允许建议什么。
- 路径分流：推进 / 继续比较 / 暂缓 / 放弃。
- 最小下一步 + 暂不动作。
- 观察信号 + 推翻条件。

**memo 写完后必须交用户审阅确认，然后才能开始写 output。不得在同一轮动作中连续产出 memo 和 output。**

---

## output（`output.md`）

最终投递到 wiki inbox 的成品，由 memo 加工而来，面向读者。禁止将 memo 直接复制为 output。output 必须经过加工：

- 重组结构，从研究过程叙述改为结论先行。
- 补充对读者的上下文说明。
- 展开关键概念。
- 移除研究过程性内容。

output 中应明确：

- 当前结论 + 推荐路径。
- 最小下一步动作。
- 需要观察哪些信号。
- 哪些事实会推翻当前判断。

---

## 过门：done

写完 `output.md` 后，执行：

```powershell
Update-QueueGate -RunId <id> -Gate done
```

---

## 补查（可选）

output 交付后用户基于实践发现需补充细节时，在现有 run 目录修补 output.md，log.md 记录 `amendment | detail=<补了什么>`，重新 deliver。如果补查发现核心判断有误，按 rerun 处理。
