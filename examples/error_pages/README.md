# Custom Error Pages Example

Demonstrates custom error page handling with Nex 0.4.

## Features

- Custom error page module with `render_error/4`
- Different styled pages for 404, 403, 500 errors
- Programmatic error triggering for testing

## Run

```bash
cd examples/error_pages
mix deps.get
mix nex.dev
```

Visit:
- http://localhost:4000 - Home page with links to trigger errors
- http://localhost:4000/not-found - Triggers 404
- http://localhost:4000/forbidden - Triggers 403
- http://localhost:4000/error - Triggers 500

## Configuration

Custom error module is set in `src/application.ex`:

```elixir
Application.put_env(:nex_core, :error_page_module, ErrorPagesExample.ErrorPages)
```
