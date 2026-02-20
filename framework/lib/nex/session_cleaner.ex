defmodule Nex.SessionCleaner do
  @moduledoc """
  Background worker that periodically cleans up expired session entries from ETS.
  Runs every 10 minutes. Completely transparent to users.
  """

  use GenServer
  require Logger

  @cleanup_interval :timer.minutes(10)
  @table :nex_session_store

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired()
    schedule_cleanup()
    {:noreply, state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end

  defp cleanup_expired do
    case :ets.whereis(@table) do
      :undefined ->
        :ok

      _ ->
        now = System.system_time(:millisecond)

        expired =
          :ets.foldl(
            fn
              {key, _value, expires_at}, acc when expires_at < now -> [key | acc]
              _, acc -> acc
            end,
            [],
            @table
          )

        Enum.each(expired, &:ets.delete(@table, &1))

        if length(expired) > 0 do
          Logger.debug("[Nex.Session] Cleaned up #{length(expired)} expired session entries")
        end
    end
  end
end
