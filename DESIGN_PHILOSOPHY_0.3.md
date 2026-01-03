# Nex 0.3.x 设计理念：极简主义的演进

> 从 0.2.x 到 0.3.x - 一个框架如何找到自己的身份

## 🙏 写在前面

这篇文档记录了我在开发 Nex 过程中的思考。

特别感谢 **Reddit (r/elixir)** 和 **Elixir Forum** 的朋友们。你们的反馈、质疑、建议，甚至批评，都帮助我一点点找到了 Nex 应该是什么样子。没有你们，就没有 0.3.x 这次重构。

也感谢 **Next.js**、**Phoenix**、**HTMX** 团队，你们的工作给了我无数灵感。

---

## 📖 TL;DR

简单来说，0.2.x 有点太复杂了：4 个不同的 `use` 语句，混乱的 API 参数，还有非主流的目录命名。

到了 0.3.x，我决定做减法：
*   只用一个 `use Nex`。
*   API 参数只保留 `query` 和 `body`，就像 Next.js 一样。
*   目录改回大家熟悉的 `components/`。
*   流式响应变成了一个简单的函数 `Nex.stream/1`。

结果就是：代码更少，概念更少，开发起来更顺手。

---

## 🎯 核心问题：找回定位

在开发 Nex 0.2.x 的时候，我其实挺纠结的。我总是在想：Nex 到底该长什么样？我试了很多方案，参考了很多框架，但总感觉差点意思。

### 0.2.x 的困境

看看这段 0.2.x 的代码：

```elixir
defmodule MyApp.Pages.Index do
  use Nex.Page  # 显式声明这是个 Page
end

defmodule MyApp.Api.Users do
  use Nex.Api  # 显式声明这是个 Api
end

defmodule MyApp.Partials.Card do
  use Nex.Partial  # 显式声明这是个 Partial
end
```

这种设计虽然看起来很严谨，但写起来很累。既然文件都在 `pages/` 目录下，为什么还要我再告诉框架一遍"这是个 Page"？

### 向 Next.js 学习

后来我重新看了下 Next.js。它最大的优点就是**约定优于配置**。你不需要写任何配置代码，文件放对位置就行了。

这才是 Nex 该有的样子：让开发者只关注业务逻辑，少写样板代码。

---

## 💡 决策 1：一个 `use Nex` 搞定所有

### 之前的尴尬

在 0.2.x 里，不仅要记 4 个不同的模块，还得搞清楚它们之间的区别。这完全是人为制造的认知负担。

### 现在的做法

0.3.x 利用 Elixir 的宏机制，根据文件路径自动推断模块类型。

```elixir
# 0.3.x - 清爽多了
defmodule MyApp.Pages.Index do
  use Nex
end

defmodule MyApp.Api.Users do
  use Nex
end
```

虽然这是个 Breaking Change，但这让代码看起来干净多了。

---

## 💡 决策 2：`partials/` 改名 `components/`

这其实是一个迟到的修正。

起初用 `partials` 是因为受到了 Rails 的影响，觉得这样更有"服务端渲染"的味道。但现实是，现在的前端世界（React, Vue, Svelte）以及 Phoenix 1.7+ 全都在用 `components`。

强行用 `partials` 除了让新用户感到困惑外，没有任何好处。所以，我们从善如流，改回了大家熟悉的 `components`。

---

## 💡 决策 3：REST API 终于好写了

### 痛点

在 0.2.x 写 API 简直是折磨。我有 4 个地方可以塞参数：`params`, `path_params`, `query_params`, `body_params`。开发者每次都要思考参数应该从哪里获取，增加了认知负担。

每次写代码都要想：
* "这个 id 是在路径里还是 query 里？"
* "我是不是该用 params 还是 query_params？"
* "body_params 和 params 有什么区别？"

### 借鉴 Next.js

我看了一下 Next.js 的做法，他们只给了两个选项，却覆盖了所有场景：

1. `req.query`: 处理所有 GET 请求参数（无论是路径里的还是 ? 后面的）
2. `req.body`: 处理所有 POST/PUT 的数据

这简直太合理了。开发者只关心"我要获取数据(Query)"还是"我要提交数据(Body)"。

所以在 0.3.x，我们也这样做了。框架会自动将路径参数（如 `/users/:id`）和查询参数（如 `?page=1`）都统一到 `req.query` 中：

```elixir
def get(req) do
  # 路径参数 :id 和查询参数 ?page 都在这里
  id = req.query["id"]
  page = req.query["page"]
end

def post(req) do
  # 提交的数据都在这里
  user = req.body["user"]
end
```

这种"无脑"的体验，才是一个好框架该有的样子。

---

## 💡 决策 4：流式响应 (Streaming) 是一等公民

2025 年了，如果一个 Web 框架还要费劲才能支持 SSE (Server-Sent Events)，那它肯定落伍了。

在 0.2.x，你需要 `use Nex.SSE`，还需要遵循特定的函数签名。但在 AI 应用爆发的今天，流式响应应该是随处可用的标准能力。

现在，你可以在任何地方直接返回流：

```elixir
def get(req) do
  Nex.stream(fn send ->
    send.("Hello")
    Process.sleep(1000)
    send.("World")
  end)
end
```

简单直接，没有黑魔法。

---

## 🎨 总结：找回定位

开发 0.1.x 和 0.2.x 时，我有点贪心，想把 Phoenix 的强大、Next.js 的简洁、Rails 的经典全都缝合在一起。结果就是做出了一个"四不像"。

到了 0.3.x，我终于想通了：**Nex 不应该试图成为另一个 Phoenix。**

Elixir 社区已经有了 Phoenix 这样完美的工业级框架。Nex 的使命，应该是提供一个**足够简单、足够轻量**的替代品（核心代码 < 500 行）。它应该像 Next.js 一样，让开发者（尤其是独立开发者）能极速构建出可用的产品。

这就是 Nex 0.3.x 的全部意义：**删繁就简，回归开发者的直觉。**

---

## 🚀 未来展望

### 0.3.0 只是开始

这次重构不仅仅是 API 的改变，更是**设计哲学的转变**：

**从"Elixir 的 Phoenix"到"Elixir 的 Next.js"**

### 下一步计划

1. **探索 Datastar 集成**
   - 关注 Datastar 作为超媒体 (Hypermedia) 框架的发展
   - 评估是否能提供比 HTMX 更细粒度的状态更新能力
   - 保持对新兴技术的开放态度，但优先级低于核心 DX 改进

2. **极致的开发者体验 (DX)**
   - 让框架"更好用"，而不是"功能更多"
   - 更完善的文档和实战范例

### 核心不变

无论如何演进，Nex 的核心理念不会变：

- ✅ **极简**: 最少的代码，最大的生产力
- ✅ **现代**: 对齐现代框架的最佳实践
- ✅ **实用**: 解决真实世界的问题

---

## 💭 写给开发者的话

### 关于 Breaking Changes

Nex 目前还处于早期快速迭代阶段，为了追求极致的开发体验，随时可能会有破坏性的变更。

但我承诺：**我会详细记录每一次重构背后的思考过程和心路历程。**

并不是为了变更而变更，而是为了探索出最适合 Elixir 的开发体验。我希望通过分享这些思考，能和大家一起交流、学习，共同打磨出一个真正好用的框架。

而不是给出一个冷冰冰的"升级指南"，我更愿意告诉你"为什么我要这样做"。

### 给用户的承诺

1. **极简的 API**: 只需要学习 `use Nex` 和几个响应函数
2. **熟悉的开发体验**: 如果你会 Next.js，Nex 的 API 设计会让你感到亲切
3. **完善的文档**: 从入门到精通的完整教程
4. **活跃的社区**: 我们会持续改进和支持

---

**Nex 0.3.x - 极简、现代、实用的 Elixir Web 框架**

让我们一起构建更好的 Web 应用！🚀
