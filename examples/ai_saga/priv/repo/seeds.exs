_ = """
 Usage: mix run priv/repo/seeds.exs
"""

Nex.Env.init()
NexBase.init(url: Nex.Env.get(:database_url), start: true)

IO.puts("Seeding data...")

# Insert Paradigms
paradigms = [
  %{name: "感知机与连接主义", slug: "perceptron", description: "最早的神经网络时代，始于Rosenblatt的感知机（1957年），后因Minsky与Papert的批评（1969年）导致第一次AI寒冬。", start_year: 1957, end_year: 1969, crisis: "感知机无法学习XOR函数", revolution: "1986年反向传播算法重新兴起"},
  %{name: "符号AI与专家系统", slug: "symbolic-ai", description: "基于规则的AI系统，主导了1970年代到1980年代，试图将人类知识编码为逻辑规则。", start_year: 1970, end_year: 1987, crisis: "知识获取瓶颈", revolution: "机器学习成为新范式"},
  %{name: "统计学习与SVM", slug: "statistical-learning", description: "统计方法在1990年代到2000年代成为主流，支持向量机是代表性方法。", start_year: 1990, end_year: 2012, crisis: "难以扩展到海量数据", revolution: "2012年深度学习突破"},
  %{name: "深度学习", slug: "deep-learning", description: "多层神经网络从2012年开始革新AI，得益于GPU计算和大数据。", start_year: 2012, end_year: 2020, crisis: "计算需求高、可解释性差", revolution: "Transformer（2017年）"},
  %{name: "基础模型与Transformer", slug: "transformers", description: "大规模预训练模型如GPT、BERT，可以通过提示完成多种任务。", start_year: 2017, end_year: nil, crisis: "对齐问题、幻觉、资源需求", revolution: "持续演进中..."}
]

Enum.each(paradigms, fn p ->
  NexBase.from("aisaga_paradigms")
  |> NexBase.insert(p)
  |> NexBase.run()
end)

# Insert Authors
authors = [
  %{name: "Frank Rosenblatt", slug: "frank-rosenblatt", bio: "康奈尔大学心理学家，1957年发明了感知机，开创了连接主义领域。", affiliation: "康奈尔大学", birth_year: 1928, first_paper_year: 1957, influence_score: 95},
  %{name: "Marvin Minsky", slug: "marvin-minsky", bio: "MIT人工智能先驱，联合创立了MIT人工智能实验室。1969年与Papert的著作终结了第一次神经网络热潮。", affiliation: "MIT", birth_year: 1927, first_paper_year: 1951, influence_score: 98},
  %{name: "Geoffrey Hinton", slug: "geoffrey-hinton", bio: "被誉为'深度学习之父'。1986年关于反向传播的工作复兴了神经网络。", affiliation: "多伦多大学 / Google", birth_year: 1947, first_paper_year: 1970, influence_score: 99},
  %{name: "Yann LeCun", slug: "yann-lecun", bio: "卷积神经网络先驱。创立了Facebook AI研究院（FAIR）。", affiliation: "纽约大学 / Meta AI", birth_year: 1960, first_paper_year: 1989, influence_score: 97},
  %{name: "Yoshua Bengio", slug: "yoshua-bengio", bio: "深度学习关键人物。2014年关于注意力机制的工作为Transformer奠定了基础。", affiliation: "蒙特利尔大学", birth_year: 1964, first_paper_year: 1991, influence_score: 97},
  %{name: "Alex Krizhevsky", slug: "alex-krizhevsky", bio: "创建了AlexNet（2012年），使用GPU训练引发了深度学习革命。", affiliation: "多伦多大学", birth_year: nil, first_paper_year: 2012, influence_score: 90},
  %{name: "Ilya Sutskever", slug: "ilya-sutskever", bio: "OpenAI联合创始人。AlphaGo和GPT系列的关键贡献者。", affiliation: "OpenAI", birth_year: 1985, first_paper_year: 2005, influence_score: 95},
  %{name: "Ashish Vaswani", slug: "ashish-vaswani", bio: "在《Attention Is All You Need》（2017年）中发明了Transformer架构。", affiliation: "Google Brain", birth_year: nil, first_paper_year: 2017, influence_score: 96},
  %{name: "Jacob Devlin", slug: "jacob-devlin", bio: "创建了BERT（2018年），通过双向编码器革新了NLP领域。", affiliation: "Google AI", birth_year: nil, first_paper_year: 2018, influence_score: 93},
  %{name: "John Hopfield", slug: "john-hopfield", bio: "创建了Hopfield网络（1982年），帮助复兴了对神经网络的兴趣。", affiliation: "普林斯顿大学", birth_year: 1933, first_paper_year: 1982, influence_score: 88}
]

Enum.each(authors, fn a ->
  NexBase.from("aisaga_authors")
  |> NexBase.insert(a)
  |> NexBase.run()
end)

# Get paradigm IDs
{:ok, paradigm_list} = NexBase.from("aisaga_paradigms") |> NexBase.run()
p_id = fn name -> Enum.find(paradigm_list, fn p -> p["name"] == name end)["id"] end

# Get author IDs
{:ok, author_list} = NexBase.from("aisaga_authors") |> NexBase.run()
a_id = fn name -> Enum.find(author_list, fn a -> a["name"] == name end)["id"] end

# Insert Papers with rich metadata
papers = [
  %{
    title: "The Perceptron: A Probabilistic Model for Information Storage and Organization in the Brain",
    slug: "rosenblatt-1958-perceptron",
    abstract: "Rosenblatt提出了感知机，第一个基于简化神经元模型的学习机器。它可以通过迭代调整权重来学习分类模式。",
    arxiv_id: nil,
    published_year: 1958,
    published_month: 7,
    url: "https://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.335.1718",
    categories: "cs.AI",
    citations: 12000,
    history_context: "1956年，达特茅斯会议标志着AI领域的诞生。研究人员对创造能够思考的机器充满乐观。Rosenblatt在1958年提出的感知机是第一个学习机器的实用演示。",
    challenge: "一个简单的神经模型如何在没有显式编程的情况下学习识别模式？",
    solution: "引入了感知机学习规则：根据预测输出与实际输出之间的误差调整权重。这是第一个能够从示例中学习的算法。",
    impact: "开创了连接主义领域。激发了几十年神经网络研究。然而，它的局限性（特别是无法解决XOR问题）在Minsky与Papert 1969年的批评后导致了第一次AI寒冬。",
    paradigm_id: p_id.("感知机与连接主义"),
    is_paradigm_shift: 1,
    shift_trigger: "第一个实用的神经网络学习算法"
  },
  %{
    title: "Perceptrons: An Introduction to Computational Geometry",
    slug: "minsky-papert-1969-perceptrons",
    abstract: "Minsky和Papert的著名著作，从数学上证明了单层感知机的局限性，包括无法解决XOR等非线性问题。",
    arxiv_id: nil,
    published_year: 1969,
    published_month: 1,
    url: "https://books.google.com/books/about/Perceptrons.html?id=2l4GAQAAMAAJ",
    categories: "cs.AI",
    citations: 8000,
    history_context: "到1960年代末，AI资金正在枯竭。该领域需要新方向。这本书从数学上证实了许多人怀疑的：简单感知机有根本性局限。",
    challenge: "单层神经网络的理论极限是什么？",
    solution: "从数学上证明感知机无法解决线性不可分模式（如XOR）。表明添加隐藏层可能解决此问题，但没有这样的网络的学习算法。",
    impact: "引发了第一次AI寒冬（1969-1980）。神经网络研究资金几乎消失。但它也指明了解决方案：多层网络与反向传播。",
    paradigm_id: p_id.("感知机与连接主义"),
    is_paradigm_shift: 1,
    shift_trigger: "从数学上证明局限性，终结了感知机时代"
  },
  %{
    title: "Learning Representations by Back-propagating Errors",
    slug: "rumelhart-hinton-williams-1986-backprop",
    abstract: "这篇开创性论文推广了反向传播算法，展示了多层神经网络如何学习非线性函数。",
    arxiv_id: nil,
    published_year: 1986,
    published_month: 9,
    url: "https://nature.com/articles/323533a0",
    categories: "cs.AI",
    citations: 45000,
    history_context: "AI寒冬之后，一小群研究人员继续研究神经网络。关键是找到训练多层网络的方法——Minsky与Papert建议但未提供的解决方案。",
    challenge: "当隐藏层没有显式误差信号时，我们如何训练多层神经网络？",
    solution: "反向传播：通过在网络中反向传播误差来计算误差相对于权重的梯度。这允许训练任意深度的网络。",
    impact: "复兴了神经网络研究（连接主义）。导致了1980年代末-1990年代的第二波神经网络热潮。然而，训练深度网络仍然困难，直到现代技术出现。",
    paradigm_id: p_id.("符号AI与专家系统"),
    is_paradigm_shift: 1,
    shift_trigger: "用实用训练算法复兴神经网络"
  },
  %{
    title: "Learning Long-Term Dependencies with Gradient Descent is Difficult",
    slug: "bengio-simard-1994-gradient-problems",
    abstract: "表明使用反向传播通过时间的普通RNN存在梯度消失/爆炸问题，使其无法学习长期依赖关系。",
    arxiv_id: nil,
    published_year: 1994,
    published_month: 3,
    url: "https://ieeexplore.ieee.org/document/291936",
    categories: "cs.NE",
    citations: 3000,
    history_context: "研究人员试图构建能够学习序列依赖关系的RNN。短序列有一些成功，但长期学习仍然难以实现。",
    challenge: "为什么RNN无法学习跨越多个时间步的依赖关系？",
    solution: "理论分析表明，通过时间的反向传播导致梯度消失或爆炸。误差信号在传播多个时间步时要么消失要么爆炸。",
    impact: "推动了LSTM（1997年）、门控循环和最终注意力机制的研究。表明简单梯度下降对长期依赖关系是不够的。",
    paradigm_id: p_id.("符号AI与专家系统"),
    is_paradigm_shift: 0,
    shift_trigger: nil
  },
  %{
    title: "Long Short-Term Memory",
    slug: "hochreiter-schmidhuber-1997-lstm",
    abstract: "引入了LSTM门控，允许RNN通过控制信息流通过记忆单元来学习长期依赖关系。",
    arxiv_id: nil,
    published_year: 1997,
    published_month: 11,
    url: "https://direct.mit.edu/neco/article-abstract/9/8/1735/6106/Long-Short-Term-Memory",
    categories: "cs.NE",
    citations: 60000,
    history_context: "梯度消失论文之后，研究人员需要解决方案。Hochreiter与Schmidhuber的LSTM引入了门控机制，可以学习记住什么和忘记什么。",
    challenge: "我们如何构建能够学习跨越数千个时间步的依赖关系的RNN？",
    solution: "LSTM门控（输入、遗忘、输出）控制信息流。单元状态充当'传送带'，可以以最小修改携带信息跨越长序列。",
    impact: "实现了实用的序列建模。LSTM为语音识别、机器翻译和许多其他应用提供动力近二十年。今天仍被广泛使用。",
    paradigm_id: p_id.("统计学习与SVM"),
    is_paradigm_shift: 1,
    shift_trigger: "解决梯度消失问题，实现长距离依赖"
  },
  %{
    title: "ImageNet Classification with Deep Convolutional Neural Networks",
    slug: "krizhevsky-sutskever-hinton-2012-alexnet",
    abstract: "AlexNet赢得了2012年ImageNet竞赛，使用深度CNN将错误率从26%降低到15%。GPU训练实现了5倍加速。",
    arxiv_id: "1211.0553",
    published_year: 2012,
    published_month: 9,
    url: "https://proceedings.neurips.cc/paper/2012/hash/c399862d3b9d6b76c8436e924a68c45b-Abstract.html",
    categories: "cs.CV",
    citations: 90000,
    history_context: "多年来，SVM主导计算机视觉。特征工程（SIFT、HOG）是标准方法。深度学习被认为对大规模视觉识别不实用。",
    challenge: "我们如何将神经网络扩展到ImageNet的120万张图像和1000个类别？",
    solution: "8层深度CNN，ReLU激活，dropout正则化，GPU加速。在2个GPU上训练5-6天。数据增强和仔细初始化至关重要。",
    impact: "引发了深度学习革命。计算机视觉一夜之间被改变。研究资金大幅转移。引领了现代深度学习时代。",
    paradigm_id: p_id.("深度学习"),
    is_paradigm_shift: 1,
    shift_trigger: "GPU + 大数据 + 深度网络 = 突破"
  },
  %{
    title: "Deep Residual Learning for Image Recognition",
    slug: "he-zhang-ren-sun-2015-resnet",
    abstract: "ResNet引入了跳跃连接，使训练100+层的网络成为可能。以3.57%错误率赢得2015年ImageNet。",
    arxiv_id: "1512.03385",
    published_year: 2015,
    published_month: 12,
    url: "https://www.cv-foundation.org/openaccess/content_cvpr_2016/html/He_Deep_Residual_Learning_CVPR_2016_paper.html",
    categories: "cs.CV",
    citations: 150000,
    history_context: "简单堆叠层会导致退化——更深的网络训练误差更高。研究人员需要训练超深网络的方法。",
    challenge: "我们如何在没有退化的情况下训练100+层的网络？",
    solution: "残差连接（跳跃连接）：不学习直接映射，而是学习残差（差异）。使优化更容易，因为恒等映射总是可学习的。",
    impact: "实现了100-1000层网络的训练。成为现代计算机视觉的主干。影响了所有深度学习领域的架构设计。",
    paradigm_id: p_id.("深度学习"),
    is_paradigm_shift: 1,
    shift_trigger: "跳跃连接实现超深网络"
  },
  %{
    title: "Attention Is All You Need",
    slug: "vaswani-shazeer-parmar-2017-transformer",
    abstract: "引入了完全基于注意力机制的Transformer架构，消除了循环和卷积。现代大语言模型的基础。",
    arxiv_id: "1706.03762",
    published_year: 2017,
    published_month: 6,
    url: "https://proceedings.neurips.cc/paper/2017/hash/3f5ee243547dee91fbd053c1c4a845aa-Abstract.html",
    categories: "cs.CL, cs.LG",
    citations: 100000,
    history_context: "序列建模依赖RNN、LSTM或CNN。注意力已被添加到RNN，但被视为增强而非替代。",
    challenge: "我们可以构建一个纯粹用注意力处理序列的模型，没有循环或卷积吗？",
    solution: "Transformer：堆叠的自注意力层与位置编码。多头注意力允许关注不同的表示子空间。在GPU上高度并行化。",
    impact: "改变了NLP。BERT、GPT和所有现代大语言模型都是Transformer。也被应用于视觉（ViT）、音频和多模态模型。可以说是ML历史上最重要的架构。",
    paradigm_id: p_id.("基础模型与Transformer"),
    is_paradigm_shift: 1,
    shift_trigger: "注意力取代循环，实现并行训练和规模化"
  },
  %{
    title: "BERT: Pre-training of Deep Bidirectional Transformers for Language Understanding",
    slug: "devlin-chang-lever-2018-bert",
    abstract: "BERT引入了双向编码器预训练，通过微调在11个NLP任务上取得了最先进的结果。",
    arxiv_id: "1810.04805",
    published_year: 2018,
    published_month: 10,
    url: "https://arxiv.org/abs/1810.04805",
    categories: "cs.CL",
    citations: 80000,
    history_context: "预训练+微调是标准（ELMo、GPT）。但GPT使用单向（从左到右）注意力。双向预训练能否给出更好的表示？",
    challenge: "我们如何在没有自回归生成的情况下使用双向上下文进行预训练？",
    solution: "掩码语言模型（MLM）：随机掩码标记并预测它们。这允许从左右上下文学习。下一句预测有助于句子级任务。",
    impact: "BERT主导了NLP基准测试。引入了成为标准的预训练/微调范式。激发了许多变体（RoBERTa、ALBERT等）。",
    paradigm_id: p_id.("基础模型与Transformer"),
    is_paradigm_shift: 1,
    shift_trigger: "双向预训练成为标准"
  },
  %{
    title: "Language Models are Few-Shot Learners",
    slug: "brown-mann-ryder-2020-gpt3",
    abstract: "GPT-3表明大规模（175B参数）无需微调即可实现零样本和少样本学习。",
    arxiv_id: "2005.14165",
    published_year: 2020,
    published_month: 5,
    url: "https://proceedings.neurips.cc/paper/2020/hash/1457c0d6bfcb4967418bfb8ac142f64a-Abstract.html",
    categories: "cs.CL, cs.LG",
    citations: 25000,
    history_context: "微调是将预训练模型应用于新任务的标准方法。但这需要任务特定数据和计算资源。",
    challenge: "我们能否让模型在没有梯度更新的情况下执行新任务，仅通过提示？",
    solution: "扩展到175B参数，300B标记训练数据。模型学习从提示中的几个示例推断任务。规模化导致涌现能力。",
    impact: "引入了上下文学习范式。点燃了大语言模型时代。表明规模化导致涌现能力。为ChatGPT和现代AI助手奠定基础。",
    paradigm_id: p_id.("基础模型与Transformer"),
    is_paradigm_shift: 1,
    shift_trigger: "规模化实现涌现的零样本能力"
  }
]

Enum.each(papers, fn p ->
  NexBase.from("aisaga_papers")
  |> NexBase.insert(p)
  |> NexBase.run()
end)

# Link authors to papers
paper_author_links = [
  %{paper: "rosenblatt-1958-perceptron", author: "Frank Rosenblatt", order: 1},
  %{paper: "minsky-papert-1969-perceptrons", author: "Marvin Minsky", order: 1},
  %{paper: "rumelhart-hinton-williams-1986-backprop", author: "Geoffrey Hinton", order: 2},
  %{paper: "krizhevsky-sutskever-hinton-2012-alexnet", author: "Alex Krizhevsky", order: 1},
  %{paper: "krizhevsky-sutskever-hinton-2012-alexnet", author: "Ilya Sutskever", order: 2},
  %{paper: "krizhevsky-sutskever-hinton-2012-alexnet", author: "Geoffrey Hinton", order: 3},
  %{paper: "vaswani-shazeer-parmar-2017-transformer", author: "Ashish Vaswani", order: 1},
  %{paper: "devlin-chang-lever-2018-bert", author: "Jacob Devlin", order: 1},
  %{paper: "brown-mann-ryder-2020-gpt3", author: "Ilya Sutskever", order: 2}
]

Enum.each(paper_author_links, fn link ->
  {:ok, [p]} = NexBase.from("aisaga_papers") |> NexBase.eq(:slug, link.paper) |> NexBase.single() |> NexBase.run()
  {:ok, [author]} = NexBase.from("aisaga_authors") |> NexBase.eq(:name, link.author) |> NexBase.single() |> NexBase.run()

  NexBase.from("aisaga_paper_authors")
  |> NexBase.insert(%{paper_id: p["id"], author_id: author["id"], author_order: link.order})
  |> NexBase.run()
end)

IO.puts("Seeded 10 seminal papers with Chinese translations!")
