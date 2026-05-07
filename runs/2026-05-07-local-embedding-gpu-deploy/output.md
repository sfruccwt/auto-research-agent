---
source: auto_research_agent
source_idea: adhoc (conversation, not from wiki)
captured: 2026-05-07
route: wiki
route_reason: "本地部署 embedding 模型到 GPU 的完整操作 workflow，从环境准备到验证，可直接复用"
status: pending
---

# 本地部署 Qwen3-Embedding-0.6B 到 GPU：完整 Workflow

本文记录从零开始在 Windows 本地环境中，将 Qwen3-Embedding-0.6B 部署到 NVIDIA GPU 上并用于 RAG 检索的完整操作流程。

## 背景与选型

**场景：** 本地 RAG 检索验证，不需要生产级 serving，能跑起来就行。

**模型选择：** Qwen3-Embedding-0.6B（约 0.6B 参数，支持 100+ 种语言，最大 8192 tokens，显存占用约 1.2GB）。

**加载方式选择：** 使用 sentence-transformers 库。原因：Qwen3-Embedding-0.6B 官方直接支持（需 sentence-transformers >= 2.7.0），3 行代码即可加载到 GPU 并生成 embedding。相比 transformers 原生方式（需自己写 last_token_pool 函数做 pooling）和 Ollama（多一层 serving 服务），sentence-transformers 对验证场景是最短路径。

## 操作步骤

### Step 0：确认 GPU 驱动状态

打开终端，运行：

```
nvidia-smi
```

看两个值：
- **Driver Version**（如 535.xxx）——有输出就说明驱动已安装
- **CUDA Version**（右上角，如 12.2）——这是驱动支持的最高 CUDA 版本，不是实际安装的 CUDA Toolkit

NVIDIA Ampere 架构（RTX 30 系列）及以上支持 CUDA 11.1+ 所有版本，不会有兼容性问题（来源：NVIDIA CUDA GPUs 兼容性列表 https://developer.nvidia.com/cuda-gpus）。

### Step 1：创建 Python 环境

```bash
# conda 方式
conda create -n embedding python=3.11 -y
conda activate embedding

# 或 venv 方式
python -m venv embedding_env
embedding_env\Scripts\activate
```

### Step 2：安装 PyTorch（CUDA 版）

根据 nvidia-smi 显示的 CUDA Version 选择对应的 PyTorch 安装命令。去 PyTorch 官网（https://pytorch.org/get-started/locally/）选配置，通常是：

```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
```

`cu121` 表示 CUDA 12.1。只要 nvidia-smi 显示的 CUDA Version >= 12.1 就能用。如果驱动较老显示 11.8，换成 `cu118`。

关键对齐关系：NVIDIA 驱动版本 → 驱动支持的最高 CUDA 版本 → PyTorch 编译时的 CUDA 版本。这三者的对齐是 GPU 版 PyTorch 安装失败的首要原因（来源：多个独立教程及 PyTorch 官方文档 https://pytorch.org/get-started/locally/）。

现代 PyTorch pip 包已经自带 CUDA 运行时库，通常不需要单独安装 CUDA Toolkit。

**验证 PyTorch GPU 可用性：**

```python
python -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"
```

应输出 `True` 和 GPU 名称（如 `NVIDIA GeForce RTX 3060 Laptop GPU`）。

### Step 3：安装 sentence-transformers

```bash
pip install "sentence-transformers>=2.7.0"
```

会自动安装 `transformers>=4.51.0` 和 `huggingface-hub` 等依赖。

### Step 4：下载并加载模型

首次运行时模型从 HuggingFace 自动下载（约 1.2GB），之后从本地缓存加载。

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer("Qwen/Qwen3-Embedding-0.6B")
```

这一行做了三件事：下载模型 → 加载到 GPU（自动检测 CUDA）→ 准备就绪。

如果 HuggingFace 下载慢，可以使用镜像源或提前用 `huggingface-cli download` 下载。

### Step 5：生成 embedding 并验证

先用最简单的例子确认 embedding 能正确区分语义：

```python
queries = ["什么是检索增强生成？"]
documents = [
    "RAG 是一种结合检索和生成的技术，先从知识库中检索相关文档，再交给大模型生成答案。",
    "今天天气很好，适合出去散步。",
]

query_emb = model.encode(queries, prompt_name="query")
doc_emb = model.encode(documents)

similarity = model.similarity(query_emb, doc_emb)
print(similarity)
```

预期：第一个文档相似度远高于第二个（如 0.7 vs 0.1），说明 embedding 能正确区分语义相关性。

### Step 6：接入 RAG 检索

验证通过后，在 RAG 管道中的用法：

- **索引阶段：** `model.encode(all_documents)` → 存入向量数据库
- **查询阶段：** `model.encode(query, prompt_name="query")` → 与向量数据库做相似度检索

## 关键注意事项

| 项目 | 说明 |
|------|------|
| query vs document | query 要加 `prompt_name="query"`，document 不加。模型会自动给 query 加 instruction prefix，帮助区分"问题"和"文档"，提升 1-5% 检索准确率（来源：Qwen3-Embedding 官方模型卡） |
| 显存占用 | 0.6B 模型约 1.2GB 显存，6GB 显卡完全够用 |
| 最大文本长度 | 8192 tokens |
| 多语言 | 支持 100+ 种语言，中英文均可 |
| instruction 语言 | 官方建议自定义 instruction 用英文写，因训练数据中 instruction 以英文为主 |

## 主要信息来源

- Qwen3-Embedding-0.6B 官方模型卡：https://huggingface.co/Qwen/Qwen3-Embedding-0.6B
- sentence-transformers 官方文档：https://sbert.net/docs/package_reference/sentence_transformer/SentenceTransformer.html
- PyTorch 官方安装指南：https://pytorch.org/get-started/locally/
- HuggingFace PyTorch 安装教程：https://huggingface.co/blog/daya-shankar/pytorch-install-guide
