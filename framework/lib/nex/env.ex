defmodule Nex.Env do
  @moduledoc """
  Environment variable management.

  This module delegates to NexEnv for core functionality.
  """

  defdelegate init, to: NexEnv
  defdelegate get(key, default \\ nil), to: NexEnv
  defdelegate get!(key), to: NexEnv
  defdelegate get_integer(key, default), to: NexEnv
  defdelegate get_boolean(key, default), to: NexEnv
end
