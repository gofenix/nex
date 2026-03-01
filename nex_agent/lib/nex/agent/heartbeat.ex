defmodule Nex.Agent.Heartbeat do
  @moduledoc """
  Heartbeat Service - Periodic agent wake-up to check for tasks

  Phase 1 (decision): reads HEARTBEAT.md and asks the LLM whether there are active tasks.
  Phase 2 (execution): only triggered when Phase 1 returns "run".
  """

  use GenServer

  # 30 minutes
  @default_interval 30 * 60

  defstruct [:interval, :enabled, :workspace, :on_execute, :on_notify, :running]

  @type t :: %__MODULE__{
          interval: integer(),
          enabled: boolean(),
          workspace: String.t(),
          on_execute: fun() | nil,
          on_notify: fun() | nil,
          running: boolean()
        }

  @doc """
  Start the heartbeat service
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    interval = Keyword.get(opts, :interval, @default_interval)
    enabled = Keyword.get(opts, :enabled, true)

    workspace =
      Keyword.get(
        opts,
        :workspace,
        Path.join(System.get_env("HOME", "~"), ".nex/agent/workspace")
      )

    state = %__MODULE__{
      interval: interval,
      enabled: enabled,
      workspace: workspace,
      on_execute: nil,
      on_notify: nil,
      running: false
    }

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @doc """
  Set the execute callback
  """
  @spec on_execute(fun()) :: :ok
  def on_execute(callback) do
    GenServer.call(__MODULE__, {:set_callback, :execute, callback})
  end

  @doc """
  Set the notify callback
  """
  @spec on_notify(fun()) :: :ok
  def on_notify(callback) do
    GenServer.call(__MODULE__, {:set_callback, :notify, callback})
  end

  @doc """
  Start the heartbeat loop
  """
  @spec start :: :ok
  def start do
    GenServer.call(__MODULE__, :start)
  end

  @doc """
  Stop the heartbeat loop
  """
  @spec stop :: :ok
  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  @doc """
  Get heartbeat status
  """
  @spec status :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # GenServer callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:start, _from, %{enabled: false} = state) do
    {:reply, {:error, :disabled}, state}
  end

  @impl true
  def handle_call(:start, _from, state) do
    schedule_tick()
    {:reply, :ok, %{state | running: true}}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:reply, :ok, %{state | running: false}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    status = %{
      enabled: state.enabled,
      running: state.running,
      interval: state.interval,
      workspace: state.workspace
    }

    {:reply, status, state}
  end

  @impl true
  def handle_call({:set_callback, type, callback}, _from, state) do
    new_state =
      case type do
        :execute -> %{state | on_execute: callback}
        :notify -> %{state | on_notify: callback}
      end

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info(:tick, %{running: false} = state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    execute_heartbeat(state)
    schedule_tick()
    {:noreply, state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @default_interval * 1000)
  end

  defp execute_heartbeat(state) do
    heartbeat_file = Path.join(state.workspace, "HEARTBEAT.md")

    unless File.exists?(heartbeat_file) do
      :skip
    end
  end
end
