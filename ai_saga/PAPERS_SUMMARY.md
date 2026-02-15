# AiSaga 论文详情 - 三视角整理完成

## 概述

所有10篇里程碑论文都已按照三视角格式整理完成：

1. **历史视角：承前启后** - 上一个范式、核心贡献、核心机制、为什么赢了
2. **范式变迁视角** - 当时面临的挑战、解决方案、深远影响
3. **人的视角** - 作者去向、名言引用
4. **后续影响** - 范式转换、时间线

## 论文列表

### 1. 感知机 (1958)
- **作者**: Frank Rosenblatt
- **范式**: 感知机与连接主义
- **核心**: 第一个能够从数据中学习的学习算法
- **历史意义**: 开创了连接主义领域

### 2. Perceptrons批评 (1969)
- **作者**: Marvin Minsky, Seymour Papert
- **范式**: 感知机与连接主义
- **核心**: 数学证明单层感知机无法解决XOR
- **历史意义**: 引发第一次AI寒冬，但也指明了解决方向

### 3. 反向传播 (1986)
- **作者**: Rumelhart, Hinton, Williams
- **范式**: 符号AI与专家系统
- **核心**: 训练多层网络的算法
- **历史意义**: 复兴神经网络，连接主义兴起

### 4. 梯度问题 (1994)
- **作者**: Bengio, Simard, Frasconi
- **范式**: 符号AI与专家系统
- **核心**: 证明RNN的梯度消失/爆炸问题
- **历史意义**: 推动LSTM和注意力机制的研究

### 5. LSTM (1997)
- **作者**: Hochreiter, Schmidhuber
- **范式**: 统计学习与SVM
- **核心**: 门控机制解决长期依赖
- **历史意义**: 让RNN实用化，服务NLP二十年

### 6. AlexNet (2012)
- **作者**: Krizhevsky, Sutskever, Hinton
- **范式**: 深度学习
- **核心**: GPU+大数据+深度CNN
- **历史意义**: 引发深度学习革命

### 7. ResNet (2015)
- **作者**: He, Zhang, Ren, Sun
- **范式**: 深度学习
- **核心**: 残差连接训练超深网络
- **历史意义**: 152层网络，超越人类水平

### 8. Transformer (2017)
- **作者**: Vaswani et al. (8位作者)
- **范式**: 基础模型与Transformer
- **核心**: 注意力取代循环
- **历史意义**: 现代大语言模型的基础

### 9. BERT (2018)
- **作者**: Devlin, Chang, Lee, Toutanova
- **范式**: 基础模型与Transformer
- **核心**: 双向预训练
- **历史意义**: 刷新NLP基准，预训练+微调范式

### 10. GPT-3 (2020)
- **作者**: Brown et al., OpenAI
- **范式**: 基础模型与Transformer
- **核心**: 规模化带来涌现能力
- **历史意义**: 上下文学习，大语言模型时代

## 数据结构

每篇论文包含以下字段：

```elixir
%{
  # 基本信息
  title: "论文标题",
  slug: "url标识",
  abstract: "中文摘要",
  
  # 历史视角
  prev_paradigm: "上一个范式描述（含表格）",
  core_contribution: "核心贡献（含关键洞察）",
  core_mechanism: "核心机制（含公式和步骤）",
  why_it_wins: "为什么赢了（含对比表格）",
  
  # 范式变迁视角
  challenge: "当时面临的挑战",
  solution: "解决方案",
  impact: "深远影响",
  
  # 人的视角
  author_destinies: "作者去向（含表格和名言）",
  
  # 后续影响
  subsequent_impact: "后续影响（含时间线）",
  
  # 历史背景
  history_context: "历史背景"
}
```

## 特色内容

### 1. 丰富的表格
- 方法对比表格
- 步骤拆解表格
- 作者去向表格
- 范式转换表格

### 2. 公式和代码
- 感知机学习规则
- 反向传播算法
- LSTM门控方程
- 注意力机制公式
- 残差连接公式

### 3. 名言引用
- Rosenblatt的愿景
- Minsky的反思
- Hinton的坚持
- Noam Shazeer的神圣仁慈
- 等等

### 4. 历史故事
- 每篇论文都有详细的历史背景
- 研究动机和团队组成
- 当时的困境和突破

## 访问方式

所有论文详情页面都可以通过以下URL访问：

```
http://localhost:4000/paper/{slug}
```

例如：
- `/paper/vaswani-shazeer-parmar-2017-transformer`
- `/paper/krizhevsky-sutskever-hinton-2012-alexnet`
- `/paper/rosenblatt-1958-perceptron`

## 技术实现

- 数据库：SQLite (MotherDuck风格)
- 后端：Elixir + Nex框架
- 前端：HEEx模板 + Tailwind CSS
- 样式：奶油色背景、黄色强调、黑色边框

## 未来扩展

可以按照相同格式添加更多论文：
1. 创建新的种子文件
2. 按照模板填充三视角内容
3. 运行 `mix run priv/repo/seeds_xxx.exs`

参考模板：`priv/repo/paper_template.md`
