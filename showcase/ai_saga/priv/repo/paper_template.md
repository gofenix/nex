# 论文详细数据模板

按照三个视角来组织论文数据：

## 基本信息
- title: 论文标题
- slug: URL友好的标识
- abstract: 中文摘要
- arxiv_id: arXiv ID
- published_year: 发表年份
- published_month: 发表月份
- url: 论文链接
- categories: 论文分类
- citations: 引用数
- paradigm_id: 所属范式ID
- is_paradigm_shift: 是否范式变迁(1/0)
- shift_trigger: 范式变迁触发点描述

## 一、历史视角：承前启后

### prev_paradigm (上一个范式)
描述Transformer出现之前的范式：
- 主流技术栈
- 各组件的贡献和问题
- 当时的困境

示例格式：
```markdown
**上一个范式：XXX + YYY + ZZZ**

在XXX出现之前，...的主流范式是：

| 组件 | 贡献 | 问题 |
|------|------|------|
| **XXX** | ... | ... |
| **YYY** | ... | ... |

**替代方案的困境**：
- 优点：...
- 缺点：...
```

### core_contribution (核心贡献)
描述论文的核心突破：
- 关键洞察（引用原文）
- 三个核心创新点
- 一句话总结

### core_mechanism (核心机制)
描述技术实现细节：
- 核心公式
- 步骤拆解表格
- 关键设计组件

### why_it_wins (为什么赢了)
对比分析为什么这个工作成功：
- 与之前方法的对比表格
- 硬件友好性分析
- 为scaling奠定的基础

## 二、范式变迁视角

### challenge (当时面临的挑战)
简洁描述当时领域面临的核心问题

### solution (解决方案)
简洁描述论文如何解决这些问题

### impact (深远影响)
简洁描述对领域的影响

## 三、人的视角

### author_destinies (作者去向)
表格形式列出主要作者的后续发展：
```markdown
| 作者 | 后续发展 |
|------|----------|
| **姓名** | 去向/成就 |
```

可以包含名言引用

## 四、后续影响

### subsequent_impact (后续影响)
- 范式转换表格
- 后续重要工作的时间线
- 对各个子领域的影响

## 五、历史背景

### history_context (历史背景)
描述论文发表时的时代背景：
- 当时的技术状况
- 团队组成
- 研究动机

---

## 使用示例：Transformer

参考 `/priv/repo/seeds_transformer.exs` 文件，这是按照此模板填充的完整示例。

添加新论文时：
1. 复制 `seeds_transformer.exs`
2. 按照模板填充内容
3. 运行 `mix run priv/repo/seeds_xxx.exs`
