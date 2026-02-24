# NexEnv

Environment variable management for Nex projects.

## Installation

```elixir
def deps do
  [
    {:nex_env, "~> 0.1"}
  ]
end
```

## Usage

```elixir
Nex.Env.init()
Nex.Env.get(:database_url)
Nex.Env.get!(:api_key)
Nex.Env.get_integer(:port, 4000)
Nex.Env.get_boolean(:debug, false)
```

## License

MIT
