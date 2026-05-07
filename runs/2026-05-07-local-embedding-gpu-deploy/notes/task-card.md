# 研究任务卡

## 主题
本地小型 embedding 模型（Qwen3-Embedding-0.6B）GPU 部署全流程

## 交付对象
用户自己——用于本地 RAG 检索验证

## 这次真正要支持的决定 / 动作
给出从零到能用的完整操作步骤，让用户可以照着做

## 这次真正要回答的问题
把一个小型 embedding 模型部署到本地 GPU 并能调用出 embedding 向量，完整 workflow 是什么？

## 当前待比较路径 / 候选动作
- 路径 A：sentence-transformers 一把梭（最终选定）
- 路径 B：Ollama serving
- 路径 C：transformers + PyTorch 原生

## 输出模式
- [x] 执行线索

## 明确不回答什么
- 不评估"是否值得部署"
- 不做推理框架对比
- 不做生产级部署方案

## 优先开的检索面
- [x] 官方 / 原始资料（HuggingFace 模型卡）
- [x] 社区 / 案例 / 一线经验

## 本轮动作上限（先预设）
- [x] 给出最小下一步

## 本轮收尾门槛
- 用户确认 workflow 可执行
