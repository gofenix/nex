defmodule Nex.ResTest do
  use ExUnit.Case, async: true

  alias Nex.{Res, Response}

  describe "new/0" do
    test "creates default response" do
      res = Res.new()
      assert %Response{status: 200, body: nil, headers: %{}} = res
    end
  end

  describe "status/2" do
    test "sets status code" do
      res = Res.new() |> Res.status(201)
      assert res.status == 201
    end
  end

  describe "json/2" do
    test "sets body and content type" do
      res = Res.new() |> Res.json(%{ok: true})
      assert res.body == %{ok: true}
      assert res.content_type == "application/json"
    end

    test "preserves status from earlier in pipeline" do
      res = Res.new() |> Res.status(201) |> Res.json(%{created: true})
      assert res.status == 201
      assert res.body == %{created: true}
    end
  end

  describe "html/2" do
    test "sets body and content type" do
      res = Res.new() |> Res.html("<h1>Hello</h1>")
      assert res.body == "<h1>Hello</h1>"
      assert res.content_type == "text/html"
    end
  end

  describe "text/2" do
    test "sets body and content type" do
      res = Res.new() |> Res.text("hello")
      assert res.body == "hello"
      assert res.content_type == "text/plain"
    end
  end

  describe "send/2" do
    test "sets body without changing content type" do
      res = Res.new() |> Res.send("raw data")
      assert res.body == "raw data"
      assert res.content_type == "application/json"
    end
  end

  describe "redirect/2,3" do
    test "sets 302 redirect by default" do
      res = Res.new() |> Res.redirect("/login")
      assert res.status == 302
      assert res.headers["location"] == "/login"
      assert res.body == ""
    end

    test "supports custom status" do
      res = Res.new() |> Res.redirect("/new-path", 301)
      assert res.status == 301
      assert res.headers["location"] == "/new-path"
    end
  end

  describe "set_header/3" do
    test "sets a response header" do
      res = Res.new() |> Res.set_header("x-request-id", "abc")
      assert res.headers["x-request-id"] == "abc"
    end

    test "preserves existing headers" do
      res =
        Res.new()
        |> Res.set_header("x-one", "1")
        |> Res.set_header("x-two", "2")

      assert res.headers["x-one"] == "1"
      assert res.headers["x-two"] == "2"
    end
  end

  describe "full pipeline" do
    test "builds a complete response" do
      res =
        Res.new()
        |> Res.set_header("x-request-id", "abc")
        |> Res.status(201)
        |> Res.json(%{user: "alice"})

      assert res.status == 201
      assert res.body == %{user: "alice"}
      assert res.content_type == "application/json"
      assert res.headers["x-request-id"] == "abc"
    end
  end
end
