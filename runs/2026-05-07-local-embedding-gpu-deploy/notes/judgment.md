# 判断单

## 当前研究问题
如何在本地 Windows 机器（RTX 3060 笔记本）上部署 Qwen3-Embedding-0.6B 到 GPU，用于 RAG 检索

## 第一轮地图
- 关键变量：GPU 驱动/CUDA 版本兼容性、模型选择、加载方式、VRAM 占用
- 主要路径：sentence-transformers / Ollama / transformers 原生
- 关键约束：Windows 平台、"能用就行"的验证需求
- 现实摩擦 / 动作条件：PyTorch CUDA 版本对齐是最常出问题的环节
- 显著分歧：是否需要单独安装 CUDA Toolkit（现代 PyTorch 自带运行时）
- 当前未知：用户具体驱动版本（通过反问获得 GPU 型号）

## 当前判断
- 我目前倾向认为：路径 A（sentence-transformers）是最短路径
- 当前最值得继续看的路径：路径 A，因为 Qwen3-Embedding-0.6B 官方直接支持
- 这个判断成立依赖的前提：模型官方支持 sentence-transformers >= 2.7.0

## 最短证据链
- 当前判断：sentence-transformers 3 行代码即可加载并使用
- 最强依据：Qwen3-Embedding-0.6B 官方模型卡直接给出了 sentence-transformers 用法
- 原始出处 / 来源：https://huggingface.co/Qwen/Qwen3-Embedding-0.6B
- 来源层级：官方 / 原始

## 竞争判断
- 竞争判断 A：用 transformers 原生方式更灵活（但需自写 pooling，对验证场景多余）
- 竞争判断 B：用 Ollama 更省心（但多一层 serving，对简单验证过重）

## 第二轮只补什么
- Qwen3-Embedding-0.6B 的完整代码示例（已从模型卡获取）
- query vs document 的 instruction 差异（已确认：query 加 prompt_name="query"，document 不加）
