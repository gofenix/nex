# Architecture and Design Decisions

Nex is dedicated to providing an extremely efficient Web architecture suitable for AI-assisted development. Understanding its internal mechanisms will help you build more robust applications.

## 1. Request Processing Flow

Every request entering a Nex application passes through these core components:

1.  **Bandit / Cowboy (Web Server)**: High-performance underlying Web server receives raw TCP/HTTP requests.
2.  **Nex.Router (Plug.Router)**: Parses basic paths, distinguishing between built-in endpoints (like hot reload) and business logic.
3.  **Nex.Handler (Core Dispatcher)**:
    *   **Context Preparation**: Initializes `Nex.Req`, clears the process dictionary.
    *   **Security Validation**: Automatically performs CSRF validation (for non-GET requests).
    *   **Route Dispatch**: Dispatches to `Api` or `Pages` based on `RouteDiscovery` results.
    *   **State Association**: Extracts `page_id` from Headers and associates it with `Nex.Store`.
    *   **Result Conversion**: Converts business logic results (HEEx, Map, or directives) into standard HTTP responses.

## 2. Compile-Time Magic: `use Nex`

When you write `use Nex`, the framework performs the following behind the scenes:

*   **Auto-Import**: Imports `Phoenix.Component` (HEEx engine), `Nex.CSRF` (security helpers), and core response functions.
*   **Attribute Injection**: Automatically adds necessary metadata to the module to facilitate scanning by `RouteDiscovery`.
*   **Development Assistance**: In development environments, injects metadata required for hot reloading.

## 3. Route Discovery Mechanism (`RouteDiscovery`)

Nex does not use traditional route table files; instead, it adopts a **dynamic scanning + caching** mechanism:

*   **Scanning Rules**: Upon startup, it scans all `.ex` files under `src/pages` and `src/api`.
*   **Priority Algorithm**:
    1.  Static paths (e.g., `new.ex`) > Dynamic paths (e.g., `[id].ex`).
    2.  Fewer parameters yield higher priority.
    3.  Deeper path depth yields more precise matching.
*   **Hot Reload Support**: In development mode, file changes automatically trigger cache clearing, and the next request re-scans the file system, achieving second-level hot updates.

## 4. Core Design Decisions

### Why Choose ETS-Based Store?
*   **Performance**: Avoids database IO overhead, supporting extremely high-frequency real-time interactions.
*   **Concurrency**: Thanks to the BEAM concurrency model, each user's state is independent.
*   **Simplified Logic**: Developers don't need to manage session synchronization; just `get` and `put`.

### Why Enforce JSON API Specifications?
*   **Type Safety**: Ensures all interfaces return consistent JSON structures.
*   **DX (Developer Experience)**: Provides precise fix guidance upon errors, instead of having developers dig through source code.

### Why Bet on Declarative Interaction?
*   **Reducing Cognitive Load**: Modern Web development has become overly complex with frontend engineering and state synchronization. We bet that declarative interaction (like HTMX) can cover 90% of interaction needs, letting developers refocus on business logic rather than glue code.
