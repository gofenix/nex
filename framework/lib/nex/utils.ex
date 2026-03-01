defmodule Nex.Utils do
  @moduledoc """
  Shared utility functions used across the Nex framework.

  This module contains common functions that are used by multiple
  modules to avoid code duplication.
  """

  @doc """
  Safely converts a string to an existing atom.

  Returns `{:ok, atom}` if the atom exists, or `:error` if it doesn't.
  This prevents atom exhaustion attacks by only converting atoms that
  have already been defined.

  ## Examples

      iex> Nex.Utils.safe_to_existing_atom("Phoenix")
      {:ok, Phoenix}

      iex> Nex.Utils.safe_to_existing_atom("NonExistentModule")
      :error
  """
  @spec safe_to_existing_atom(String.t()) :: {:ok, atom()} | :error
  def safe_to_existing_atom(string) do
    {:ok, String.to_existing_atom(string)}
  rescue
    ArgumentError -> :error
  end

  @doc """
  Safely converts a module name string to an existing module.

  Returns `{:ok, module}` if the module is loaded, or `:error` if not.

  ## Examples

      iex> Nex.Utils.safe_to_existing_module("Nex.Handler")
      {:ok, Nex.Handler}

      iex> Nex.Utils.safe_to_existing_module("Non.Existent")
      :error
  """
  @spec safe_to_existing_module(String.t()) :: {:ok, module()} | :error
  def safe_to_existing_module(module_name) do
    case safe_to_existing_atom("Elixir.#{module_name}") do
      {:ok, module} ->
        if Code.ensure_loaded?(module), do: {:ok, module}, else: :error

      :error ->
        :error
    end
  end

  @doc """
  Generates a cryptographically secure random token.

  ## Examples

      iex> Nex.Utils.generate_token()
      "abc123..."
  """
  @spec generate_token(pos_integer()) :: String.t()
  def generate_token(length \\ 24) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Generates a cryptographically secure random hex string.

  ## Examples

      iex> Nex.Utils.generate_hex(16)
      "abc123..."
  """
  @spec generate_hex(pos_integer()) :: String.t()
  def generate_hex(length) do
    :crypto.strong_rand_bytes(length) |> Base.encode16(case: :lower)
  end
end
