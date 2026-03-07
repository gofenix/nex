defmodule Nex.Agent.MessageBus do
  @moduledoc """
  Async message queue for decoupled channel-agent communication.

  Separates message queues from waiter queues to prevent deadlock:
  - Messages go into `:queue` FIFOs
  - Blocked consumers wait in separate waiter queues with monitors
  - On publish: if a waiter exists, reply directly; otherwise enqueue
  - On consume: if a message exists, reply directly; otherwise wait
  - Consumer crashes are cleaned up via :DOWN monitors
  """

  use GenServer
  require Logger

  @type inbound_message :: %{
          required(:channel) => String.t(),
          required(:chat_id) => String.t(),
          required(:content) => String.t(),
          optional(:sender_id) => String.t(),
          optional(:media) => [String.t()],
          optional(:metadata) => map()
        }

  @type outbound_message :: %{
          required(:channel) => String.t(),
          required(:chat_id) => String.t(),
          required(:content) => String.t(),
          optional(:metadata) => map()
        }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def init(:ok) do
    {:ok,
     %{
       inbound_queue: :queue.new(),
       inbound_waiters: :queue.new(),
       outbound_queue: :queue.new(),
       outbound_waiters: :queue.new()
     }}
  end

  @doc "Publish inbound message from channel to agent."
  @spec publish_inbound(inbound_message()) :: :ok
  def publish_inbound(msg) do
    GenServer.cast(__MODULE__, {:publish, :inbound, msg})
  end

  @doc "Consume next inbound message (blocks until available)."
  @spec consume_inbound(timeout()) :: inbound_message() | nil
  def consume_inbound(timeout \\ 5000) do
    GenServer.call(__MODULE__, {:consume, :inbound}, timeout)
  end

  @doc "Publish outbound message from agent to channel."
  @spec publish_outbound(outbound_message()) :: :ok
  def publish_outbound(msg) do
    GenServer.cast(__MODULE__, {:publish, :outbound, msg})
  end

  @doc "Consume next outbound message."
  @spec consume_outbound(timeout()) :: outbound_message() | nil
  def consume_outbound(timeout \\ 5000) do
    GenServer.call(__MODULE__, {:consume, :outbound}, timeout)
  end

  # --- Publish: deliver to waiter or enqueue ---

  @impl true
  def handle_cast({:publish, direction, msg}, state) do
    {waiters_key, queue_key} = keys(direction)
    waiters = Map.fetch!(state, waiters_key)

    case dequeue_live_waiter(waiters) do
      {:ok, {from, ref}, remaining_waiters} ->
        Process.demonitor(ref, [:flush])
        GenServer.reply(from, msg)
        {:noreply, Map.put(state, waiters_key, remaining_waiters)}

      :empty ->
        queue = Map.fetch!(state, queue_key)
        {:noreply, Map.put(state, queue_key, :queue.in(msg, queue))}
    end
  end

  # --- Consume: dequeue or wait ---

  @impl true
  def handle_call({:consume, direction}, from, state) do
    {waiters_key, queue_key} = keys(direction)
    queue = Map.fetch!(state, queue_key)

    case :queue.out(queue) do
      {{:value, msg}, rest} ->
        {:reply, msg, Map.put(state, queue_key, rest)}

      {:empty, _} ->
        {caller_pid, _} = from
        ref = Process.monitor(caller_pid)
        waiters = Map.fetch!(state, waiters_key)
        new_waiters = :queue.in({from, ref}, waiters)
        {:noreply, Map.put(state, waiters_key, new_waiters)}
    end
  end

  # --- Clean up crashed consumers ---

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    state =
      state
      |> remove_waiter(:inbound_waiters, ref)
      |> remove_waiter(:outbound_waiters, ref)

    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  # --- Helpers ---

  defp keys(:inbound), do: {:inbound_waiters, :inbound_queue}
  defp keys(:outbound), do: {:outbound_waiters, :outbound_queue}

  # Dequeue the first live waiter, skipping any whose process already died.
  defp dequeue_live_waiter(waiters) do
    case :queue.out(waiters) do
      {{:value, {from, ref} = entry}, rest} ->
        {pid, _} = from

        if Process.alive?(pid) do
          {:ok, entry, rest}
        else
          Process.demonitor(ref, [:flush])
          dequeue_live_waiter(rest)
        end

      {:empty, _} ->
        :empty
    end
  end

  defp remove_waiter(state, waiters_key, ref) do
    waiters = Map.fetch!(state, waiters_key)

    filtered =
      :queue.to_list(waiters)
      |> Enum.reject(fn {_from, r} -> r == ref end)
      |> :queue.from_list()

    Map.put(state, waiters_key, filtered)
  end
end
