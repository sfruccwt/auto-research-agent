---
source: auto_research_agent
source_idea: research/ideas/<idea-filename>.md
captured: YYYY-MM-DD
route: wiki
route_reason: "one-line reason this is worth ingesting"
status: pending
---

# <Title>

<Body — content-finalized prose with inline source citations. No wikilinks, no Related section.>

## 来源

<编号列表，每条包含：简称、作者/机构、标题、年份、可直达 URL。学术论文优先用出版商/会议网页版（openreview.net、aclanthology.org 等），arXiv 作为备选。>

---

## 写作规范

### 引用格式
- 正文中用数字脚注标注引用位置（如 `[1]`、`[2,3]`），每句论断直接标注对应来源编号
- 来源列表按编号排序，每条之间空一行，格式：
  ```
  [N] 作者/机构. "标题." 会议/年份.
      URL: example.com/path
  ```
- URL 显式写出网址，不用 markdown 超链接
- 学术论文优先用出版商/会议网页版，arXiv 作为备选
- 中途搜索笔记（sources/search-round*.md）同样使用数字脚注引用，正文标 `[N]`，文末附编号来源列表含 URL

### 后置检查（output 定稿前必做）
- 检查正文是否有语义明显不连贯的翻译（如 agent→代理、token→令牌），回查是否为专有术语误翻译
- 确认每条正文引用都能在来源列表中找到对应条目
