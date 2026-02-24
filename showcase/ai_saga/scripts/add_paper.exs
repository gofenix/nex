_ = """
 Usage: mix run scripts/add_paper.exs

 这个脚本演示如何添加新论文到AiSaga：
 1. 用户提供论文基本信息
 2. 生成AI prompt
 3. 用户将prompt发送给AI（ChatGPT, Claude等）
 4. 将AI返回的内容保存到数据库
"""

# 示例：添加一篇新论文
paper_info = %{
  title: "Diffusion Models Beat GANs on Image Synthesis",
  authors: ["Prafulla Dhariwal", "Alex Nichol"],
  year: 2021,
  url: "https://arxiv.org/abs/2105.05233",
  abstract: "We show that diffusion models can achieve image sample quality superior to the current state-of-the-art generative models, including GANs. We achieve this by improving the U-Net architecture and introducing classifier guidance.",
  paradigm_id: 5,
  is_paradigm_shift: 1,
  shift_trigger: "扩散模型超越GAN成为图像生成新范式"
}

IO.puts("=" |> String.duplicate(80))
IO.puts("新论文信息")
IO.puts("=" |> String.duplicate(80))
IO.puts("标题: #{paper_info.title}")
IO.puts("作者: #{Enum.join(paper_info.authors, ", ")}")
IO.puts("年份: #{paper_info.year}")
IO.puts("链接: #{paper_info.url}")
IO.puts("")

# 生成slug
author_part = paper_info.authors |> List.first() |> String.downcase() |> String.split(" ") |> List.last()
keyword = paper_info.title |> String.downcase() |> String.replace(~r/[^a-z0-9\s]/, "") |> String.split() |> Enum.take(3) |> Enum.join("-")
slug = "#{author_part}-#{paper_info.year}-#{keyword}"

# 生成prompt
prompt = """
请为以下AI论文生成详细的三视角分析内容：

论文标题：#{paper_info.title}
作者：#{Enum.join(paper_info.authors, ", ")}
发表年份：#{paper_info.year}
论文链接：#{paper_info.url}
摘要：#{paper_info.abstract}

请按照以下格式生成内容（使用Markdown格式）：

## 上一个范式
描述这篇论文出现之前的主流方法，包括：
- 主流技术栈（用表格对比组件、贡献、问题）
- 当时的困境

## 核心贡献
- 突破性洞察（引用关键句子）
- 2-3个核心创新点
- 一句话总结

## 核心机制
- 核心公式（用代码块）
- 步骤拆解（用表格）
- 关键设计组件

## 为什么赢了
- 与之前方法的对比表格
- 关键优势

## 当时面临的挑战
简洁描述领域面临的核心问题

## 解决方案
简洁描述论文如何解决这些问题

## 深远影响
简洁描述对领域的影响

## 后续影响
- 范式转换表格（时代、核心、代表工作）
- 后续重要工作的时间线

## 作者去向
- 表格列出主要作者的后续发展
- 名言引用（如果有）

## 历史背景
描述论文发表时的时代背景、研究动机

请用中文生成，保持学术性和准确性。
"""

IO.puts("=" |> String.duplicate(80))
IO.puts("AI Prompt (复制到ChatGPT/Claude)")
IO.puts("=" |> String.duplicate(80))
IO.puts(prompt)
IO.puts("")

IO.puts("=" |> String.duplicate(80))
IO.puts("建议的URL标识: #{slug}")
IO.puts("=" |> String.duplicate(80))
IO.puts("")

IO.puts("使用说明:")
IO.puts("1. 复制上面的Prompt发送给AI（ChatGPT-4, Claude等）")
IO.puts("2. 将AI返回的内容保存到文件，如: #{slug}.md")
IO.puts("3. 运行: mix run scripts/insert_paper.exs #{slug} #{slug}.md")
