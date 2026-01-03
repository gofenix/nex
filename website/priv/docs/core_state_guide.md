# State Management Depth

Nex provides a unique state management philosophy aimed at solving the "state explosion" problem in modern Web development.

## 1. Layers of State

In a Nex application, state is typically divided into three layers:

| Dimension | Client State (e.g. Alpine.js)* | Page State (Nex.Store) | Persistent State (DB) |
| :--- | :--- | :--- | :--- |
| **Storage Location** | Browser Memory | Server Memory (ETS) | Disk (PostgreSQL/Etc) |
| **Lifecycle** | During page load | Within Page ID lifecycle | Permanent (until deleted) |
| **Use Case** | Menu toggles, instant previews | Shopping carts, temporary forms, search filters | User profiles, order data |
| **Sync Overhead** | 0 (Local) | Low (AJAX) | High (DB IO) |

*\*Note: Nex does not include client-side JS libraries by default. This layer is applicable only if you choose to include libraries like Alpine.js or Datastar.*

## 2. Nex.Store Design Intent: Ephemeral State

Nex.Store is specifically designed for **Ephemeral State**.

### Why Choose Ephemeral?
In HTMX's interaction model, we often need to store data that is "longer than a request but shorter than a session." For example:
*   Data partially filled by a user in a multi-step form.
*   Current page sorting and filtering criteria.
*   Sidebar collapse state.

By binding to `page_id`, Nex ensures that these states are automatically cleared when the user **refreshes the page**, avoiding the "dirty state" residue problems common in traditional Session mechanisms.

## 3. ETS Implementation and Performance

Nex.Store is implemented under the hood using Erlang's **ETS (Erlang Term Storage)** tables:

*   **Concurrency**: ETS supports extremely high concurrent reads and writes, suitable for handling real-time interactions for a large number of users.
*   **Memory-Resident**: Data is stored in memory, providing extremely fast access.
*   **TTL Cleanup**:
    *   Every record has an `expires_at` timestamp.
    *   A background `Nex.Store.Janitor` process periodically scans and deletes expired records.
    *   **Automatic Renewal**: Any `get` or `put` operation on state under a specific `page_id` automatically extends the lifecycle of all state under that ID.

## 4. Best Practices

### When to Use Nex.Store?
*   **Temporary Accumulation**: Like a shopping cart, where a user keeps adding items on the current page.
*   **Interaction Feedback**: Storing intermediate results after an asynchronous operation.
*   **Sharing Across Actions**: Passing context between different interaction functions on a page.

### When **NOT** to Use It?
*   **Sensitive Data**: Do not store user passwords or secrets in the memory Store.
*   **Large Data Volumes**: Store is suitable for metadata and small structures, not for storing hundreds of MBs of file content.
*   **Critical Persistence**: If data must exist after a user refresh (like a completed order), be sure to write it to the database.

## 5. Debugging Tips

In development mode, you can use the Elixir console to check the current status of the Store:

```elixir
# View all active state keys and values
:ets.tab2list(:nex_store)
```
