# What is Nex?

Nex is an extremely minimalist Web framework based on Elixir. Its core goal is to: **Bring back the joy of "Server-Driven" Web development by eliminating the complexity of frontend engineering.**

## 🚀 Framework Positioning

Nex is a bet on **simplicity**. We chose **HTMX** as the default interaction layer because we believe that for most Web applications, server-side rendering combined with lightweight declarative interactions provides development efficiency far exceeding current mainstream frontend stacks.

Nex is not a replacement for Phoenix, but a **lightweight alternative** for specific scenarios.

*   **Minimalism**: No tedious configuration files, no complex JavaScript build processes (No Node.js, No Webpack/Esbuild).
*   **Declarative Interaction**: With HTMX, achieve asynchronous interactions through simple HTML attributes without manually writing complex AJAX logic.
*   **Vibe Coding Friendly**: Specifically optimized for AI-assisted programming, with highly localized code structures (Locality of Behavior).

## ✨ Core Features

### 1. Minimalist Interaction Model
Nex simplifies asynchronous interaction into HTML attributes. We bet that HTMX can cover 90% of interaction needs without introducing heavy client-side frameworks.

### 2. File System Routing
Project structure is the router.
*   `src/pages/index.ex` -> `/`
*   `src/pages/users/[id].ex` -> `/users/123`
*   `src/api/login.ex` -> `/api/login`

### 3. Server-Side State Management (`Nex.Store`)
Nex provides a page-based state storage mechanism. This is a rethinking of how "ephemeral state" is handled in Web interactions, keeping state synchronized with the user's mental model of the "page lifecycle."

### 4. Smart Error Handling
Nex automatically chooses the best error display based on request intent, ensuring reasonable feedback across asynchronous fragment updates, JSON APIs, or full-page navigation.
