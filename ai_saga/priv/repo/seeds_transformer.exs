_ = """
 Usage: mix run priv/repo/seeds_transformer.exs
 这个文件用于添加Transformer论文的详细数据，作为参考格式示例
"""

Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

IO.puts("Seeding Transformer paper with detailed format...")

# Update Transformer paper with detailed information
transformer_data = %{
  # 基本信息
  title: "Attention Is All You Need",
  slug: "vaswani-shazeer-parmar-2017-transformer",
  abstract: "我们提出了一种新的简单网络架构——Transformer，完全基于注意力机制，彻底摒弃了循环和卷积。在两个机器翻译任务上的实验表明，这些模型在质量上更优越，同时更易于并行化，训练时间显著减少。",
  arxiv_id: "1706.03762",
  published_year: 2017,
  published_month: 6,
  url: "https://arxiv.org/abs/1706.03762",
  categories: "cs.CL, cs.LG",
  citations: 100000,
  
  # 范式信息
  paradigm_id: 5,  # 基础模型与Transformer
  is_paradigm_shift: 1,
  shift_trigger: "注意力取代循环，实现并行训练和规模化",
  
  # 历史视角 - 时代背景（承前启后）
  prev_paradigm: """
**上一个范式：RNN + Encoder-Decoder + Attention**

在Transformer出现之前，序列建模的主流范式是：
```
RNN (LSTM/GRU) + Encoder-Decoder 架构 + 注意力机制
```

| 组件 | 贡献 | 问题 |
|------|------|------|
| **RNN** | 捕获序列顺序信息 | 难以并行计算(序列依赖)，梯度消失/爆炸 |
| **Encoder-Decoder** | 解决变长输入/输出 | 压缩信息到固定向量，信息瓶颈 |
| **Attention** | 缓解长距离信息丢失 | 仍受限于RNN框架 |

**CNN的困境**：
- 优点：容易并行(想想AlexNet)
- 缺点：难以捕捉长距离依赖(卷积核太小，需要多层堆叠)
""",
  
  # 历史视角 - 核心贡献
  core_contribution: """
**突破性洞察**：

> "The model reduces the number of sequential operations required to relate signals from an arbitrary input or output position to a fixed number."

Transformer敏锐地抓住了最核心的要素：注意力机制，完全基于此来建模序列关系：

1. **操作数量固定化**：任意两个位置之间的关联只需要O(1)步操作（而不是RNN的O(N)）
2. **并行计算友好**：多头注意力可以完全并行，不受序列依赖限制
3. **长距离依赖直接建模**：每个token可以直接关注上下文窗口内的任意其他token

> **一句话理解**：给了每个token"看到"整个上下文的能力，而不是像RNN只能看到"前世今生"。
""",
  
  # 历史视角 - 核心机制
  core_mechanism: """
**核心公式**：
```
Attention(Q, K, V) = softmax( (Q · K^T) / √d_k ) · V
```

**步骤拆解**：

| 步骤 | 操作 | 含义 |
|------|------|------|
| **1. 线性映射** | Q = XW_Q, K = XW_K, V = XW_V | 将embedding投影到Q/K/V空间 |
| **2. 计算相似度** | Q · K^T | 用点积计算query和key的相关性 |
| **3. 缩放** | / √d_k | 防止点积结果过大，导致softmax梯度消失 |
| **4. 归一化** | softmax() | 转换为概率分布(注意力权重) |
| **5. 加权求和** | · V | 用注意力权重对value加权，得到上下文向量 |

**多头注意力(Multi-Head Attention)**：
- 多头并行计算不同的注意力模式
- 拼接后通过线性变换恢复到原始embedding维度

**模型架构关键设计**：
- 绝对位置编码：用sin/cos函数编码位置信息
- Masked Attention：防止Decoder看到未来信息
- Add & LayerNorm：残差连接+层归一化，稳定训练
- Position-wise FFN：逐位置的前馈网络，增加模型容量
""",
  
  # 历史视角 - 为什么赢了
  why_it_wins: """
**1. 抽中硬件彩票**

| 特性 | RNN | CNN | Transformer |
|------|-----|-----|-------------|
| **并行计算** | ❌ 串行 | ✅ | ✅ ✅ |
| **长距离依赖** | ⚠️ 梯度问题 | ⚠️ 需要多层 | ✅ 直接建模 |
| **硬件友好** | ❌ | ✅ | ✅ ✅ |

> Transformer完美契合GPU/TPU的并行计算能力，"大力出奇迹"成为可能。

**2. 为Scaling奠定基础**
- 适合并行 → 可以用更多GPU训练
- 注意力机制 → 可以扩展到更大上下文窗口
- 无序列依赖 → 可以用更大batch size

> 这为后来的GPT、LLaMA等大语言模型埋下了伏笔。
""",
  
  # 范式变迁视角 - 当时面临的挑战
  challenge: "RNN的序列依赖性导致无法并行计算，训练速度慢；长距离依赖难以捕捉；如何完全摆脱循环结构，仅基于注意力机制构建序列模型？",
  
  # 范式变迁视角 - 解决方案
  solution: "提出Transformer架构，完全基于自注意力机制，通过多头注意力、位置编码、残差连接等技术，实现了完全并行化的序列建模。",
  
  # 范式变迁视角 - 深远影响
  impact: "引发了NLP领域的范式革命，BERT、GPT等后续模型都基于Transformer架构。这是ML历史上最重要的架构创新之一。",
  
  # 后续影响
  subsequent_impact: """
**范式转换**：

| 时代 | 核心 | 代表工作 |
|------|------|----------|
| **Transformer之前** | RNN + Attention | Seq2Seq, Bahdanau Attention |
| **Transformer时代** | Attention Only | BERT, GPT, T5, etc. |

**后续影响时间线**：
1. **BERT** (2018)：只用Encoder，刷新NLP基准
2. **GPT** (2018)：只用Decoder，引领生成式AI
3. **GPT-2** (2019)：零样本学习
4. **GPT-3** (2020)：few-shot, 175B参数
5. **ViT** (2020)：Transformer进入计算机视觉
6. **ChatGPT** (2022)：LLM + 指令微调 + RLHF
7. **LLaMA** (2023)：开源LLM
""",
  
  # 人的视角 - 作者去向
  author_destinies: """
| 作者 | 后续发展 |
|------|----------|
| **Noam Shazeer** | 联合创立Character.AI |
| **Llion Jones** | 联合创立Sakana AI (从Cohere离开) |
| **Aidan N. Gomez** | 联合创立Cohere |
| **Niki Parmar** | 联合创立Cohere |
| **Illia Polosukhin** | 联合创立Near Protocol (区块链) |
| **Jakob Uszkoreit** | 联合创立Inceptive (AI Biotech) |
| **Ashish Vaswani** | 继续AI研究 |
| **Łukasz Kaiser** | 继续AI研究 |

> **Noam Shazeer**在论文中的名言：
> *"We offer no explanation as to why these architectures seem to work; we attribute their success, as all else, to divine benevolence."*
> (我们无法解释这些架构为何有效；我们将其成功归因于神圣的仁慈。)
""",
  
  # 历史背景
  history_context: """
2017年，序列建模仍被RNN、LSTM、GRU主导。注意力机制虽然已被证明有效，但始终作为RNN的附加组件。

Google Brain团队敏锐地意识到：注意力机制本身就是核心，可以彻底取代循环结构。

这篇论文的8位作者来自Google Brain、Google Research和多伦多大学，是学术界与工业界合作的典范。
"""
}

# Update the paper
NexBase.from("papers")
|> NexBase.eq(:slug, "vaswani-shazeer-parmar-2017-transformer")
|> NexBase.update(transformer_data)
|> NexBase.run()

IO.puts("Transformer paper updated with detailed format!")
