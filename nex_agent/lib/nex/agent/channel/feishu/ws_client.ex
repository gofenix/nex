defmodule Nex.Agent.Channel.Feishu.WSClient do
  @moduledoc """
  Feishu WebSocket client using pbbp2 binary Protobuf protocol.

  All frames are binary-encoded Protobuf (not JSON text).
  method=0 → control (ping/pong), method=1 → data (events).
  """

  use WebSockex

  require Logger

  alias Nex.Agent.Channel.Feishu.Frame

  @spec start_link(String.t(), list(), pid()) :: {:ok, pid()} | {:error, term()}
  def start_link(url, headers, parent_pid) do
    service_id = parse_service_id(url)
    state = %{parent: parent_pid, service_id: service_id}
    WebSockex.start_link(url, __MODULE__, state, extra_headers: headers)
  end

  defp parse_service_id(url) do
    uri = URI.parse(url)
    params = URI.decode_query(uri.query || "")
    case Integer.parse(Map.get(params, "service_id", "0")) do
      {n, _} -> n
      _ -> 0
    end
  end

  @doc "Send a protobuf-encoded frame to the WS server."
  @spec send_frame(pid(), Frame.t()) :: :ok
  def send_frame(pid, %Frame{} = frame) when is_pid(pid) do
    WebSockex.cast(pid, {:send_frame, frame})
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("[Feishu] WebSocket connected, service_id=#{state.service_id}")
    send(state.parent, {:feishu_ws_connected, self()})
    WebSockex.cast(self(), :send_initial_ping)
    {:ok, state}
  end

  defp build_ping(service_id) do
    %Frame{
      seq_id: 0,
      log_id: 0,
      service: service_id,
      method: Frame.method_control(),
      headers: [{"type", "ping"}],
      payload: <<>>
    }
  end

  @impl true
  def handle_disconnect(%{reason: reason}, state) do
    send(state.parent, {:feishu_ws_disconnected, self(), reason})
    {:ok, state}
  end

  @impl true
  def handle_frame({:binary, data}, state) when is_binary(data) do
    Logger.debug("[Feishu] Binary frame #{byte_size(data)} bytes")

    case Frame.decode(data) do
      {:ok, frame} ->
        state = handle_decoded_frame(frame, state)
        {:ok, state}

      {:error, reason} ->
        Logger.warning("[Feishu] Failed to decode frame: #{inspect(reason)}")
        {:ok, state}
    end
  end

  @impl true
  def handle_frame({:text, data}, state) when is_binary(data) do
    Logger.debug("[Feishu] Text frame (unexpected): #{data}")
    {:ok, state}
  end

  @impl true
  def handle_frame({:ping, payload}, state) do
    {:reply, {:pong, payload}, state}
  end

  @impl true
  def handle_cast(:send_initial_ping, state) do
    ping = build_ping(state.service_id)
    binary = Frame.encode(ping)
    Logger.info("[Feishu] Sending initial ping service_id=#{state.service_id}")
    {:reply, {:binary, binary}, state}
  end

  @impl true
  def handle_cast({:send_frame, frame}, state) do
    binary = Frame.encode(frame)
    {:reply, {:binary, binary}, state}
  end

  @impl true
  def terminate(reason, _state) do
    Logger.warning("[Feishu] WS client terminated: #{inspect(reason)}")
    :ok
  end

  # ─── Frame Dispatch ───────────────────────────────────────────────────────

  defp handle_decoded_frame(%Frame{method: 0} = frame, state) do
    handle_control_frame(frame, state)
  end

  defp handle_decoded_frame(%Frame{method: 1} = frame, state) do
    handle_data_frame(frame, state)
  end

  defp handle_decoded_frame(frame, state) do
    Logger.debug("[Feishu] Unknown method=#{frame.method}")
    state
  end

  # ─── Control (ping/pong) ──────────────────────────────────────────────────

  defp handle_control_frame(frame, state) do
    type = Frame.get_header(frame, "type")
    Logger.debug("[Feishu] Control frame type=#{inspect(type)}")

    case type do
      "ping" ->
        pong = %Frame{
          seq_id: frame.seq_id,
          log_id: frame.log_id,
          service: frame.service,
          method: 0,
          headers: [{"type", "pong"}],
          payload: <<>>
        }

        send(self(), {:send_ws_frame, pong})
        state

      "pong" ->
        if byte_size(frame.payload) > 0 do
          case Jason.decode(frame.payload) do
            {:ok, cfg} ->
              ping_interval = Map.get(cfg, "PingInterval")
              send(state.parent, {:feishu_ws_pong_config, ping_interval})

            _ ->
              :ok
          end
        end

        state

      _ ->
        state
    end
  end

  # ─── Data (events) ────────────────────────────────────────────────────────

  defp handle_data_frame(frame, state) do
    headers = Map.new(frame.headers)
    type = Map.get(headers, "type")
    message_id = Map.get(headers, "message_id")

    Logger.debug("[Feishu] Data frame type=#{inspect(type)} message_id=#{inspect(message_id)}")

    if type == "event" do
      event_json = frame.payload

      send(state.parent, {:feishu_ws_event, self(), frame, event_json})
    end

    state
  end
end
