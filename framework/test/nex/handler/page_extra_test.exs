defmodule Nex.Handler.PageExtraTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Nex.Handler.Page

  describe "page_id_from_request/1" do
    test "returns X-Nex-Page-Id header when present" do
      conn = conn(:get, "/") |> put_req_header("x-nex-page-id", "custom-page-123")
      assert Page.page_id_from_request(conn) == "custom-page-123"
    end

    test "generates a page ID when header is missing" do
      conn = conn(:get, "/")
      page_id = Page.page_id_from_request(conn)
      assert is_binary(page_id)
      assert byte_size(page_id) > 0
    end

    test "generated page IDs are unique" do
      id1 = Page.page_id_from_request(conn(:get, "/"))
      id2 = Page.page_id_from_request(conn(:get, "/"))
      assert id1 != id2
    end
  end

  describe "page handle/3 for unsupported methods" do
    test "returns 405 for OPTIONS method" do
      conn = conn(:options, "/some-page")
      result = Page.handle(conn, :options, ["some-page"])
      assert result.status == 405
    end
  end
end
