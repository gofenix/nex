defmodule Nex.Agent.Subagent do
  @moduledoc """
  Subagent - Background task execution

  Allows spawning background tasks that run independently and notify when complete.
  """

  use GenServer
  alias Nex.Agent.Bus

  defstruct [:tasks, :bus]

  @type t :: %__MODULE__{
          tasks: map(),
          bus: pid() | nil
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %__MODULE__{tasks: %{}, bus: nil}, name: name)
  end

  @doc """
  Spawn a background task
  """
  @spec spawn_task(String.t(), keyword()) :: {:ok, String.t()}
  def spawn_task(task_description, opts \\ []) do
    GenServer.call(__MODULE__, {:spawn, task_description, opts})
  end

  @doc """
  List running background tasks
  """
  @spec list :: list(map())
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @doc """
  Get task status
  """
  @spec status(String.t()) :: map() | nil
  def status(task_id) do
    GenServer.call(__MODULE__, {:status, task_id})
  end

  @doc """
  Cancel a running task
  """
  @spec cancel(String.t()) :: :ok | {:error, :not_found}
  def cancel(task_id) do
    GenServer.call(__MODULE__, {:cancel, task_id})
  end

  # GenServer callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:spawn, task_description, opts}, _from, state) do
    task_id = generate_id()
    label = opts[:label] || String.slice(task_description, 0, 30)

    task = %{
      id: task_id,
      label: label,
      description: task_description,
      status: :running,
      started_at: System.system_time(:second),
      result: nil
    }

    run_task(task, opts)

    new_tasks = Map.put(state.tasks, task_id, task)
    {:reply, {:ok, task_id}, %{state | tasks: new_tasks}}
  end

  @impl true
  def handle_call(:list, _from, state) do
    tasks = Map.values(state.tasks)
    {:reply, tasks, state}
  end

  @impl true
  def handle_call({:status, task_id}, _from, state) do
    task = Map.get(state.tasks, task_id)
    {:reply, task, state}
  end

  @impl true
  def handle_call({:cancel, task_id}, _from, state) do
    case Map.get(state.tasks, task_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      task ->
        # Cancel the task process if running
        if task[:pid] do
          Process.exit(task[:pid], :kill)
        end

        updated_task = %{task | status: :cancelled}
        new_tasks = Map.put(state.tasks, task_id, updated_task)
        {:reply, :ok, new_tasks}
    end
  end

  @impl true
  def handle_info({:task_complete, task_id, result}, state) do
    task = Map.get(state.tasks, task_id)

    if task do
      updated_task = %{
        task
        | status: :completed,
          result: result,
          completed_at: System.system_time(:second)
      }

      # Notify via Bus
      Bus.publish(:subagent, %{
        type: :task_complete,
        task_id: task_id,
        result: result
      })

      new_tasks = Map.put(state.tasks, task_id, updated_task)
      {:noreply, new_tasks}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:task_failed, task_id, reason}, state) do
    task = Map.get(state.tasks, task_id)

    if task do
      updated_task = %{
        task
        | status: :failed,
          error: reason,
          completed_at: System.system_time(:second)
      }

      Bus.publish(:subagent, %{
        type: :task_failed,
        task_id: task_id,
        reason: reason
      })

      new_tasks = Map.put(state.tasks, task_id, updated_task)
      {:noreply, new_tasks}
    else
      {:noreply, state}
    end
  end

  defp run_task(task, opts) do
    # In a real implementation, this would spawn an actual task
    # For now, we simulate it
    task_id = task.id

    spawn(fn ->
      # Simulate task execution
      # In real implementation, this would call the agent
      Process.sleep(1000)

      result = "Task completed: #{task.description}"

      send(self(), {:task_complete, task_id, result})
    end)
  end

  defp generate_id do
    :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
  end
end
