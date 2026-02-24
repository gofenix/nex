defmodule Nex.Env do
  require Logger

  @doc "Initialize environment from .env files"
  def init do
    env = current_env()
    project_root = detect_project_root()

    files =
      [".env", ".env.#{env}"]
      |> Enum.map(&Path.join(project_root, &1))
      |> Enum.filter(&File.exists?/1)

    if files != [] do
      Logger.info("[Nex.Env] Loading environment from: #{Enum.join(files, ", ")}")

      case Dotenvy.source(files) do
        {:ok, vars} ->
          Enum.each(vars, fn {key, value} ->
            System.put_env(key, value)
          end)

          Logger.info("[Nex.Env] Environment loaded (#{map_size(vars)} variables)")

        {:error, reason} ->
          Logger.warning("[Nex.Env] Failed to load environment: #{inspect(reason)}")
      end
    else
      Logger.debug("[Nex.Env] No .env files found in: #{project_root}")
    end

    :ok
  end

  defp current_env do
    if function_exported?(Mix, :env, 0) do
      Mix.env() |> to_string()
    else
      System.get_env("MIX_ENV", "prod")
    end
  end

  defp detect_project_root do
    cond do
      function_exported?(Mix.Project, :app_path, 0) ->
        case Mix.Project.app_path() do
          nil ->
            File.cwd!()

          app_path ->
            app_path
            |> Path.dirname()
            |> Path.dirname()
            |> Path.dirname()
            |> Path.dirname()
        end

      true ->
        case :init.get_argument(:progname) do
          {:ok, [[progname]]} ->
            progname |> to_string() |> Path.expand() |> Path.dirname()

          _ ->
            File.cwd!()
        end
    end
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
