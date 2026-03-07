# AiSaga Paper Summary - Three-Lens Dataset Complete

## Overview

All 10 milestone papers have been organized using the three-lens format:

1. **Historical Lens** - Previous paradigm, core contribution, core mechanism, and why it won
2. **Paradigm Shift Lens** - Challenges at the time, solution, and long-term impact
3. **Human Lens** - Author trajectories and notable quotes
4. **Subsequent Influence** - Paradigm transitions and timeline

## Paper List

### 1. Perceptron (1958)
- **Author**: Frank Rosenblatt
- **Paradigm**: Perceptron and Connectionism
- **Core idea**: The first learning algorithm that could learn from data
- **Historical significance**: Opened the era of connectionism

### 2. Perceptrons Critique (1969)
- **Authors**: Marvin Minsky, Seymour Papert
- **Paradigm**: Perceptron and Connectionism
- **Core idea**: A mathematical proof that single-layer perceptrons cannot solve XOR
- **Historical significance**: Triggered the first AI winter, while also pointing toward the eventual solution

### 3. Backpropagation (1986)
- **Authors**: Rumelhart, Hinton, Williams
- **Paradigm**: Symbolic AI and Expert Systems
- **Core idea**: An algorithm for training multilayer neural networks
- **Historical significance**: Revived neural networks and accelerated the return of connectionism

### 4. Gradient Problems (1994)
- **Authors**: Bengio, Simard, Frasconi
- **Paradigm**: Symbolic AI and Expert Systems
- **Core idea**: Demonstrated the vanishing and exploding gradient problem in RNNs
- **Historical significance**: Motivated later work on LSTM and attention mechanisms

### 5. LSTM (1997)
- **Authors**: Hochreiter, Schmidhuber
- **Paradigm**: Statistical Learning and SVM
- **Core idea**: A gating mechanism for long-term dependency modeling
- **Historical significance**: Made RNNs practical and shaped NLP for two decades

### 6. AlexNet (2012)
- **Authors**: Krizhevsky, Sutskever, Hinton
- **Paradigm**: Deep Learning
- **Core idea**: GPU training, large-scale data, and deep CNNs
- **Historical significance**: Triggered the deep learning revolution

### 7. ResNet (2015)
- **Authors**: He, Zhang, Ren, Sun
- **Paradigm**: Deep Learning
- **Core idea**: Residual connections for training very deep networks
- **Historical significance**: Enabled 152-layer networks and surpassed human-level benchmarks in some settings

### 8. Transformer (2017)
- **Authors**: Vaswani et al. (8 authors)
- **Paradigm**: Foundation Models and Transformers
- **Core idea**: Replaced recurrence with attention
- **Historical significance**: Became the foundation of modern large language models

### 9. BERT (2018)
- **Authors**: Devlin, Chang, Lee, Toutanova
- **Paradigm**: Foundation Models and Transformers
- **Core idea**: Bidirectional pretraining
- **Historical significance**: Reset NLP benchmarks and popularized the pretrain-plus-finetune paradigm

### 10. GPT-3 (2020)
- **Authors**: Brown et al., OpenAI
- **Paradigm**: Foundation Models and Transformers
- **Core idea**: Emergent capability through scale
- **Historical significance**: In-context learning and the rise of the large language model era

## Data Structure

Each paper includes the following fields:

```elixir
%{
  title: "Paper title",
  slug: "url-friendly identifier",
  abstract: "English abstract or summary",

  prev_paradigm: "Previous paradigm description, optionally with tables",
  core_contribution: "Core contribution, key insight, and summary",
  core_mechanism: "Core mechanism, formulas, and procedural steps",
  why_it_wins: "Why it won, including comparison tables if useful",

  challenge: "Challenges faced at the time",
  solution: "Solution introduced by the paper",
  impact: "Long-term impact",

  author_destinies: "Author trajectories, optionally with tables and quotes",

  subsequent_impact: "Subsequent influence, optionally including timelines",

  history_context: "Historical context"
}
```

## Notable Content Features

### 1. Rich tables
- Method comparison tables
- Step-by-step breakdown tables
- Author trajectory tables
- Paradigm transition tables

### 2. Equations and technical details
- Perceptron learning rule
- Backpropagation algorithm
- LSTM gating equations
- Attention mechanism formulas
- Residual connection formulas

### 3. Quotes and researcher voices
- Rosenblatt's vision
- Minsky's reflections
- Hinton's persistence
- Noam Shazeer's remarks
- And more

### 4. Historical narrative
- Detailed historical context for each paper
- Research motivation and team background
- The difficulties and breakthroughs of the time

## Access

All paper detail pages are accessible via:

```
http://localhost:4000/paper/{slug}
```

For example:
- `/paper/vaswani-shazeer-parmar-2017-transformer`
- `/paper/krizhevsky-sutskever-hinton-2012-alexnet`
- `/paper/rosenblatt-1958-perceptron`

## Technical Implementation

- Database: SQLite with a MotherDuck-inspired style
- Backend: Elixir + Nex framework
- Frontend: HEEx templates + Tailwind CSS
- Visual style: Cream background, yellow accents, and black borders

## Future Expansion

You can add more papers using the same format:
1. Create a new seed file
2. Fill it using the same three-lens structure
3. Run `mix run priv/repo/seeds_xxx.exs`

Reference template: `priv/repo/paper_template.md`
