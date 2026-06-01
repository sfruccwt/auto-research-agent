# 阶段 1：开题（opening 门前）

> 适用：从 `run_init` 到 `gate=opening` 通过之前。开题状态写入 `notes/research-state.md`。

---

## 研究是为了什么

研究的目的通常只有三种：

1. 支持一个决定
2. 推进一个项目
3. 解决一个真实问题

研究开始前，先把问题改写成这种形式：

- 我到底要决定什么？
- 我到底要推进什么？
- 我到底卡在什么问题上？

---

## 初始化 research state

opening 阶段必须创建：

```text
notes/research-state.md
notes/state-history/research-state-opening.md
```

`notes/research-state.md` 使用 `sop/template-research-state.md`。opening 只要求能安全进入第一轮搜索，不要求所有 slot 都 confirmed。

最低要求：

- `origin_context.initial_topic`：原始主题和用户表达。
- `objective.research_question`：把“研究 X”改写成“为了做 Y，需要回答 Z”。
- `scope_boundary`：当前回答什么、不回答什么、动作上限是什么。
- `search_plan.first_round`：第一轮为什么搜、先开哪些来源面。
- `enoughness.stop_criteria`：什么情况下可以停止继续搜索。

---

## 关键词压测

对“要回答的问题”中每个关键词做范围确认：

- **主语**：谁？例如“人机协作”里是谁在协作。
- **领域**：在哪？例如软件开发、办公、创意工作。
- **动作**：做什么？例如信任代码质量、判断正确性、执行建议。

如果缺口属于 high-impact + user-only，并且没有安全默认值，先问用户。
如果缺口可以通过搜索补齐，记录到 `search_plan.first_round`，不要马上追问用户。

---

## 开题门检查

通过 opening 前，必须写清：

- 这轮到底要支持什么决定 / 项目 / 问题。
- 当前至少要比较哪几条路径 / 动作。
- 明确不回答什么。
- 第一轮搜索要解决哪些 searchable gap。
- 哪些关键项只是 `temporary` 或 `unresolved`。

**不开 opening 门，不开搜。**

---

## 过门：opening

写完 `notes/research-state.md` 并保存 `notes/state-history/research-state-opening.md` 后，执行：

```powershell
Update-QueueGate -RunId <id> -Gate opening
```

然后重读 `sop/stages/0-global.md` + `sop/stages/2-research.md`，进入搜索、状态更新与收尾阶段。
