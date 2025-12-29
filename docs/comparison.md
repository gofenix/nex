# Nex (HTMX) vs Phoenix LiveView

Both Nex and Phoenix LiveView are excellent choices for building Web applications in the Elixir ecosystem, but they adopt distinctly different architectural models. Understanding these differences helps you choose the right tool for your project.

## Core Differences Summary

| Feature | Nex (HTMX) | Phoenix LiveView |
| :--- | :--- | :--- |
| **Protocol** | **HTTP** (Stateless Request/Response) | **WebSocket** (Stateful Persistent Connection) |
| **State Location** | **Client/Temporary** (ETS Cache, lost on refresh) | **Server Process** (GenServer, persistent) |
| **Concurrency Model** | Each interaction is an independent process (Plug model) | One long-running process per user |
| **Deployment Cost** | Low (Stateless, easy to scale horizontally) | Medium/High (Requires maintaining many long-lived connections, higher memory usage) |
| **Use Cases** | CRUD apps, Admin panels, Content sites | Real-time collaboration, Games, High-frequency data dashboards |

---

## 1. Communication Model

### Nex: HTTP First
The core of Nex is `Nex.Handler`, which is a standard Plug pipeline.
*   **Interaction**: Click button -> Send HTTP POST -> Server returns HTML fragment -> HTMX updates DOM.
*   **Pros**: Aligns with traditional Web and its caching mechanisms; performs better on unstable networks (standard HTTP retries); server resource usage is transient.
*   **Code Evidence**: `Nex.Handler` handles `post` requests and returns `send_resp(200, html)`.

### LiveView: WebSocket First
LiveView establishes a WebSocket connection after the page loads.
*   **Interaction**: Click button -> Send message via WS -> Server process handles it -> Push Diff via WS -> JS updates DOM.
*   **Pros**: Extremely low latency; can actively push messages to the client (PubSub).

---

## 2. State Management

### Nex: Page-Scoped State
Nex uses `Nex.Store` (based on ETS) to simulate state.
*   **Lifecycle**: State is bound to `page_id`. Refreshing the page generates a new ID, and old state is lost.
*   **Connectionless**: You don't need to maintain a connection to keep state. State is passed between requests via the `X-Nex-Page-Id` HTTP Header.
*   **Code Evidence**: `Nex.Store.put/2` and `get_page_id_from_request/1` in `Nex.Handler`.

### LiveView: Process State
LiveView's state is kept in the memory of a GenServer process (`socket.assigns`).
*   **Lifecycle**: State exists as long as the WebSocket connection exists.
*   **Crash Recovery**: If the process crashes, state is lost, and the client attempts to reconnect.

---

## 3. Why Choose Nex?

### ✅ Simplicity
Nex removes the complexity of LiveView (mount lifecycle, change tracking, temporary assigns, etc.). You just write simple functions that take parameters and return HTML.

### ✅ Scalability
Being based on short-lived HTTP connections, Nex apps are easier to deploy and auto-scale on Serverless platforms (like AWS Lambda, Fly.io Machines) without worrying about WebSocket disconnection or re-routing issues.

### ✅ Progressive Enhancement
Nex is essentially server-rendered HTML. This makes it more SEO-friendly and easier to integrate with the existing HTTP ecosystem (load balancers, CDN caching).

---

## 4. When to Use LiveView?

*   You need **extremely high frequency** UI updates (e.g., real-time multiplayer games, stock charts).
*   You need **server push** (PubSub) capability (although Nex supports SSE, LiveView's PubSub is more seamless).
*   You need complex **client-server state synchronization** and cannot tolerate any HTTP overhead.

## Summary

*   **Nex** is "Elixir's Rails + Hotwire" or "PHP Laravel + HTMX". Suitable for 90% of Web apps.
*   **LiveView** is an SPA alternative for those seeking the ultimate interactive experience.
