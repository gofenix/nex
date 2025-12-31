defmodule Nex.ReqTest do
  use ExUnit.Case, async: true
  alias Nex.Req

  describe "from_plug_conn/2" do
    test "handles unfetched body_params gracefully" do
      conn = build_conn(
        body_params: %Plug.Conn.Unfetched{aspect: :body_params},
        method: "GET"
      )

      req = Req.from_plug_conn(conn)

      assert req.body == %{}
      assert is_map(req.body)

      # Should be safe to use Map functions
      assert Map.has_key?(req.body, "test") == false
    end

    test "preserves valid body_params" do
      conn = build_conn(
        body_params: %{"name" => "test", "email" => "test@example.com"},
        method: "POST"
      )

      req = Req.from_plug_conn(conn)

      assert req.body == %{"name" => "test", "email" => "test@example.com"}
    end

    test "merges path params and query params in req.query (path takes precedence)" do
      conn = build_conn(
        query_params: %{"id" => "query-id", "page" => "2"}
      )

      path_params = %{"id" => "path-id"}
      req = Req.from_plug_conn(conn, path_params)

      # Path params take precedence over query params
      assert req.query["id"] == "path-id"
      assert req.query["page"] == "2"
    end

    test "req.body is independent from req.query" do
      conn = build_conn(
        query_params: %{"id" => "query-id"},
        body_params: %{"id" => "body-id", "name" => "test"}
      )

      path_params = %{"id" => "path-id"}
      req = Req.from_plug_conn(conn, path_params)

      # req.query contains path + query (path wins)
      assert req.query["id"] == "path-id"

      # req.body is completely independent
      assert req.body["id"] == "body-id"
      assert req.body["name"] == "test"
    end

    test "converts headers list to map" do
      conn = build_conn(
        req_headers: [
          {"content-type", "application/json"},
          {"authorization", "Bearer token"}
        ]
      )

      req = Req.from_plug_conn(conn)

      assert req.headers == %{
        "content-type" => "application/json",
        "authorization" => "Bearer token"
      }
    end

    test "includes all Next.js standard fields" do
      conn = build_conn(
        query_params: %{"page" => "1"},
        body_params: %{"name" => "test"},
        req_headers: [{"accept", "application/json"}],
        cookies: %{"session" => "abc123"},
        method: "POST",
        request_path: "/api/users"
      )

      req = Req.from_plug_conn(conn)

      # Next.js standard fields
      assert is_map(req.query)
      assert is_map(req.body)
      assert is_map(req.headers)
      assert is_map(req.cookies)
      assert req.method == "POST"

      # Framework internals
      assert req.path == "/api/users"
    end

    test "does not expose non-standard fields" do
      conn = build_conn(
        query_params: %{"page" => "1"},
        body_params: %{"name" => "test"}
      )

      path_params = %{"id" => "123"}
      req = Req.from_plug_conn(conn, path_params)

      # Should NOT have these fields (not in Next.js)
      refute Map.has_key?(req, :params)
      refute Map.has_key?(req, :path_params)
      refute Map.has_key?(req, :query_params)
      refute Map.has_key?(req, :body_params)
    end
  end

  defp build_conn(opts) do
    %Plug.Conn{
      body_params: Keyword.get(opts, :body_params, %{}),
      query_params: Keyword.get(opts, :query_params, %{}),
      params: Keyword.get(opts, :params, %{}),
      req_headers: Keyword.get(opts, :req_headers, []),
      cookies: Keyword.get(opts, :cookies, %{}),
      method: Keyword.get(opts, :method, "GET"),
      request_path: Keyword.get(opts, :request_path, "/test"),
      private: Keyword.get(opts, :private, %{})
    }
    |> Plug.Conn.fetch_query_params()
    |> Plug.Conn.fetch_cookies()
  end
end
