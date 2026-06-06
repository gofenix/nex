defmodule Nex.CoreTest do
  use ExUnit.Case, async: true

  alias Nex.Response

  describe "json/2" do
    test "builds a JSON response with default status" do
      resp = Nex.json(%{ok: true})

      assert %Response{} = resp
      assert resp.status == 200
      assert resp.body == %{ok: true}
      assert resp.content_type == "application/json"
    end

    test "accepts custom status and headers" do
      resp = Nex.json([1, 2, 3], status: 201, headers: %{"x-custom" => "v"})

      assert resp.status == 201
      assert resp.headers == %{"x-custom" => "v"}
      assert resp.body == [1, 2, 3]
    end
  end

  describe "text/2" do
    test "builds a plain text response" do
      resp = Nex.text("hello")

      assert resp.status == 200
      assert resp.body == "hello"
      assert resp.content_type == "text/plain"
    end

    test "accepts custom status" do
      resp = Nex.text("bad", status: 400)
      assert resp.status == 400
    end
  end

  describe "html/2" do
    test "builds an HTML response" do
      resp = Nex.html("<h1>hi</h1>")

      assert resp.status == 200
      assert resp.body == "<h1>hi</h1>"
      assert resp.content_type == "text/html"
    end

    test "accepts custom status and headers" do
      resp = Nex.html("<p>oops</p>", status: 404, headers: %{"x-page" => "404"})

      assert resp.status == 404
      assert resp.headers == %{"x-page" => "404"}
    end
  end

  describe "redirect/2" do
    test "builds a 302 redirect by default" do
      resp = Nex.redirect("/login")

      assert resp.status == 302
      assert resp.headers == %{"location" => "/login"}
      assert resp.content_type == "text/html"
    end

    test "accepts custom status" do
      resp = Nex.redirect("/new", status: 301)
      assert resp.status == 301
    end
  end

  describe "status/2" do
    test "builds a plain text response with status code" do
      resp = Nex.status(204, "no content")

      assert resp.status == 204
      assert resp.body == "no content"
      assert resp.content_type == "text/plain"
    end

    test "body defaults to empty string" do
      resp = Nex.status(418)
      assert resp.status == 418
      assert resp.body == ""
    end
  end

  describe "stream/1" do
    test "builds an SSE streaming response" do
      callback = fn _send -> :done end
      resp = Nex.stream(callback)

      assert resp.status == 200
      assert resp.content_type == "text/event-stream"
      assert is_function(resp.body, 1)
      assert resp.headers["cache-control"] == "no-cache, no-transform"
      assert resp.headers["connection"] == "keep-alive"
    end
  end

  describe "__using__/1 macro" do
    test "imports HEEx + helpers for Pages modules" do
      defmodule __MODULE__.Pages.Example do
        use Nex

        def render(_assigns) do
          # sigil_H should be imported
          assigns = %{name: "world"}
          ~H"<span>Hello <%= @name %></span>"
        end
      end

      output = apply(__MODULE__.Pages.Example, :render, [%{}])
      assert is_struct(output, Phoenix.LiveView.Rendered)
    end

    test "imports HEEx + helpers for Components modules" do
      defmodule __MODULE__.Components.Card do
        use Nex

        def render(assigns) do
          assigns = Map.put_new(assigns, :text, "ok")
          ~H"<div><%= @text %></div>"
        end
      end

      assert apply(__MODULE__.Components.Card, :render, [%{}])
    end

    test "imports HEEx + helpers for Layouts module" do
      defmodule __MODULE__.MyLayouts do
        use Nex

        def render(assigns) do
          assigns = Map.put_new(assigns, :inner_content, "")
          ~H"<main><%= @inner_content %></main>"
        end
      end

      assert apply(__MODULE__.MyLayouts, :render, [%{}])
    end

    test "API modules do not import unnecessary helpers" do
      defmodule __MODULE__.Api.Users do
        use Nex

        def get(_req) do
          Nex.json(%{users: []})
        end
      end

      assert apply(__MODULE__.Api.Users, :get, [%{}]).content_type == "application/json"
    end

    test "default (non-matching) module imports page helpers" do
      defmodule __MODULE__.RandomModule do
        use Nex

        def render(assigns) do
          assigns = Map.put_new(assigns, :n, 1)
          ~H"<p>count: <%= @n %></p>"
        end
      end

      assert apply(__MODULE__.RandomModule, :render, [%{}])
    end
  end
end
