# Learning Path

Whether you're a frontend expert, a backend developer, or a coding beginner, Nex can get you up and running quickly. Choose the learning path that best fits your background.

## 🌱 Zero-Experience Path
If you're just starting with Web development, Nex is a perfect starting point because it shields you from the complexity of modern frontend engineering (Node.js, Webpack, Bundlers).

1.  **HTML/CSS Basics**: Understand basic HTML tags and Tailwind CSS classes (built-in by default).
2.  **Elixir Introduction**: Master basic syntax, Maps, Lists, and pattern matching.
3.  **The Nex Trinity**:
    *   Learn `mount/1`: How to initialize data.
    *   Learn `render/1`: How to write templates.
    *   Learn `Action`: How to handle clicks and forms.
4.  **Hands-on Practice**: Follow tutorials to write a simple "Personal Profile" or "Counter."

## 🐘 Backend-Experienced Path (Rails, Django, Go)
If you're used to server-side rendering (SSR) and traditional MVC architecture, you'll find Nex to be like a traditional development mode with "wings."

1.  **Interaction Model**: Understand how Nex uses HTML attributes (defaulting to HTMX) to send asynchronous requests and perform partial updates, avoiding tedious JavaScript.
2.  **File Routing**: Adapt to life without `routes.rb` or `urls.py`—your folder structure is your API.
3.  **State Isolation**: Understand how `Nex.Store` manages page-level state based on `page_id`, which differs from traditional Sessions.
4.  **Advanced**: Explore how to build standard JSON APIs with Nex for other clients.

## ⚛️ Frontend-Experienced Path (React, Vue, Next.js)
If you're tired of managing complex client-side state, data synchronization, and massive JS bundle sizes, Nex will take you back to the "zero-bundle-size" era.

1.  **Mindset Shift**: Give up the idea of "client-side managing all state." In Nex, state is usually kept on the server or in the URL.
2.  **Locality of Behavior (LoB)**: Observe how interaction logic is written directly on HTML tags (hx-*) rather than being scattered in `useEffect` or `methods`.
3.  **Alpine.js Integration**: If you truly need complex client-side animations or instant UI state (like opening a modal), learn how to use Alpine.js to complement Nex.
4.  **Performance Comparison**: Feel how fast "raw HTML replacement" is without a Virtual DOM.
