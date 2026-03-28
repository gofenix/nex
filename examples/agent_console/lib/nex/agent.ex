defmodule Nex.Agent.Onboarding do
  def ensure_initialized, do: :ok
end

defmodule Nex.Agent.Skills do
  def load, do: :ok
end

defmodule Nex.Agent.Session do
  defstruct [:key, :updated_at, history: []]

  def new(key) when is_binary(key) do
    %__MODULE__{
      key: key,
      updated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    }
  end
end

defmodule Nex.Agent.SessionManager do
  use GenServer

  alias Nex.Agent.Session

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, Keyword.put_new(opts, :name, __MODULE__))
  end

  def get_or_create(key) when is_binary(key) do
    GenServer.call(__MODULE__, {:get_or_create, key})
  end

  def save(%Session{} = session) do
    GenServer.cast(__MODULE__, {:save, session})
  end

  def invalidate(key) when is_binary(key) do
    GenServer.cast(__MODULE__, {:invalidate, key})
  end

  def list do
    GenServer.call(__MODULE__, :list)
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:get_or_create, key}, _from, state) do
    session = Map.get_lazy(state, key, fn -> Session.new(key) end)
    {:reply, session, Map.put(state, key, session)}
  end

  def handle_call(:list, _from, state) do
    sessions =
      state
      |> Map.values()
      |> Enum.sort_by(& &1.updated_at, :desc)

    {:reply, sessions, state}
  end

  @impl true
  def handle_cast({:save, %Session{} = session}, state) do
    {:noreply, Map.put(state, session.key, session)}
  end

  def handle_cast({:invalidate, key}, state) do
    {:noreply, Map.delete(state, key)}
  end
end

defmodule Nex.Agent.Runner do
  alias Nex.Agent.Session

  def run(%Session{} = session, prompt, _opts) do
    if is_binary(prompt) and String.trim(prompt) != "" do
      result = "Echo: #{prompt}"

      updated_session = %Session{
        session
        | history: session.history ++ [%{prompt: prompt, response: result}],
          updated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
      }

      {:ok, result, updated_session}
    else
      {:error, :invalid_prompt, session}
    end
  end
end
