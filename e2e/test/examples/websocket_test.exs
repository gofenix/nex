defmodule E2E.WebsocketTest do
  use E2E.ExampleCase, example: "websocket"

  test "connects and exchanges chat messages over WebSocket", %{
    client: client,
    example_config: example
  } do
    {home, _jar} = HTTP.get(client, "/")
    assert_has_test_id(home.body, "websocket-page")

    username = "exunit-#{System.unique_integer([:positive])}"
    message = "Hello from ExUnit"
    url = Example.websocket_url(example, "/ws/chat?username=#{username}&room=tech")

    {:ok, socket} = WebSocketClient.start_link(url, self())
    assert_receive {:ws_connected, ^socket}, 5_000

    assert_receive {:ws_text, joined_payload}, 5_000
    joined = Jason.decode!(joined_payload)
    assert joined["user"] == "System"
    assert joined["text"] =~ "#{username} joined tech"

    :ok = WebSocketClient.send_text(socket, message)

    assert_receive {:ws_text, message_payload}, 5_000
    delivered = Jason.decode!(message_payload)
    assert delivered["user"] == username
    assert delivered["text"] == message

    :ok = WebSocketClient.close(socket)
  end
end
