# AI-Assisted Development (Vibe Coding)

Nex is a framework specifically optimized for **AI-assisted development**. We chose a minimalist architecture (Locality of Behavior, file system routing) and bet on declarative interaction (like HTMX) to allow AI to more accurately understand and generate complete business logic.

## 1. Why Nex's Architecture Suits AI Development?

### Locality of Behavior (LoB)
In Nex, data loading (`mount`), UI definition (`render`), and interaction logic (`Action`) for a page are all centralized in one file. For an AI, this means it only needs to understand the context of the current file to generate or modify a complete feature, without jumping between route tables, controllers, views, and templates.

### Convention Over Configuration
AI doesn't have to guess how your routes are configured. As long as it knows you've created a file at `src/pages/users/[id].ex`, it can be certain the URL is `/users/123`. This certainty significantly reduces the probability of AI generating incorrect code.

### Advantages of Declarative Interaction
Nex bets on declarative tools like HTMX because they condense complex asynchronous logic into simple HTML attributes. For an AI, generating attributes is much more robust than generating complex JavaScript asynchronous flows (Promises, Async/Await).

## 2. Writing Efficient Prompts

When telling an AI to write Nex code, follow these patterns:

### Describe Feature Modules
> "Create a `todos.ex` page under `src/pages`. The index shows a todo list and supports adding new todos. Use `Nex.Store` to store the list, and use HTMX for partial list updates upon successful addition."

### Describe Interaction Details
> "Add `hx-delete` to the delete button, calling an Action named `remove`. In the `remove` function, remove the item with the corresponding ID from `Nex.Store` and return `:empty`."

## 3. Common AI Prompt Templates

### Basic Page Template
```markdown
Please use the Nex framework to create a [Feature Name] page:
1. File location: src/pages/[filename].ex
2. mount: Initialize [Data Name] data.
3. render: Use Tailwind CSS to render [UI Description].
```

### Interaction Action Template
```markdown
Add interaction to an existing Nex page:
1. Add a function named [action_name].
2. Handle requests from [hx-post/hx-put/...].
3. Update [State Name] in `Nex.Store`.
4. Return [HTML fragment/refresh directive].
```

## 4. Common Pitfalls and Corrections

AI can sometimes use patterns from other frameworks out of habit; you need to correct it promptly:

*   **Pitfall**: AI tries to find `router.ex` in the project root.
    *   **Correction**: Tell the AI, "Nex has no global route file; please create files directly under `src/pages`."
*   **Pitfall**: AI tries to introduce large JS libraries.
    *   **Correction**: Require the AI, "Prioritize using HTMX or Alpine.js to solve interaction problems; do not introduce complex build tools."
*   **Pitfall**: AI forgets to use `Nex.Store` in an Action.
    *   **Correction**: Remind the AI, "Use `Nex.Store.get/put/update` to maintain temporary state during interactions."

## 5. Conclusion

Nex's goal is to shift the developer's role from "code porter" to "intent describer." By leveraging Nex's architectural advantages, you can significantly enhance the Vibe Coding experience.
