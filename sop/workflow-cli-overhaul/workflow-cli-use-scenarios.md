# Workflow CLI 使用场景

状态：简化草案

## 0. 定位

本文件记录用户如何使用半自动 research runner。它不是技术实现文档。

## 1. 启动一个 run

用户给出研究意图后，系统只做 startup：

```text
保存 raw intake
创建 run
报告 ready for opening
```

之后由 LLM 生成 opening brief 和 `notes/search-opening.md`，用户审阅后才进入首轮检索。

## 2. 审阅 opening

用户看到 Opening brief：

- `user_intent`
- `research_object`
- `operation_type`
- `scope_boundary`
- `use_intent`
- `output_shape / action_boundary`
- `source_surfaces`
- `first_search_questions`
- `stop_when`
- `temporary_or_default_fields`

用户可以：

- 批准。
- 修改理解或范围。
- 修改首轮检索问题。
- 缩小 action boundary。

批准后脚本 `seal opening`，首轮 search round 才能开始。

## 3. 审阅每轮 search round

每轮结束后，用户看到 Round N brief：

- `original_intent`
- `previous_search_intent`
- `what_this_round_found`
- `enough_for`
- `not_enough_for`
- `state_changed`
- `remaining_gaps`
- `proposed_next_round`
- `recommendation`
- `user_decision_needed`

用户可以：

- 批准下一轮。
- 修改下一轮计划。
- 要求 pivot。
- 拆子 run。
- 判断已经足够进入 memo。

## 4. 继续一个 run

恢复时先看状态：

- 是否已经 seal opening。
- 最近一个 sealed round 是哪一轮。
- 是否正在等待用户审阅。
- 是否已有 memo / output。

恢复不自动继续执行 search。它只把当前 review point 呈现给用户。

## 5. 收口

当用户认为证据足够时：

```text
Round N brief
  -> 用户选择进入 memo
  -> LLM 写 notes/memo.md
  -> 用户确认 memo
  -> LLM 写 output.md
  -> done gate
  -> deliver 或 close
```
