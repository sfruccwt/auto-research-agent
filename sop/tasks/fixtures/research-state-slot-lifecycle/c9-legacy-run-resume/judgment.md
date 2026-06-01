# Legacy judgment fixture

## 当前研究问题

`research-state.md` 是否能替代旧阶段文档，并驱动每轮搜索更新？

## 第一轮地图

- `task-card.md` 负责 opening。
- `judgment.md` 负责第一轮后的判断。
- `memo.md` 负责 output 前收口。

## 当前判断

`task-card.md` 和 `judgment.md` 可以作为 legacy import 来源，不应作为新 run active artifact。

## 判断成立依赖的前提

- 每轮 `search-round-N.md` 必须写 `state_delta`。
- `memo.md` 必须保留 enoughness 和 action boundary review。

## 最短证据链

- 旧字段可映射到 `origin_context`、`objective`、`scope_boundary`、`search_plan`、`enoughness`。

## 竞争判断

- 新老并存。
- 直接删除旧模板。

## 待证点列表

- legacy import 是否能保留旧 run 信息。
- `midway` gate 是否只作为 legacy 状态。

## 第二轮只补什么

只补 legacy resume 和 gate 重绑定。
