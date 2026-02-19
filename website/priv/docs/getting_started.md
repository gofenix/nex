# Quick Start

Get a Nex application up and running in just 5 minutes.

## 🛠️ Install Nex

It is recommended to install the Nex CLI tool via Hex:

```bash
mix archive.install hex nex_new
```

### Install from Source (Advanced Users)
If you want to experience the latest features, you can install from source:

1.  **Clone the Nex repository**:
    ```bash
    git clone https://github.com/gofenix/nex.git
    cd nex/installer
    ```

2.  **Compile and install the archive**:
    ```bash
    mix do deps.get, compile, archive.install
    ```

## 📦 Create a New Project

Run the `nex.new` task to create a new project directory:

```bash
mix nex.new my_app
cd my_app
mix deps.get
```

## 🚀 5-Minute Hello World

1.  **Create your first page**:
    Nex uses file system routing. Write the following in `src/pages/index.ex`:

    ```elixir
    defmodule MyApp.Pages.Index do
      use Nex

      def mount(_params) do
        %{message: "Hello, Nex!"}
      end

      def render(assigns) do
        ~H"""
        <div class="p-8 text-center">
          <h1 class="text-4xl font-bold text-indigo-600">{@message}</h1>
          <p class="mt-4 text-gray-600">Welcome to the minimalist server-driven Web world.</p>
          <button hx-post="/say_hi"
                  hx-target="#response"
                  class="mt-6 px-4 py-2 bg-indigo-500 text-white rounded">
            Click Me
          </button>
          <div id="response" class="mt-4 font-semibold text-green-600"></div>
        </div>
        """
      end

      def say_hi(_params) do
        "Hello! This is an HTML fragment returned via declarative interaction."
      end
    end
    ```

2.  **Run the development server**:
    ```bash
    mix nex.dev
    ```

3.  **Visit the page**:
    Open your browser and go to `http://localhost:4000`. Try clicking the button and experience interaction without a full page refresh.

## 📁 Project Structure

Nex's directory structure follows "convention over configuration," aiming to eliminate all unnecessary engineering complexity:

*   `src/`: **Core application code**
    *   `pages/`: Page modules (GET requests, automatically mapped to URLs).
    *   `api/`: JSON API modules.
    *   `components/`: Reusable UI components.
    *   `layouts.ex`: Global HTML template.
    *   `application.ex`: OTP application entry point.
*   `.env`: Environment configuration file (automatically loaded).
*   `mix.exs`: Project dependency management.
