defmodule Nex.Env do
  @moduledoc """
  Environment variable management.

  Loads from .env files and system environment.
  """

  @doc "Initialize environment from .env files"
  def init do
    env = Mix.env() |> to_string()

    # Get project root directory (parent of _build)
    project_root =
      case Mix.Project.app_path() do
        nil -> File.cwd!()
        app_path ->
          # app_path is like "_build/dev/lib/chatbot"
          # We need to go up to project root
          app_path
          |> Path.dirname()  # _build/dev/lib
          |> Path.dirname()  # _build/dev
          |> Path.dirname()  # _build
          |> Path.dirname()  # project root
      end

    files =
      [".env", ".env.#{env}"]
      |> Enum.map(&Path.join(project_root, &1))
      |> Enum.filter(&File.exists?/1)

    if files != [] do
      IO.puts("[Nex.Env] Loading environment from: #{Enum.join(files, ", ")}")

      case Dotenvy.source(files) do
        {:ok, vars} ->
          # Set all loaded variables to system environment
          Enum.each(vars, fn {key, value} ->
            System.put_env(key, value)
          end)
          IO.puts("[Nex.Env] ✓ Environment loaded successfully (#{map_size(vars)} variables)")

        {:error, reason} ->
          IO.puts("[Nex.Env] ✗ Failed to load environment: #{inspect(reason)}")
      end
    else
      IO.puts("[Nex.Env] ⚠ No .env files found in: #{project_root}")
    end

    :ok
  end

  @doc "Get environment variable with optional default"
  def get(key, default \\ nil) when is_atom(key) do
    key_str = key |> to_string() |> String.upcase()
    System.get_env(key_str) || default
  end

  @doc "Get required environment variable (raises if missing)"
  def get!(key) when is_atom(key) do
    case get(key) do
      nil -> raise "Missing required environment variable: #{key}"
      value -> value
    end
  end

  @doc "Get environment variable as integer"
  def get_integer(key, default) when is_atom(key) do
    case get(key) do
      nil -> default
      value -> String.to_integer(value)
    end
  end

  @doc "Get environment variable as boolean"
  def get_boolean(key, default) when is_atom(key) do
    case get(key) do
      nil -> default
      "true" -> true
      "1" -> true
      _ -> false
    end
  end
end
