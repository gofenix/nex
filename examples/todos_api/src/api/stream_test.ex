defmodule TodosApi.Api.StreamTest do
  use Nex

  @moduledoc """
  Simple SSE streaming test endpoint.

  Test with:
    curl http://localhost:4000/api/stream_test
  """

  def get(_req) do
    # Test 1: Simple callback function
    Nex.stream(fn send ->
      send.("Message 1")
      Process.sleep(500)
      send.("Message 2")
      Process.sleep(500)
      send.("Message 3")
    end)
  end

  def post(req) do
    count = req.body["count"] || 5

    # Test 2: Dynamic streaming with parameter
    Nex.stream(fn send ->
      Enum.each(1..count, fn i ->
        send.("Item #{i}")
        Process.sleep(200)
      end)
      send.(%{event: "done", data: "Complete!"})
    end)
  end
end
