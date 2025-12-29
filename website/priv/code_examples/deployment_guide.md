# Nex Deployment Guide

This guide covers how to deploy Nex applications (both Web pages and JSON APIs) to production environments.

Since Nex uses a unified architecture where Web pages and APIs run within the same Elixir process, their deployment methods are identical.

## Table of Contents

- [Development vs Production](#development-vs-production)
- [Static Assets Strategy](#static-assets-strategy)
- [Start Command](#start-command)
- [Environment Variables](#environment-variables)
- [Docker Deployment](#docker-deployment)

---

## Development vs Production

Nex provides two distinct Mix tasks to run your application:

### Development Mode (`mix nex.dev`)
*   Enables Live Reload: Automatically refreshes browser on file changes.
*   Shows detailed error pages.
*   Default port: 4000

### Production Mode (`mix nex.start`)
*   **Disables Live Reload**: Optimizes performance.
*   Shows only concise error messages.
*   Loads `.env` file (if present).
*   **Auto-compile**: Automatically ensures code is compiled before starting.

---

## Static Assets Strategy

**Important: The Nex framework does not serve local static files.**

To maintain simplicity and high performance, Nex has removed `Plug.Static`. This means you cannot place images, CSS, or JS files in the `priv/static` directory and expect to access them via URL.

### How to Handle Static Assets?

1.  **CSS/JS**: Use CDNs.
    *   Tailwind CSS and DaisyUI are loaded via CDN by default (see `src/layouts.ex`).
    *   If you need custom scripts, reference external URLs directly in the Layout.

2.  **Images/Media**:
    *   **Recommended**: Upload to object storage (like AWS S3, Cloudflare R2, Aliyun OSS) and get public URLs.
    *   **Inline**: For very small icons (SVG), inline the code directly into HEEx templates.

### Why No Build Step?

Nex adopts a **No-Build** strategy.
*   No Webpack/Vite/Esbuild.
*   No `node_modules`.
*   No `npm run build`.

This means your "frontend deployment" is effectively just deploying the Elixir backend code.

---

## Start Command

In production environments, use the following command to start the service:

```bash
mix nex.start
```

This command automatically:
1.  Sets the application environment to `:prod`.
2.  Starts the Web Server (Bandit).
3.  Initializes the application supervision tree.

---

## Environment Variables

Nex respects [12-Factor App](https://12factor.net/) principles and is configured via environment variables.

| Variable Name | Default Value | Description |
| :--- | :--- | :--- |
| `PORT` | `4000` | HTTP listening port |
| `HOST` | `0.0.0.0` | Binding IP address |

You can create a `.env` file in the project root, and `mix nex.start` will automatically load it:

```bash
# .env
PORT=8080
SECRET_KEY=...
```

---

## Docker Deployment

This is the recommended way to deploy to production. Every Nex project generates a production-ready `Dockerfile` upon creation.

### 1. Build Image

```bash
docker build -t my_app .
```

### 2. Run Container

```bash
docker run -p 4000:4000 -e PORT=4000 my_app
```

### Dockerfile Breakdown

Nex's Dockerfile is based on `elixir:1.18-alpine`, keeping it small and secure.

```dockerfile
FROM elixir:1.18-alpine

# Install runtime dependencies
RUN apk add --no-cache build-base git openssl ncurses-libs

WORKDIR /app

# Install Hex and Rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy project files
COPY . .

# Get dependencies
RUN mix deps.get

# Expose port
EXPOSE 4000

# Start command
CMD ["mix", "nex.start"]
```

### Platform Adaptation

*   **Fly.io / Railway / Render**: These platforms automatically detect the Dockerfile. Simply connect your GitHub repository to build and deploy automatically.
*   **Kubernetes / VPS**: Use the Docker workflow described above.
