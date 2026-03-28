defmodule AgentConsole.SessionTracker.Agent do
  defstruct [:session_key, :session, :provider, :model, :api_key, :cwd, :max_iterations]
end

defmodule AgentConsole.SessionTracker do
  @moduledoc """
  Manages Agent instances for each WebSocket connection.
  """
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @doc """
  Create or get agent for a session.
  """
  def get_or_create(session_id) do
    GenServer.call(__MODULE__, {:get_or_create, session_id})
  end

  @doc """
  Update agent after a prompt completes.
  """
  def update(session_id, agent) do
    GenServer.cast(__MODULE__, {:update, session_id, agent})
  end

  @doc """
  Delete a session.
  """
  def delete(session_id) do
    GenServer.cast(__MODULE__, {:delete, session_id})
  end

  @doc """
  List all sessions.
  """
  def list do
    GenServer.call(__MODULE__, {:list})
  end

  @doc """
  Get agent for session.
  """
  def get(session_id) do
    GenServer.call(__MODULE__, {:get, session_id})
  end

  @impl true
  def handle_call({:get_or_create, session_id}, _from, state) do
    case Map.get(state, session_id) do
      nil ->
        agent = create_agent(session_id)
        {:reply, agent, Map.put(state, session_id, agent)}

      agent ->
        {:reply, agent, state}
    end
  end

  def handle_call({:get, session_id}, _from, state) do
    {:reply, Map.get(state, session_id), state}
  end

  def handle_call({:list}, _from, state) do
    sessions =
      state
      |> Map.keys()
      |> Enum.map(fn id -> %{id: id, key: "console:#{id}"} end)

    {:reply, sessions, state}
  end

  @impl true
  def handle_cast({:update, session_id, agent}, state) do
    {:noreply, Map.put(state, session_id, agent)}
  end

  def handle_cast({:delete, session_id}, state) do
    {:noreply, Map.delete(state, session_id)}
  end

  defp create_agent(session_id) do
    key = "console:#{session_id}"

    case Nex.Agent.SessionManager.get_or_create(key) do
      session ->
        provider =
          case Nex.Env.get(:llm_provider) || "anthropic" do
            "anthropic" -> :anthropic
            "openai" -> :openai
            p -> String.to_atom(p)
          end

        model =
          case provider do
            :anthropic -> Nex.Env.get(:anthropic_model) || "claude-sonnet-4-20250514"
            :openai -> Nex.Env.get(:openai_model) || "gpt-4o"
            _ -> "claude-sonnet-4-20250514"
          end

        api_key =
          case provider do
            :anthropic -> Nex.Env.get(:anthropic_api_key)
            :openai -> Nex.Env.get(:openai_api_key)
            _ -> nil
          end

        %AgentConsole.SessionTracker.Agent{
          session_key: key,
          session: session,
          provider: provider,
          model: model,
          api_key: api_key,
          cwd: File.cwd!(),
          max_iterations: 40
        }
    end
  end
end
