defmodule E2E.RatelimitTest do
  use E2E.ExampleCase, example: "ratelimit"

  test "returns rate-limit headers and rejects burst traffic", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_has_test_id(home.body, "ratelimit-page")

    responses =
      Enum.map(1..6, fn _ ->
        {response, _jar} = HTTP.get(client, "/api/status")
        response
      end)

    limited = Enum.find(responses, &(&1.status == 429))
    refute is_nil(limited)
    assert HTTP.header(limited, "x-ratelimit-limit") == "5"
    assert HTTP.header(limited, "x-ratelimit-remaining") == "0"

    payload = HTTP.json_body(limited)
    assert payload["error"] == "Too Many Requests"
    assert payload["retry_after"] == 60
  end
end
