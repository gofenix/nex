defmodule Nex.Agent.Channel.HTTP do
  @moduledoc """
  HTTP Webhook Channel - Receive messages via HTTP POST webhook
  """

  use GenServer
  alias Nex.Agent.Bus

  defstruct [:port, :enabled]

  @type t :: %__MODULE__{
          port: integer(),
          enabled: boolean()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    port = Keyword.get(opts, :port, 8080)
    enabled = Keyword.get(opts, :enabled, true)

    state = %__MODULE__{
      port: port,
      enabled: enabled
    }

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @doc """
  Start the HTTP server (using Plug)
  """
  @spec start_server(integer()) :: :ok
  def start_server(port) do
    GenServer.call(__MODULE__, {:start_server, port})
  end

  @doc """
  Stop the HTTP server
  """
  @spec stop_server :: :ok
  def stop_server do
    GenServer.call(__MODULE__, :stop_server)
  end

  @doc """
  Send a message to the channel
  """
  @spec send_message(String.t(), String.t()) :: :ok
  def send_message(chat_id, content) do
    Bus.publish(:http_outbound, %{
      chat_id: chat_id,
      content: content
    })
  end

  # GenServer callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:start_server, port}, _from, state) do
    # In a real implementation, this would start a Plug/Cowboy server
    # For now, we just acknowledge the request
    IO.puts("HTTP Channel would start on port #{port}")
    {:reply, :ok, %{state | port: port}}
  end

  @impl true
  def handle_call(:stop_server, _from, state) do
    IO.puts("HTTP Channel stopping")
    {:reply, :ok, %{state | enabled: false}}
  end

  @doc """
  Handle incoming HTTP request (to be called by Plug)
  """
  def handle_incoming(conn, body) do
    case Jason.decode(body) do
      {:ok, %{"message" => message, "chat_id" => chat_id}} ->
        Bus.publish(:inbound, %{
          channel: "http",
          chat_id: chat_id,
          content: message
        })

        {:ok, %{status: "message received"}}

      _ ->
        {:error, %{status: "invalid request"}}
    end
  end
end
