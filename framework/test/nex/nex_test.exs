defmodule NexTest do
  use ExUnit.Case, async: true

  describe "json/2" do
    test "creates JSON response with default status" do
      result = Nex.json(%{key: "value"})

      assert result.status == 200
      assert result.body == %{key: "value"}
      assert result.content_type == "application/json"
    end

    test "creates JSON response with custom status" do
      result = Nex.json(%{error: "not found"}, status: 404)

      assert result.status == 404
      assert result.body == %{error: "not found"}
    end

    test "creates JSON response with headers" do
      result = Nex.json(%{data: []}, headers: %{"X-Custom" => "value"})

      assert result.headers["X-Custom"] == "value"
    end

    test "accepts list as data" do
      result = Nex.json([1, 2, 3])

      assert result.body == [1, 2, 3]
    end
  end

  describe "text/2" do
    test "creates text response with default status" do
      result = Nex.text("Hello World")

      assert result.status == 200
      assert result.body == "Hello World"
      assert result.content_type == "text/plain"
    end

    test "creates text response with custom status" do
      result = Nex.text("Error", status: 500)

      assert result.status == 500
    end
  end

  describe "html/2" do
    test "creates HTML response with default status" do
      result = Nex.html("<h1>Hello</h1>")

      assert result.status == 200
      assert result.body == "<h1>Hello</h1>"
      assert result.content_type == "text/html"
    end

    test "creates HTML response with custom status" do
      result = Nex.html("<p>Created</p>", status: 201)

      assert result.status == 201
    end
  end

  describe "redirect/2" do
    test "creates redirect response with default 302" do
      result = Nex.redirect("/dashboard")

      assert result.status == 302
      assert result.headers["location"] == "/dashboard"
      assert result.body == ""
    end

    test "creates redirect with custom status" do
      result = Nex.redirect("/permanent", status: 301)

      assert result.status == 301
    end
  end

  describe "status/2" do
    test "creates status response with body" do
      result = Nex.status(404, "Not Found")

      assert result.status == 404
      assert result.body == "Not Found"
      assert result.content_type == "text/plain"
    end

    test "creates status response without body" do
      result = Nex.status(204)

      assert result.status == 204
      assert result.body == ""
    end
  end

  describe "stream/1" do
    test "creates SSE streaming response" do
      callback = fn _send -> :ok end
      result = Nex.stream(callback)

      assert result.status == 200
      assert result.content_type == "text/event-stream"
      assert is_function(result.body)
      assert result.headers["cache-control"] == "no-cache, no-transform"
      assert result.headers["connection"] == "keep-alive"
    end
  end
end
