# State Management Depth

Nex provides a unique state management philosophy aimed at solving the "state explosion" problem in modern Web development. It provides distinct tools for different state lifecycles: `Nex.Store`, `Nex.Session`, `Nex.Cookie`, and `Nex.Flash`.

## 1. Layers of State

In a Nex application, state is typically divided into multiple layers:

| Dimension | Client State (Alpine/JS) | Page State (`Nex.Store`) | Session State (`Nex.Session`) | Persistent State (DB) |
| :--- | :--- | :--- | :--- | :--- |
| **Storage Location** | Browser Memory | Server Memory (ETS) | Server Memory (ETS) | Disk (PostgreSQL/Etc) |
| **Lifecycle** | During page load | Within Page ID lifecycle | Cross-page (until expiration or logout) | Permanent (until deleted) |
| **Use Case** | Menu toggles, instant previews | Shopping carts, temporary forms, search filters | User authentication (login status), preferences | User profiles, order data |
| **Sync Overhead** | 0 (Local) | Low (AJAX) | Low (AJAX/Navigation) | High (DB IO) |

*\*Note: Nex does not include client-side JS libraries by default. This layer is applicable only if you choose to include libraries like Alpine.js or Datastar.*

## 2. Nex.Store Design Intent: Ephemeral State

`Nex.Store` is specifically designed for **Ephemeral State**.

### Why Choose Ephemeral?
In HTMX's interaction model, we often need to store data that is "longer than a request but shorter than a session." For example:
*   Data partially filled by a user in a multi-step form.
*   Current page sorting and filtering criteria.
*   Sidebar collapse state.

By binding to `page_id`, Nex ensures that these states are automatically cleared when the user **refreshes the page**, avoiding the "dirty state" residue problems common in traditional Session mechanisms.

## 3. Session, Cookies, and Flash

For state that *must* survive page reloads or navigations, Nex provides dedicated modules:

### `Nex.Session`
Used for storing cross-page state, most commonly authentication tokens and user preferences.
*   Backed by server-side ETS.
*   Identified by a signed, cryptographically secure cookie (`_nex_session`).
*   Requires `SECRET_KEY_BASE` environment variable in production.
```elixir
# Store user ID upon login
Nex.Session.put(:user_id, 123)

# Retrieve it in other routes
user_id = Nex.Session.get(:user_id)
```

### `Nex.Cookie`
Direct access to read and write HTTP cookies. Useful for client-side accessible preferences (like theme) or tracking.
```elixir
Nex.Cookie.put("theme", "dark", max_age: 86400 * 30)
```

### `Nex.Flash`
A specialized session store for one-time messages (e.g., "User saved successfully!").
*   Flash messages survive exactly one redirect.
*   They are automatically cleared after being read.
```elixir
# In your action
Nex.Flash.put(:success, "Profile updated")
{:redirect, "/profile"}

# In your layout or page
flash = Nex.Flash.get(:success)
```

## 4. ETS Implementation and Performance

`Nex.Store` and `Nex.Session` are implemented under the hood using Erlang's **ETS (Erlang Term Storage)** tables:

*   **Concurrency**: ETS supports extremely high concurrent reads and writes, suitable for handling real-time interactions for a large number of users.
*   **Memory-Resident**: Data is stored in memory, providing extremely fast access.
*   **TTL Cleanup**:
    *   Every record has an `expires_at` timestamp.
    *   A background process periodically scans and deletes expired records to prevent memory leaks.
    *   **Automatic Renewal**: Any `get` or `put` operation on state automatically extends its lifecycle.

## 5. Best Practices

### When to Use `Nex.Store`?
*   **Temporary Accumulation**: Like a shopping cart, where a user keeps adding items on the current page.
*   **Interaction Feedback**: Storing intermediate results after an asynchronous operation.
*   **Sharing Across Actions**: Passing context between different interaction functions on a single page.

### When to Use `Nex.Session`?
*   **Authentication**: Tracking if a user is logged in.
*   **Preferences**: Storing dark mode / light mode if it needs to apply site-wide.

### When **NOT** to Use In-Memory State?
*   **Sensitive Data**: Do not store passwords or highly sensitive secrets in the memory Store.
*   **Large Data Volumes**: Store and Session are suitable for metadata and small structures, not for storing hundreds of MBs of file content.
*   **Critical Persistence**: If data must exist after a user closes their browser (like a completed order), be sure to write it to the database.
