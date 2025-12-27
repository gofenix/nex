defmodule Nex.Env do
  @moduledoc """
  Environment variable management.
  
  Loads from .env files and system environment.
  """

  @doc "Initialize environment from .env files"
  def init do
    env = Mix.env() |> to_string()

    files =
      [".env", ".env.#{env}"]
      |> Enum.filter(&File.exists?/1)

    if files != [] do
      Dotenvy.source(files)
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
