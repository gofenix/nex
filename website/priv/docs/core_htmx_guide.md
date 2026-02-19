# Declarative Interaction and Core Protocol

Nex's core competitiveness lies in its deep and seamless integration with declarative tools like HTMX. Nex is not just a backend returning HTML; it extends the underlying interaction through a private protocol, providing automated security and state management.

## 1. Why Bet on Declarative Interaction?

In mainstream Web development, frontend state management and API synchronization consume a massive amount of effort. We believe:
*   **Locality of Behavior (LoB)**: Interaction logic should be written directly on HTML elements.
*   **Server-Driven**: Complex business state should remain on the server, with the frontend only responsible for rendering and triggering actions.
*   **Eliminating Glue Code**: Defining asynchronous behavior directly through HTML attributes eliminates thousands of lines of JavaScript boilerplate code.

## 2. Automatic Security Protection (CSRF)

Nex mandates that all non-GET requests must pass CSRF validation.

### Automated Process
1.  **Token Generation**: Every time a page is initially rendered, Nex generates a strongly encrypted CSRF Token for the current session.
2.  **Meta Tag Injection**: Nex automatically injects `<meta name="csrf-token" content="...">` into `</head>` on every page render.
3.  **Script Injection**: Nex automatically injects a lightweight JS snippet that listens for all HTMX requests (`htmx:configRequest` event) and puts the Token in the `X-CSRF-Token` request header.
4.  **Form Token Injection**: Nex automatically injects a hidden `_csrf_token` input into all forms with `method="post/put/patch/delete"` **and** all HTMX forms using `hx-post`, `hx-put`, `hx-patch`, or `hx-delete`.
5.  **Server Validation**: Nex's handler automatically intercepts and validates this header. If validation fails, the request is rejected (403 Forbidden).

> **Fully Automated**: Developers do not need to add `{meta_tag()}`, `hx-headers={hx_headers()}`, or `{csrf_input_tag()}` anywhere. Just write your forms and HTMX attributes — Nex handles all security boilerplate automatically.

## 3. State Isolation (Page ID)

To allow `Nex.Store` to distinguish between different page instances, Nex introduced the `page_id` concept.

*   **Uniqueness**: Every full page load gets a new `page_id`.
*   **Automatic Transfer**: Injected JS scripts automatically put the current page's `page_id` in the `X-Nex-Page-Id` request header.
*   **Purpose**: The server uses this ID to isolate storage space in ETS, ensuring a shopping cart in tab A doesn't affect tab B.

## 4. Smart Error Handling

Nex's handler can identify the intent of a request and return the most appropriate error response:

*   **HTMX Scenario**: Returns a styled red error message fragment. This ensures that even if the backend crashes, your page layout (navbar, sidebar) remains intact, and only the requested part displays an error.
*   **API Scenario**: Returns a standard `{"error": "..."}` JSON format.
*   **Direct Access**: Returns a full-page HTML error page with Stacktrace.

## 5. Controlling Response Types

In an Action, you can return different directives to control HTMX behavior:

| Return Type | HTTP Header | Browser Behavior |
| :--- | :--- | :--- |
| **HEEx / String** | `Content-Type: text/html` | Partial replacement of specified DOM |
| **`:empty`** | - | No DOM change |
| **`{:redirect, url}`** | `HX-Redirect` | Client-side forced redirect to new URL |
| **`{:refresh}`** | `HX-Refresh` | Client-side forced refresh of current page |
| **`Nex.stream/1`** | `Content-Type: text/event-stream` | Starts SSE listening |
