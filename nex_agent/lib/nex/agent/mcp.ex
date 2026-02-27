defmodule Nex.Agent.MCP do
  @moduledoc """
  MCP Client for connecting to Model Context Protocol servers.

  ## Usage

      # Start a connection
      {:ok, conn} = Nex.Agent.MCP.start_link(
        command: "mcp-server-filesystem",
        args: ["/Users/test/data"]
      )
      
      # Initialize
      :ok = Nex.Agent.MCP.initialize(conn)
      
      # List tools
      {:ok, tools} = Nex.Agent.MCP.list_tools(conn)
      
      # Call a tool
      {:ok, result} = Nex.Agent.MCP.call_tool(conn, "read_file", %{path: "/Users/test/data/file.txt"})
      
      # Stop
      Nex.Agent.MCP.stop(conn)
  """

  use GenServer
  require Logger

  @timeout 30_000

  defstruct [
    :port,
    :request_id,
    :pending_requests,
    :tools,
    :initialized
  ]

  # Client API

  @doc """
  Start a new MCP connection.

  ## Options

  * `:command` - Command to start the MCP server (required)
  * `:args` - Arguments for the command (default: [])
  * `:env` - Environment variables (default: %{})

  ## Examples

      {:ok, conn} = Nex.Agent.MCP.start_link(
        command: "mcp-server-filesystem",
        args: ["/Users/test/data"]
      )
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Initialize the MCP connection.
  """
  def initialize(pid, timeout \\ @timeout) do
    GenServer.call(pid, :initialize, timeout)
  end

  @doc """
  List available tools from the MCP server.
  """
  def list_tools(pid, timeout \\ @timeout) do
    GenServer.call(pid, :list_tools, timeout)
  end

  @doc """
  Call a tool on the MCP server.

  ## Parameters

  * `name` - Tool name
  * `arguments` - Tool arguments (map)

  ## Examples

      {:ok, result} = Nex.Agent.MCP.call_tool(conn, "read_file", %{path: "/tmp/test.txt"})
  """
  def call_tool(pid, name, arguments \\ %{}, timeout \\ @timeout) do
    GenServer.call(pid, {:call_tool, name, arguments}, timeout)
  end

  @doc """
  Stop the MCP connection.
  """
  def stop(pid) do
    GenServer.stop(pid, :normal)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    command = Keyword.fetch!(opts, :command)
    args = Keyword.get(opts, :args, [])
    env = Keyword.get(opts, :env, %{})

    # Convert env map to list of {key, value} tuples
    env_list = Enum.map(env, fn {k, v} -> {to_charlist(k), to_charlist(v)} end)

    port =
      Port.open({:spawn_executable, to_charlist(command)}, [
        :binary,
        :eof,
        :stderr_to_stdout,
        args: Enum.map(args, &to_charlist/1),
        env: env_list
      ])

    state = %__MODULE__{
      port: port,
      request_id: 0,
      pending_requests: %{},
      tools: [],
      initialized: false
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:initialize, from, state) do
    request = %{
      jsonrpc: "2.0",
      id: state.request_id + 1,
      method: "initialize",
      params: %{
        protocolVersion: "2024-11-05",
        capabilities: %{},
        clientInfo: %{
          name: "nex-agent",
          version: "1.0.0"
        }
      }
    }

    send_request(state, request, from)
  end

  @impl true
  def handle_call(:list_tools, from, state) do
    if not state.initialized do
      {:reply, {:error, :not_initialized}, state}
    else
      request = %{
        jsonrpc: "2.0",
        id: state.request_id + 1,
        method: "tools/list",
        params: %{}
      }

      send_request(state, request, from)
    end
  end

  @impl true
  def handle_call({:call_tool, name, arguments}, from, state) do
    if not state.initialized do
      {:reply, {:error, :not_initialized}, state}
    else
      request = %{
        jsonrpc: "2.0",
        id: state.request_id + 1,
        method: "tools/call",
        params: %{
          name: name,
          arguments: arguments
        }
      }

      send_request(state, request, from)
    end
  end

  @impl true
  def handle_info({port, {:data, data}}, %{port: port} = state) do
    # Parse JSON-RPC response
    case Jason.decode(data) do
      {:ok, response} ->
        handle_response(response, state)

      {:error, reason} ->
        Logger.warning("Failed to parse MCP response: #{inspect(reason)} - Data: #{data}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({port, :eof}, %{port: port} = state) do
    Logger.info("MCP server closed connection")
    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state.port do
      Port.close(state.port)
    end

    :ok
  end

  # Private functions

  defp send_request(state, request, from) do
    request_id = state.request_id + 1
    request = %{request | id: request_id}

    json = Jason.encode!(request) <> "\n"
    Port.command(state.port, json)

    new_state = %{
      state
      | request_id: request_id,
        pending_requests: Map.put(state.pending_requests, request_id, from)
    }

    {:noreply, new_state}
  end

  defp handle_response(%{"id" => id, "result" => result}, state) do
    case Map.pop(state.pending_requests, id) do
      {nil, _} ->
        {:noreply, state}

      {from, pending} ->
        # Check if this is initialize response
        new_state =
          if id == 1 do
            tools = result["tools"] || []
            %{state | initialized: true, tools: tools, pending_requests: pending}
          else
            %{state | pending_requests: pending}
          end

        GenServer.reply(from, {:ok, result})
        {:noreply, new_state}
    end
  end

  defp handle_response(%{"id" => id, "error" => error}, state) do
    case Map.pop(state.pending_requests, id) do
      {nil, _} ->
        {:noreply, state}

      {from, pending} ->
        GenServer.reply(from, {:error, error})
        {:noreply, %{state | pending_requests: pending}}
    end
  end

  defp handle_response(_response, state) do
    # Ignore notifications (no id)
    {:noreply, state}
  end
end
