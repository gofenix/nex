defmodule Nex.Env do
  @moduledoc """
  Environment variable management.

  Loads from .env files and system environment.
  """

  require Logger

  @doc """
  Initialize environment from .env files.
  
  Options:
    - :env - Override the environment name (default: auto-detected)
    - :project_root - Override the project root path (default: auto-detected)
  """
  def init(opts \\ []) do
    env = opts[:env] || current_env()
    project_root = opts[:project_root] || detect_project_root()

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

  @doc """
  Returns the current environment name as a string.
  Uses Mix.env() when available (dev/test), falls back to MIX_ENV env var,
  then defaults to "prod" — safe for compiled releases.
  
  Can be overridden for testing with :mix_env and :system_env options.
  """
  def current_env(opts \\ []) do
    mix_env = if Keyword.has_key?(opts, :mix_env), do: opts[:mix_env], else: detect_mix_env()
    system_env = opts[:system_env] || &System.get_env/1
    
    if mix_env do
      mix_env |> to_string()
    else
      system_env.("MIX_ENV") || "prod"
    end
  end

  # Helper to detect if Mix is available and get Mix.env()
  defp detect_mix_env do
    if function_exported?(Mix, :env, 0) do
      Mix.env()
    else
      nil
    end
  end

  @doc """
  Detects project root directory.
  In dev/test (Mix available): walks up from _build app path.
  In prod release (no Mix): uses the directory of the running executable or cwd.
  
  Can be overridden for testing with :mix_project_path and :progname options.
  """
  def detect_project_root(opts \\ []) do
    mix_project_path = if Keyword.has_key?(opts, :mix_project_path), do: opts[:mix_project_path], else: detect_mix_project_path()
    progname = if Keyword.has_key?(opts, :progname), do: opts[:progname], else: detect_progname()
    
    cond do
      mix_project_path ->
        mix_project_path
        |> Path.dirname()
        |> Path.dirname()
        |> Path.dirname()
        |> Path.dirname()

      progname ->
        progname |> to_string() |> Path.expand() |> Path.dirname()

      true ->
        File.cwd!()
    end
  end

  # Helper to detect Mix.Project.app_path()
  defp detect_mix_project_path do
    if function_exported?(Mix.Project, :app_path, 0) do
      case Mix.Project.app_path() do
        nil -> nil
        app_path -> app_path
      end
    else
      nil
    end
  end

  # Helper to detect the program name from :init
  defp detect_progname do
    case :init.get_argument(:progname) do
      {:ok, [[progname]]} -> progname
      _ -> nil
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
