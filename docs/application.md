# Application Module

## Overview

Every Nex application should have an `Application` module that defines the application's supervision tree. This module is automatically started when you run `mix nex.dev` or deploy your application.

## Why Use an Application Module?

The Application module allows you to:

- **Supervise long-running processes** - Database connections, HTTP clients, caches, etc.
- **Manage application lifecycle** - Initialize resources on startup, clean up on shutdown
- **Follow OTP best practices** - Leverage Erlang/OTP's battle-tested supervision strategies

## Basic Structure

Create a file at `src/application.ex`:

```elixir
defmodule MyApp.Application do
  @moduledoc """
  The MyApp application.
  
  This module defines the application supervision tree.
  """
  
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add supervised processes here
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

## Configuration

Update your `mix.exs` to reference the Application module:

```elixir
def application do
  [
    extra_applications: [:logger],
    mod: {MyApp.Application, []}  # Add this line
  ]
end
```

## Common Use Cases

### HTTP Client (Finch)

If you're using `Req` for HTTP requests (e.g., calling external APIs):

```elixir
def start(_type, _args) do
  children = [
    {Finch, name: MyApp.Finch}
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

Then use it in your code:

```elixir
Req.post(url, json: body, finch: MyApp.Finch)
```

### Database Connection Pool (Ecto)

```elixir
def start(_type, _args) do
  children = [
    MyApp.Repo
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

### Custom GenServer

```elixir
def start(_type, _args) do
  children = [
    {MyApp.Cache, []},
    {MyApp.Worker, []}
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Empty Application Module

Even if you don't need supervised processes right now, it's recommended to create an empty Application module. This makes it easy to add supervised processes later without changing your project structure:

```elixir
def start(_type, _args) do
  children = [
    # Add supervised processes here when needed
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Supervision Strategies

The `:one_for_one` strategy means if a child process crashes, only that process is restarted. Other strategies include:

- `:one_for_all` - If one child crashes, all children are restarted
- `:rest_for_one` - If one child crashes, that child and all children started after it are restarted

For most Nex applications, `:one_for_one` is the right choice.

## Examples

See the example applications for reference:

- **chatbot** - Uses Finch for HTTP client
- **guestbook** - Empty supervision tree (ready for future additions)
- **todos** - Empty supervision tree (ready for future additions)

## Learn More

- [Elixir Application Behavior](https://hexdocs.pm/elixir/Application.html)
- [OTP Supervision Trees](https://hexdocs.pm/elixir/Supervisor.html)
