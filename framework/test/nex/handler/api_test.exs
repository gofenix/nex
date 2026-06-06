defmodule Nex.Handler.ApiTest do
  use ExUnit.Case, async: false
  import Plug.Test
  import Plug.Conn

  alias Nex.Handler.Api

  setup do
    original_app = Application.get_env(:nex_core, :app_module)

    on_exit(fn ->
      if original_app do
        Application.put_env(:nex_core, :app_module, original_app)
      else
        Application.delete_env(:nex_core, :app_module)
      end
    end)

    Application.put_env(:nex_core, :app_module, "ApiHandlerTest")
    :ok
  end

  describe "handle/3" do
    test "returns 404 JSON for unknown API route" do
      conn = conn(:get, "/api/nonexistent")
      result = Api.handle(conn, :get, ["api", "nonexistent"])

      assert result.status == 404
      assert Jason.decode!(result.resp_body) == %{"error" => "Not Found"}
      assert hd(get_resp_header(result, "content-type")) =~ "application/json"
    end

    test "strips leading \"api\" segment before resolving" do
      conn = conn(:get, "/missing")
      result = Api.handle(conn, :get, ["missing"])
      assert result.status == 404
      assert Jason.decode!(result.resp_body) == %{"error" => "Not Found"}
    end
  end
end
