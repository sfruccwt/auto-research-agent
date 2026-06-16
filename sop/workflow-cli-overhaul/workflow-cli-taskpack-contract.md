# Handoff / Review packet 契约

状态：简化草案

## 0. 定位

旧 Taskpack 设想用于自动分发下一步任务。新的工作流不再依赖自动分发。

本文件只保留两个轻量契约：

- `handoff packet`：给 LLM 的明确人工指令包，可选。
- `review packet`：给用户审阅的 brief 视图。

二者都不是自动执行协议。

## 1. Handoff packet

Handoff packet 只在需要把任务交给另一个 agent / CLI 会话时使用。最小字段：

```yaml
handoff_packet:
  run_id:
  stage: opening | search_round | memo | output
  read:
    - <path>
  write_allowed:
    - <path>
  do_not_write:
    - queue/in_flight.json
    - runs/<run-id>/log.md
  expected_artifacts:
    - <path>
  user_review_required: true
```

规则：

- 不在 handoff packet 里替用户总结最终意图。
- 不把 packet 设计成自动推进命令。
- 写完产物后仍需要用户审阅或脚本 seal。

## 2. Opening review packet

Opening review packet 至少展示：

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

批准后写入 `notes/search-opening.md`，再由脚本 `seal opening`。

## 3. Round review packet

Round review packet 至少展示：

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

用户批准或修改后，下一轮 search round 才能开始。
