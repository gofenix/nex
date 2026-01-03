# Datastar 集成

Datastar 是另一个优秀的超轻量级前端增强库，它提供了声明式的状态同步能力。对于需要跨元素同步状态的复杂交互，Datastar 是一个强力选择。

## 1. 核心理念

Datastar 通过 `data-star` 属性将 HTML 元素绑定到统一的状态存储中。它与 Nex 的集成同样基于 CDN 引入，保持了零构建的优势。

## 2. 集成方式

在 `src/layouts.ex` 中引入：

```html
<script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar/dist/datastar.js"></script>
```

## 3. 示例：实时搜索过滤

```elixir
~H"""
<div data-star="{ search: '' }">
  <input type="text" data-model="search" placeholder="输入搜索词..." class="...">
  
  <ul>
    <li data-show="search == '' || 'apple'.includes(search)">苹果</li>
    <li data-show="search == '' || 'banana'.includes(search)">香蕉</li>
    <li data-show="search == '' || 'cherry'.includes(search)">樱桃</li>
  </ul>
</div>
"""
```

## 4. Datastar vs Alpine.js

*   **Alpine.js**：更适合处理传统的 UI 交互（模态框、折叠菜单、简单的逻辑）。
*   **Datastar**：在处理跨组件的大规模状态共享和复杂的前端业务逻辑时更具优势。

在 Nex 项目中，你可以根据团队习惯选择其中之一。Nex 的文件系统路由和 Action 机制可以与这两者完美配合。
