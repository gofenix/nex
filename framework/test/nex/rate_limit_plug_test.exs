defmodule Nex.RateLimit.PlugTest do
  use ExUnit.Case, async: true
  import Plug.Conn

  setup do
    # Reset rate limit table
    Nex.RateLimit.ensure_table()
    :ok
  end

  describe "Nex.RateLimit.Plug" do
    test "init returns opts" do
      opts = [max: 10, window: 60]
      assert Nex.RateLimit.Plug.init(opts) == opts
    end

    test "call allows request when under limit" do
      # Create a mock conn with remote_ip
      conn = %Plug.Conn{
        remote_ip: {127, 0, 0, 1},
        req_headers: [],
        cookies: %{},
        params: %{},
        path_info: [],
        method: "GET"
      }

      opts = [max: 100, window: 60]
      result = Nex.RateLimit.Plug.call(conn, opts)

      # Should not be halted
      assert result.halted == false
      assert get_resp_header(result, "x-ratelimit-limit") == ["100"]
    end
  end
end
