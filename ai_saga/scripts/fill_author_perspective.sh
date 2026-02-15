#!/bin/bash
# 补齐论文的人视角字段：author_destinies 和 subsequent_impact

cd /Users/fenix/github/nex/ai_saga

# 论文1: The Perceptron (1958) - Rosenblatt
sqlite3 data/ai_saga.db << 'EOF'
UPDATE papers SET
  author_destinies = '**Frank Rosenblatt** (1928-1971)：感知机的发明者，康奈尔大学航空实验室研究员。在感知机论文发表后，他继续研究神经网络，但1969年Minsky的批评后，他的研究资金锐减。1971年，Rosenblatt在一次 boating accident 中不幸溺亡，年仅43岁。如果他活得更久，可能会在深度学习复兴中扮演重要角色。他的学生和同事在1970-80年代继续神经网络研究，但直到反向传播出现才取得突破。',
  subsequent_impact = '感知机的影响远超其技术局限：1) 开创了**连接主义**范式，将神经网络确立为AI的重要分支；2) 启发了后续Minsky/Papert的工作，虽然负面但推动了理论发展；3) 训练算法(梯度下降)成为机器学习基础；4) 1986年反向传播复兴后，Rosenblatt的工作被重新认可为深度学习先驱。今天，每个神经网络的学生都会先学习感知机作为入门。'
WHERE id = 1;
EOF

# 论文2: Perceptrons (1969) - Minsky & Papert
sqlite3 data/ai_saga.db << 'EOF'
UPDATE papers SET
  author_destinies = '**Marvin Minsky** (1927-2016)：MIT人工智能实验室联合创始人，AI领域奠基人之一。在《Perceptrons》后，他主导了符号AI研究，开发了帧(Frame)理论和知识表示方法。1980年代后转向认知科学和意识研究，晚年关注AI伦理。2016年去世，未能看到深度学习的全面胜利。**Seymour Papert** (1928-2016)：MIT教授，与Minsky共同创立AI实验室。后来转向教育技术，开发了LOGO编程语言，倡导儿童计算机教育。2000年代后继续研究学习理论，2016年去世。两人的批评虽然导致神经网络寒冬，但也推动了AI理论的严谨性。',
  subsequent_impact = '这本书的后续影响具有两面性：1) **负面**：直接导致1969-1980年代神经网络研究的资金枯竭，第一次AI寒冬；2) **正面**：迫使研究人员寻找新的方向，间接促进了符号AI和专家系统的发展；3) **关键启示**：书中暗示的多层网络解决方案，直接启发了反向传播的研究；4) **历史评价**：今天看来，这是必要的理论纠正，防止了感知机被过度炒作。Minsky晚年承认对神经网络复兴感到惊讶和欣慰。'
WHERE id = 2;
EOF

# 论文3: Backpropagation (1986) - Rumelhart, Hinton, Williams
sqlite3 data/ai_saga.db << 'EOF'
UPDATE papers SET
  author_destinies = '**David Rumelhart** (1942-2011)：认知心理学家，连接主义运动领袖。1980年代领导了PDP研究组，推动神经网络复兴。1990年代因健康问题(罕见神经系统疾病)逐渐退出研究，2011年去世。他的认知科学视角深刻影响了神经网络研究。**Geoffrey Hinton**：英国计算机科学家，深度学习的"教父"。反向传播后继续研究神经网络，开发了玻尔兹曼机、深度信念网络。2012年AlexNet成功后获得广泛关注，2013年加入Google，2018年获图灵奖。2023年从Google离职，公开表达对AI风险的担忧。**Ronald Williams**：东北大学教授，主要研究神经网络优化算法。与Hinton和Rumelhart合作后，继续神经网络和机器学习研究，但保持相对低调。',
  subsequent_impact = '反向传播的后续影响：1) **连接主义复兴**：1986-1995年间，神经网络从边缘研究变为主流，引发第二波AI热潮；2) **架构创新**：LSTM(1997)、CNN(1989)、ResNet(2015)都依赖反向传播训练；3) **深度学习基石**：AlexNet、Transformer、GPT等所有现代模型都使用反向传播或其变体；4) **跨学科影响**：推动了计算神经科学，帮助理解大脑学习机制；5) **产业应用**：语音识别、图像分类、自然语言处理等商业应用的基础。可以说，没有反向传播就没有现代AI。'
WHERE id = 3;
EOF

# 论文4: Gradient Vanishing (1994) - Bengio et al.
sqlite3 data/ai_saga.db << 'EOF'
UPDATE papers SET
  author_destinies = '**Yoshua Bengio**：加拿大计算机科学家，深度学习三巨头之一。这篇论文后，他继续研究RNN和序列建模。2000年后专注于深度学习理论，开发了神经语言模型和注意力机制。2018年与Hinton、LeCun共同获得图灵奖。现为蒙特利尔大学教授，领导Mila研究所，致力于AI安全和可解释AI。**Patrice Simard**：微软研究院研究员，主要从事机器学习理论和人机交互研究。**François Frasconi**：意大利研究员，从事生物信息学和机器学习应用。',
  subsequent_impact = '梯度消失论文的后续影响：1) **问题识别**：首次从理论上解释了RNN的根本限制，不是工程问题而是架构问题；2) **直接推动LSTM**：Hochreiter和Schmidhuber在1997年阅读本文后开发了LSTM来解决这一问题；3) **注意力机制**：Bengio后续研究注意力机制，最终导向Transformer；4) **残差连接**：ResNet的跳跃连接也部分受此启发；5) **Transformer革命**：2017年Transformer完全摒弃循环，部分原因就是为了避免梯度问题。这篇负面结果论文实际上指明了正确的研究方向。'
WHERE id = 4;
EOF

# 论文5: LSTM (1997) - Hochreiter & Schmidhuber
sqlite3 data/ai_saga.db << 'EOF'
UPDATE papers SET
  author_destinies = '**Sepp Hochreiter**：奥地利计算机科学家，LSTM的主要发明者。1997年在TUM完成博士学位，导师是Schmidhuber。之后继续研究深度学习，开发了GPU上的高效LSTM实现。现任JKU Linz教授，领导深度学习研究所，研究生物信息学和神经架构搜索。**Jürgen Schmidhuber**：德国/瑞士计算机科学家，递归神经网络和LSTM的奠基人。2000年代后在IDSIA研究所继续深度学习研究，开发了基于LSTM的语音识别和翻译系统。2014年创立Nnaisense公司。以提出"AI智能爆炸"和"自我改进AI"等前瞻性观点闻名，有时与深度学习其他先驱存在学术争议。',
  subsequent_impact = 'LSTM的后续影响：1) **序列建模标准**：1997-2017年间，LSTM主导了所有序列任务(语音识别、机器翻译、手写识别)；2) **商业应用**：Google语音搜索、Apple Siri、Amazon Alexa等早期都基于LSTM；3) **架构变体**：GRU(2014)、BiLSTM、多层LSTM等改进版本；4) **产业落地**：百度、Google、微软等公司的大规模部署；5) **被Transformer取代**：2017年后，虽然Transformer成为主流，但LSTM仍在资源受限场景和某些特定任务中使用。LSTM解决了梯度消失问题，为序列深度学习铺平道路。'
WHERE id = 5;
EOF

# 论文6: AlexNet (2012) - Krizhevsky, Sutskever, Hinton
sqlite3 data/ai_saga.db << 'EOF'
UPDATE papers SET
  author_destinies = '**Alex Krizhevsky**：多伦多大学博士生，Hinton的学生。AlexNet是他博士期间的工作，论文一作。ImageNet胜利后，2013年与Hinton一起加入Google，开发了Google Photos的图像识别系统。2017年离开Google，之后保持低调。**Ilya Sutskever**：Hinton的另一位博士生，AlexNet二作。深度学习核心研究者，开发了Sequence to Sequence模型。2015年离开Google，与Greg Brockman、Sam Altman共同创立OpenAI，任首席科学家。主导了GPT系列和DALL-E的开发，是ChatGPT成功的关键人物。2023年参与OpenAI董事会事件后被重新任命为首席科学家。**Geoffrey Hinton**：见论文3。AlexNet后获得图灵奖，成为深度学习代言人，2023年从Google离职后专注于AI安全警告。',
  subsequent_impact = 'AlexNet的后续影响：1) **深度学习革命**：2012年后，计算机视觉界从手工特征(SIFT、HOG)全面转向深度学习；2) **ImageNet遗产**：催生了ILSVRC竞赛，推动视觉识别快速进步；3) **GPU普及**：证明了GPU对深度学习的关键作用，NVIDIA股价因此起飞；4) **架构演进**：VGG(2014)、ResNet(2015)、DenseNet等都受益于AlexNet开创的深度CNN范式；5) **产业变革**：自动驾驶、医学影像、安防监控等行业被深度学习彻底改变；6) **AI投资热潮**：2012年后AI研究和投资呈指数增长。AlexNet是现代AI时代的 tipping point。'
WHERE id = 6;
EOF

# 论文7: ResNet (2015) - He et al. (Microsoft Research)
sqlite3 data/ai_saga.db << 'EOF'
UPDATE papers SET
  author_destinies = '**Kaiming He (何恺明)**：中国计算机科学家，ResNet的一作。毕业于清华和港中文，博士导师是汤晓鸥。ResNet是他在MSRA期间的工作，获得CVPR 2016 Best Paper。后继续研究计算机视觉，开发了Mask R-CNN、MoCo(自监督学习)等重要工作。2023年离开Meta AI，加入MIT担任教授。被认为是计算机视觉领域最具影响力的研究者之一。**其他作者**：Xiangyu Zhang、Shaoqing Ren(现AutoX创始人)、Jian Sun(孙剑，MSRA首席研究员，2022年不幸去世)。微软亚洲研究院团队在此期间产出了大量深度学习核心研究。',
  subsequent_impact = 'ResNet的后续影响：1) **深度网络基础**：成为几乎所有计算机视觉任务的主干网络(backbone)；2) **超深网络**：首次实现100+层甚至1000+层的稳定训练，打破了深度的限制；3) **跨领域应用**：被应用于目标检测(Faster R-CNN)、语义分割、人脸 recognition等；4) **架构设计思想**：残差连接思想影响了DenseNet、ResNeXt、EfficientNet等后续架构；5) **跳跃连接范式**：Transformer中的残差连接也源于此；6) **工业标准**：被部署在几乎所有视觉产品中，从手机拍照到自动驾驶。ResNet解决了深度学习的核心瓶颈，其影响延续至今。'
WHERE id = 7;
EOF

# 论文8: Transformer (2017) - Vaswani et al. (Google Brain)
sqlite3 data/ai_saga.db << 'EOF'
UPDATE papers SET
  author_destinies = '**Ashish Vaswani**：Transformer一作，Google Brain研究员。此前参与神经机器翻译研究。Transformer后继续在Google研究NLP，2018年创立Adept AI(专注AI助手)，2021年离开Google加入OpenAI参与GPT-4开发，2023年再次创业。**Niki Parmar**：Google研究员，Transformer共同作者。后离开Google加入Adept，再后加入一家 stealth startup。**其他Google Brain作者**：Llion Jones(后继续研究T5)、Lukasz Kaiser(BERT共同作者，后离开Google)、Illia Polosukhin(后创立NEAR Protocol区块链)。Google Brain在此期间(2017-2018)密集产出了Transformer、BERT、GPT等变革性研究，团队后来分散到各AI公司。',
  subsequent_impact = 'Transformer的后续影响是全方位的：1) **NLP革命**：BERT、GPT、T5等所有现代语言模型都基于此，2018年后NLP研究从RNN全面转向Transformer；2) **视觉Transformer**：ViT(2020)证明纯注意力在视觉也有效，逐步取代CNN；3) **多模态AI**：CLIP、DALL-E、GPT-4V等跨模态模型都使用Transformer统一架构；4) **大模型时代**：GPT-3(175B)、GPT-4、PaLM等超大规模模型都依赖Transformer的可并行性；5) **产业落地**：从ChatGPT到Copilot，所有生成式AI产品都基于此。Transformer可能是深度学习历史上最重要的架构创新，改变了整个AI领域的走向。'
WHERE id = 8;
EOF

# 论文9: BERT (2018) - Devlin et al. (Google)
sqlite3 data/ai_saga.db << 'EOF'
UPDATE papers SET
  author_destinies = '**Jacob Devlin**：BERT一作，Google研究员。毕业于斯坦福和马里兰大学，在Google期间领导了BERT的预训练研究。BERT成功后，他继续在Google研究大规模语言模型。2022年离开Google，加入一家AI startup(据报道是Character.AI或类似公司)。**Ming-Wei Chang (张明威)**：台湾计算机科学家，Google研究员。博士毕业于伊利诺伊大学，从事NLP和预训练研究。BERT后继续研究多语言模型和对话系统。**Kent Lee**：Google研究员，从事机器翻译和NLP。**Kristina Toutanova**：斯坦福/微软研究员，从事知识表示和NLP。',
  subsequent_impact = 'BERT的后续影响：1) **预训练-微调范式**：成为NLP的标准方法，取代了任务特定模型；2) **模型变体**：RoBERTa(优化训练)、ALBERT(参数共享)、DistilBERT(轻量化)、ELECTRA(替代训练)等数十个改进版本；3) **跨语言扩展**：mBERT、XLM-R等多语言版本推动了全球NLP发展；4) **下游任务**：在GLUE、SQuAD等基准上大幅提升，被应用于搜索、问答、情感分析等；5) **被GPT取代**：虽然BERT在理解任务上仍优秀，但GPT的生成能力更受关注，2022年后生成式AI成为主流。BERT代表了NLP的预训练时代，为GPT和大语言模型铺平道路。'
WHERE id = 9;
EOF

# 论文10: GPT-3 (2020) - Brown et al. (OpenAI)
sqlite3 data/ai_saga.db << 'EOF'
UPDATE papers SET
  author_destinies = '**Tom B. Brown**：GPT-3一作，OpenAI研究员。毕业于MIT，在OpenAI期间从事大规模语言模型研究。GPT-3后继续研究上下文学习和提示工程，2022年后离开OpenAI，去向未公开。**其他OpenAI作者**：Benjamin Mann、Nick Ryder(继续在OpenAI)、Melanie Subbiah(离开OpenAI)、Jared Kaplan(物理学家转AI，继续在大模型研究)、Prafulla Dhariwal(继续在OpenAI，参与GPT-4)、Arvind Neelakantan(离开OpenAI)。OpenAI在此期间(2018-2020)从小型研究组织快速扩张，GPT-3的成功吸引了微软10亿美元投资，为ChatGPT奠定基础。',
  subsequent_impact = 'GPT-3的后续影响是革命性的：1) **上下文学习新范式**：证明了无需微调、仅通过提示就能完成多种任务；2) **大模型竞赛**：激发了Google(PaLM)、Meta(LLaMA)、Anthropic(Claude)等公司的超大规模模型研发；3) **提示工程兴起**：催生了新的AI交互范式和产品形态；4) **ChatGPT基础**：2022年的ChatGPT基于GPT-3.5，2023年的GPT-4延续了这一架构；5) **AI应用爆发**：从GitHub Copilot到Jasper AI，无数AI产品基于GPT-3 API构建；6) **产业变革**：2020年后AI投资热潮，NVIDIA市值暴涨，AI成为科技界核心议题。GPT-3标志着大语言模型时代的正式开始。'
WHERE id = 10;
EOF

echo "人的视角字段补齐完成！"
