# C5 fixture：第一轮搜索后 pivot

## search_intent

- 本轮为什么搜: 验证 opening clarification 是否应该直接加问题。
- 对应 state gap: 不清楚缺口应先问用户还是先搜索。
- 本轮不做什么: 不修改 SOP。

## key_findings

- 关键不是问更多澄清问题，而是先把缺口拆成 searchable gap 与 user-only gap。
- searchable gap 可以通过预搜索降低用户负担。
- user-only gap 只有在会改变 output 或 action boundary 时才需要暂停问用户。

## search_round_summary

### state_before

`sop/tasks/fixtures/research-state-slot-lifecycle/c5-pivot-after-round-1/research-state-before.md`

### state_delta

| slot / facet | before | after | resolution_state | update_reason |
|---|---|---|---|---|
| objective | 是否增加更多 opening clarification | 设计 searchable gap / user-only gap 分流机制 | temporary | 第一轮发现方向应从“多问问题”转向“先预搜索后定焦” |
| inquiry_shape | opening clarification question 数量 | clarification 与预搜索的协作机制 | temporary | 问题对象发生变化 |

### state_after

`notes/state-history/research-state-r01.md`

### new_gaps

| 缺口 | 类型 | next_action | 说明 |
|---|---|---|---|
| 分流机制如何写进 SOP | searchable | search_next | 需要补流程细节 |
| 用户是否接受 pivot | user_only | ask_user | pivot 会改变本轮研究目标 |

### enoughness_current

- 当前证据足够支持什么: 足够支持提出 pivot。
- 当前证据不足以支持什么: 不足以直接改 SOP。
- 是否足够进入 memo: 否。

### next_search_options

- continue_search: 继续补 SOP 写法。
- pivot: 转向 gap 分流机制。
- ask_user: 请用户确认 pivot。
- write_memo: 否。
- stop: 否。

### agent_recommendation

`pivot`

### required_user_confirmation

- pivot 改变了 objective，必须暂停给用户确认。
