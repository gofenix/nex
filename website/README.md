# Nex Official Website

The official website for the Nex framework, built with Nex itself.

## Features

- **Claude-inspired Design**: Clean, minimalist aesthetic with cream background (#FBF9F1) and purple accents (#7B61FF)
- **DaisyUI Components**: Leveraging DaisyUI for consistent, accessible UI components
- **Framework Showcase**: Demonstrates Nex's core capabilities through its own implementation

## Pages

- `/` - Landing page with hero section and core features
- `/features` - Detailed feature explanations (routing, HTMX, SSE, state management, security)
- `/getting-started` - Quick start guide for new users

## Development

```bash
# From the website directory
cd website

# Install dependencies
mix deps.get

# Start the development server
iex -S mix

# Visit http://localhost:4000
```

## Project Structure

```
website/
├── src/
│   ├── application.ex       # Application entry point
│   ├── layouts.ex           # Main layout with Claude styling
│   ├── pages/               # Page modules
│   │   ├── index.ex         # Homepage
│   │   ├── features.ex      # Features page
│   │   └── getting_started.ex # Getting started guide
│   └── partials/            # Reusable components
│       ├── nav.ex           # Navigation bar
│       └── footer.ex        # Footer
├── mix.exs                  # Project configuration
└── README.md                # This file
```

## Design Principles

1. **Minimalism**: Focus on content, remove unnecessary elements
2. **Accessibility**: Semantic HTML, proper contrast ratios
3. **Performance**: Minimal dependencies, server-side rendering
4. **Authenticity**: Built with Nex to showcase real-world usage

## Deployment

The website can be deployed to any Elixir-friendly platform:

- Fly.io (recommended)
- Railway
- Docker container
- Traditional VPS

See the main Nex documentation for deployment guides.
