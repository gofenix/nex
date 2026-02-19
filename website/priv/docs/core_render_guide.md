# Rendering Lifecycle

Understanding Nex's rendering lifecycle is the cornerstone of building efficient, stateless-feeling applications. Nex's rendering process is straightforward and divided into two main phases.

## 1. Initial Render (Full Page Load)

When you access a URL directly via the browser address bar (GET request), Nex performs the following:

1.  **Route Matching**: Finds the corresponding page module based on the file system route.
2.  **Page ID Generation**: The framework generates a unique `page_id` for this visit.
3.  **Execute `mount(params)`**:
    *   Receives URL parameters and query parameters.
    *   Initialize data here (e.g., read from database).
    *   Returns the `assigns` Map.
4.  **Execute `render(assigns)`**:
    *   Renders the HEEx template using `assigns`.
5.  **Inject Layout**:
    *   Passes the rendered result as `@inner_content` to `src/layouts.ex`.
    *   **Automated Injection**: Automatically injects `<meta name="csrf-token">` before `</head>`, and injects a JS snippet (CSRF + Page ID configuration for HTMX) before `</body>`.
6.  **Respond to Client**: Returns the full HTML document.

## 2. Asynchronous Interaction (Action Update)

When you initiate a request via HTMX (e.g., `hx-post`), the lifecycle changes:

1.  **Action Matching**: Finds the target Action function based on the URL path or Referer.
2.  **Execute Action**:
    *   **Skip mount**: For performance and locality, Actions do not re-execute the page's `mount`.
    *   Receives request parameters.
    *   Returns an HTML fragment or control directives (e.g., `{:refresh}`).
3.  **Partial Update**:
    *   HTMX receives the response and only updates part of the page according to `hx-target`.
    *   **State Persistence**: Although `mount` didn't run, you can read previously stored state via `Nex.Store`.

## 3. Page Refresh = State Reset

This is one of the most important design decisions in the Nex architecture:

*   **Full Page Refresh (F5)**: The browser discards all current state, Nex initiates a new GET request, and a **brand new Page ID** is generated.
*   **Consequence**: Since `Nex.Store` state is bound to the `page_id`, old state becomes inaccessible (and is later cleaned up by TTL).
*   **Design Intent**: Ensures the Web application behaves according to the user's intuition—"refreshing the page returns to the initial state," avoiding complex stale data cleanup issues.

## Summary

| Feature | Initial Render (GET) | Action Interaction (POST/...) |
| :--- | :--- | :--- |
| **Execute mount** | Yes | No |
| **Generate Page ID** | New | Persist |
| **Layout Wrap** | Yes | No (Returns fragment only) |
| **State Reading** | Initial State | Can read cumulative state from Store |
