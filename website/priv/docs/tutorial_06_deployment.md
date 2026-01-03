# Deployment

Nex applications are standard Elixir applications, and we recommend containerized deployment for running on various platforms.

## 🐳 Docker Deployment (Recommended)

Every project created with `mix nex.new` includes an optimized `Dockerfile`.

1.  **Build the Image**:
    ```bash
    docker build -t my_nex_app .
    ```

2.  **Run the Container**:
    ```bash
    docker run -p 4000:4000 -e SECRET_KEY_BASE=your_secret my_nex_app
    ```

## 🚀 Cloud Platform Deployment

### Railway (Fastest)
1.  Connect your GitHub repository.
2.  Railway will automatically detect the `Dockerfile` and start building.
3.  Add `SECRET_KEY_BASE` in the environment variables (generate one with `mix phx.gen.secret`).

### Fly.io
1.  Install `flyctl`.
2.  Run `fly launch`.
3.  Fly.io will automatically detect the Elixir project and guide you through deployment.

### Render
1.  Create a new "Web Service."
2.  Connect your repository and choose "Docker" as the environment.
3.  Configure the port to 4000.

## 📋 Deployment Checklist

*   [ ] **SECRET_KEY_BASE**: Ensure this secret is set in the environment variables.
*   [ ] **Static Assets**: While Nex supports basic static file serving, it's recommended to use a CDN under high load.
*   [ ] **Health Check**: Configure your load balancer to check the `/` path; a 200 status code indicates the application is healthy.
