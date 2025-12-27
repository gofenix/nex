# Nex 文档

欢迎阅读 Nex 框架文档。Nex 是一个极简主义的 Elixir Web 框架，专注于服务端渲染和 HTMX 驱动的交互。

## 目录

### 入门

- [快速开始](./getting-started.md) - 创建你的第一个 Nex 应用
- [项目结构](./project-structure.md) - 了解 Nex 项目的目录组织
- [路由](./routing.md) - 文件即路由的工作原理

### 核心概念

- [Pages](./pages.md) - 页面渲染和 HTMX 交互处理
- [API](./api.md) - 构建 JSON API
- [Partials](./partials.md) - 可复用的 UI 组件
- [Layouts](./layouts.md) - 页面布局
- [Store](./store.md) - 页面级状态管理

### 进阶

- [HTMX 集成](./htmx.md) - 深入理解 HTMX 与 Nex 的配合
- [环境变量](./environment.md) - 配置管理
- [错误处理](./error-handling.md) - 错误页面和异常处理
- [开发工具](./development.md) - 热重载和开发服务器

### 参考

- [API 参考](./api-reference.md) - 所有模块和函数
- [示例项目](./examples.md) - 完整示例代码

---

## 设计哲学

Nex 遵循以下设计原则：

1. **极简** — 最少的概念，最少的样板代码
2. **服务端优先** — 状态和渲染都在服务端
3. **文件即路由** — 文件路径就是 URL 路径
4. **零 JS 构建** — 不需要 Node.js 或前端构建工具

## 快速链接

- [GitHub 仓库](https://github.com/user/nex)
- [示例项目](../examples/todos)
- [Changelog](../CHANGELOG.md)
