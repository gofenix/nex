# Changelog

All notable changes to the Nex framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **Mix.Tasks.Nex.Dev**: 自动检查并安装缺失的依赖，避免因未运行 `mix deps.get` 导致启动失败
- **Mix.Tasks.Nex.New**: 创建项目后自动运行 `mix deps.get`，用户可直接运行 `mix nex.dev` 启动项目

### Fixed
- **Mix.Tasks.Nex.Dev**: 修复 `app_name` 类型错误，确保 `Application.ensure_all_started/2` 接收原子类型参数

## [0.1.1] - 2025-12-28

### Fixed
- **Installer Package**: Fixed VERSION file path issue that prevented `mix archive.install hex nex_new` from working
- **Package Structure**: Both `nex_core` and `nex_new` now include their own VERSION, README.md, and CHANGELOG.md files instead of referencing parent directory

## [0.1.0] - 2025-12-28

### Published
- **Hex.pm Release**: Published `nex_core` v0.1.0 to Hex.pm at https://hex.pm/packages/nex_core/0.1.0
- **Hex.pm Release**: Published `nex_new` v0.1.0 to Hex.pm at https://hex.pm/packages/nex_new/0.1.0
- **Documentation**: Published documentation to HexDocs at https://hexdocs.pm/nex_core/0.1.0 and https://hexdocs.pm/nex_new/0.1.0

### Changed
- **Naming**: 重命名框架核心包为 `nex_core`，重命名项目生成器为 `nex_new`，以解决 Hex.pm 命名冲突。
- **Version Management**: Installer and framework now share a single VERSION file for synchronized releases
- **Dependencies**: Added `ex_doc` as dev dependency for documentation generation

## [0.1.0] - 2025-12-28

### Added
- **Nex.CSRF**: 新增 CSRF 保护模块，防止跨站请求伪造攻击
  - `Nex.CSRF.generate_token/0` - 生成 CSRF token
  - `Nex.CSRF.input_tag/0` - 生成表单隐藏字段
  - `Nex.CSRF.hx_headers/0` - 生成 HTMX hx-headers 属性
  - `Nex.CSRF.validate/1` - 验证请求中的 CSRF token
  - 自动注入到页面，HTMX 请求自动携带 `X-CSRF-Token` header
  - POST 请求自动验证 CSRF token
- **Nex.RouteDiscovery**: 新增动态路由发现模块，支持基于文件系统的路由自动发现
  - 支持单参数动态路由 `[param]`（如 `users/[id].ex` 匹配 `/users/123`）
  - 支持命名参数路由 `[slug]`（如 `posts/[slug].ex` 匹配 `/posts/hello-world`）
  - 支持多参数动态路由（如 `posts/[year]/[month].ex` 匹配 `/posts/2024/12`）
  - 支持通配符路由 `[...path]`（如 `docs/[...path].ex` 匹配任意层级路径）
  - 支持混合路由（如 `files/[category]/[...path].ex`）
  - 路由缓存机制（ETS），开发时文件变更自动刷新
  - 路由优先级排序：静态路由 > 动态路由 > 通配符路由
- **Examples**: 新增 `dynamic_routes` 示例项目，展示所有动态路由类型的用法
- **Mix.Tasks.Nex.New**: 全局项目生成器，从零创建完整 Nex 项目
  - `mix nex.new my_app` - 创建完整项目结构（无需先运行 mix new）
  - 支持指定路径 `mix nex.new my_app --path ~/projects`
  - 自动生成干净的 mix.exs，无需清理 lib/ 和 test/
  - 通过 `installer/` 目录打包为 Mix archive
- **Mix.Tasks.Nex.Release**: 新增生产构建任务
  - `mix nex.release` - 编译并打包用于部署
  - 自动生成优化后的 Dockerfile 用于容器化部署

### Changed
- **Nex.Handler**: 重构路由解析逻辑，优先使用 `Nex.RouteDiscovery` 进行动态路由匹配
  - `resolve_page_module/1` 现在支持基于文件名的动态参数提取
  - `resolve_api_module/1` 同样支持动态路由
  - `resolve_action/1` 支持动态路由下的 POST action
  - 保留 legacy 路由逻辑作为后备兼容
- **Nex.Reloader**: 文件变更时自动清除路由缓存，确保新路由立即生效
- **Nex.Reloader**: 生产环境自动禁用热重载
  - `Nex.Reloader.enabled?/0` 检查是否启用（仅 `:dev` 环境）
  - 生产环境不注入 live reload WebSocket 脚本
  - 通过 `Application.get_env(:nex, :env)` 配置环境
- **Mix.Tasks.Nex.Dev**: 重构进程启动逻辑，使用 `Nex.Supervisor` 替代手动启动单个进程
  - 原来：手动启动 Store、PubSub、Reloader（无监督）
  - 现在：通过 `Nex.Supervisor.start_link()` 统一管理（有监督）

### Added (Earlier)
- **Nex.Supervisor**: 新增框架层监督树模块，统一管理 Nex 核心进程（Store、PubSub、Reloader）
  - 任何进程崩溃会自动重启，提高框架可靠性
  - 对用户完全透明，无需额外配置
  - 符合 OTP 最佳实践

### Security
- **Nex.Handler**: Fixed atom exhaustion vulnerability (CVE-level security issue) by replacing `String.to_atom/1` with `String.to_existing_atom/1` for user-supplied input. This prevents attackers from crashing the server by requesting random paths like `/api/random_1`, `/api/random_2`, etc.
- **Nex.Handler**: Improved privacy by moving `page_id` from request payload to HTTP header (`X-Nex-Page-Id`), preventing exposure in browser dev tools and network logs
- **Nex.Store**: Added automatic process dictionary cleanup after each request using `Plug.Conn.register_before_send/2`, preventing potential session leakage when HTTP server processes are reused

### Performance
- **Nex.Store**: Optimized `touch_page/1` to use `:ets.match/2` instead of `:ets.foldl/3`, reducing complexity from O(n) to O(m) where m is the number of keys for a specific page. This significantly improves performance when the ETS table contains many pages.

### Removed
- **Mix.Tasks.Nex.Init**: 删除了 `mix nex.init` 任务。现在推荐使用 `installer` 中的 `mix nex.new` 来创建项目，以保持框架简洁和单一职责原则。

### Fixed
- **Nex.Env**: Fixed `.env` file loading to correctly resolve project root directory using `Mix.Project.app_path()` instead of relying on current working directory
- **Nex.Env**: Fixed environment variables not being accessible via `System.get_env/1` by explicitly setting loaded variables to system environment after Dotenvy parsing
- **Nex.Env**: Added debug logging to show which `.env` files are being loaded, their paths, and how many variables were loaded
- **Mix.Tasks.Nex.Dev**: Fixed user application not being started, which prevented application supervision trees (like Finch for HTTP clients) from running

### Added
- **Nex.SSE**: Added new `Nex.SSE` behaviour module for defining Server-Sent Events (SSE) endpoints
- **SSE Routing**: SSE endpoints can now be placed anywhere in the application structure (e.g., `src/api/chat/stream.ex`) and are identified by `use Nex.SSE` instead of requiring a specific `/sse/` path
- **SSE Handler**: Added `handle_sse_endpoint/3` function to automatically detect and handle modules that use `Nex.SSE` behaviour
- **Documentation**: Added comprehensive `application.md` guide explaining Application modules and supervision trees
- **Examples**: All example projects now include a default `Application` module template with documentation
- **Examples**: Added `chatbot_sse` example demonstrating SSE streaming with HTMX SSE extension for zero-JavaScript real-time streaming
- **Getting Started**: Updated quick start guide to include Application module setup

### Changed
- **SSE Routing**: SSE endpoints are now identified by `use Nex.SSE` behaviour instead of path-based detection, allowing SSE endpoints to coexist with JSON API endpoints at the same path structure
- **Handler**: Refactored API routing to check for SSE endpoints (via `__sse_endpoint__/0` function) before treating as regular API endpoints
- **Handler**: SSE format now supports plain text for `message` event type (for HTMX SSE extension compatibility) while maintaining JSON format for other event types
- **Nex.Env**: Improved `.env` file path resolution to work correctly regardless of where `mix nex.dev` is executed from
- **Nex.Env**: Enhanced error handling to show specific error messages when `.env` file loading fails
- **Examples**: All example projects (`chatbot`, `guestbook`, `todos`) now have `Application` modules configured in `mix.exs`
- **Live Reload**: Migrated from HTTP polling to WebSocket push for instant file change notifications without network request spam

### Deprecated
- **SSE Path Convention**: The `/sse/*` path convention is still supported for backward compatibility but is now considered legacy. New SSE endpoints should use `use Nex.SSE` and can be placed under `/api/*` or any other path structure
