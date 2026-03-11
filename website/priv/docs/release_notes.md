# Nex Release Notes

## [0.4.0] - 2026-03-11

### Features
*   **Validator (`Nex.Validator`)**: Powerful data validation module to sanitize and validate incoming request parameters. Supports required fields, type casting (string, integer, float, boolean), custom regex formatting, and custom validation functions.
*   **File Uploads (`Nex.Upload`)**: Built-in support for `multipart/form-data` uploads. Access files from `req.body`, validate them (size, type, extensions), and save them securely with built-in path-traversal protection.
*   **Custom Error Pages**: You can now define a custom error module (e.g., `MyApp.ErrorPages`) in your configuration to completely customize the HTML returned for 404, 500, and other error statuses.

### Fixes & Improvements
*   Installer command injection and argument parsing fixes.
*   Fixed a memory leak in the Rate Limiter by adding periodic ETS entry cleanup.
*   Various bug fixes and DX enhancements for CSRF and Session modules.

---

## [0.3.8] - 2026-02-20

### Features
*   **WebSockets (`Nex.WebSocket`)**: User-level WebSocket support with easy routing via `src/api/*`.
*   **Rate Limiting (`Nex.RateLimit`)**: Built-in ETS-based sliding window rate limiter, available as a direct API or a Plug middleware.

---

## [0.3.7] - 2026-02-20

### Features
*   **Cookie Management (`Nex.Cookie`)**: Read and write cookies directly in your actions.
*   **Session Storage (`Nex.Session`)**: Server-side session storage backed by ETS and signed cookies.
*   **Flash Messages (`Nex.Flash`)**: One-time messages for redirects.
*   **Middleware (`Nex.Middleware`)**: Define your own Plug pipelines (e.g., for authentication) that run before the framework's router.

---

## [0.3.6] - 2026-02-20

### Features
*   **Static Asset Serving**: Automatically serve files from `priv/static/` via `/static/*`.
*   **Template Helpers**: Truncate, pluralize, clsx logic directly within `.ex` views.
*   **Better Errors**: An improved dark-themed error page for development showing exceptions and request details.

---

## [0.3.0] - 2025-12-31

### Features
*   **Unified Interface**: Introduced a single `use Nex` to replace multiple specific `use` macros.
*   **SSE Support**: Introduced `Nex.stream/1` for easy Server-Sent Events generation.
*   **API Improvements**: Re-designed `req` struct to align with modern web framework standards (Next.js).
