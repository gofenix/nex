defmodule Nex.HTMXTest do
  use ExUnit.Case, async: true
  import Phoenix.Component
  import Nex.HTMX

  alias Nex.Response

  describe "HTMX header helpers" do
    test "push_url/2 adds hx-push-url header to HEEx" do
      assigns = %{}
      heex = ~H"<div>Hello</div>"
      resp = push_url(heex, "/new-path")

      assert %Response{} = resp
      assert resp.status == 200
      assert resp.headers["hx-push-url"] == "/new-path"
      assert is_struct(resp.body, Phoenix.LiveView.Rendered)
    end

    test "push_url/2 adds hx-push-url header to existing Response" do
      resp = %Response{status: 201, body: "OK"}
      updated_resp = push_url(resp, "/new-path")

      assert updated_resp.status == 201
      assert updated_resp.headers["hx-push-url"] == "/new-path"
    end

    test "replace_url/2 adds hx-replace-url header" do
      assigns = %{}
      resp = replace_url(~H"<div>Hello</div>", "/replace")
      assert resp.headers["hx-replace-url"] == "/replace"
    end

    test "retarget/2 adds hx-retarget header" do
      assigns = %{}
      resp = retarget(~H"<div>Hello</div>", "#target-id")
      assert resp.headers["hx-retarget"] == "#target-id"
    end

    test "reswap/2 adds hx-reswap header" do
      assigns = %{}
      resp = reswap(~H"<div>Hello</div>", "beforeend")
      assert resp.headers["hx-reswap"] == "beforeend"
    end
  end

  describe "HTMX trigger merging" do
    test "trigger/2 with simple string" do
      assigns = %{}
      resp = trigger(~H"<div></div>", "event-one")
      assert resp.headers["hx-trigger"] == "event-one"
    end

    test "trigger/3 with details map encodes as JSON" do
      assigns = %{}
      resp = trigger(~H"<div></div>", "event-two", %{id: 1})
      assert Jason.decode!(resp.headers["hx-trigger"]) == %{"event-two" => %{"id" => 1}}
    end

    test "trigger/2 merges multiple string events" do
      assigns = %{}
      resp =
        ~H"<div></div>"
        |> trigger("event-one")
        |> trigger("event-two")

      assert resp.headers["hx-trigger"] == "event-one, event-two"
    end

    test "trigger/3 merges string and map events into JSON" do
      assigns = %{}
      resp =
        ~H"<div></div>"
        |> trigger("event-one")
        |> trigger("event-two", %{foo: "bar"})

      assert Jason.decode!(resp.headers["hx-trigger"]) == %{
               "event-one" => %{},
               "event-two" => %{"foo" => "bar"}
             }
    end

    test "trigger/3 merges multiple map events into JSON" do
      assigns = %{}
      resp =
        ~H"<div></div>"
        |> trigger("event-one", %{a: 1})
        |> trigger("event-two", %{b: 2})

      assert Jason.decode!(resp.headers["hx-trigger"]) == %{
               "event-one" => %{"a" => 1},
               "event-two" => %{"b" => 2}
             }
    end
  end
end
