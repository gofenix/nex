defmodule Nex.DatastarTest do
  use ExUnit.Case, async: true

  alias Nex.Datastar

  describe "patch_elements/2" do
    test "builds event with fragments only" do
      result = Datastar.patch_elements(~s(<div id="feed">Hello</div>))

      assert result == %{
               event: "datastar-patch-elements",
               data: ~s(fragments <div id="feed">Hello</div>)
             }
    end

    test "includes selector when provided" do
      result = Datastar.patch_elements("<span>hi</span>", selector: "#feed")

      assert result == %{
               event: "datastar-patch-elements",
               data: "selector #feed\nfragments <span>hi</span>"
             }
    end

    test "includes mode when provided" do
      result = Datastar.patch_elements("<li>item</li>", selector: "#list", mode: "append")

      assert result == %{
               event: "datastar-patch-elements",
               data: "selector #list\nmode append\nfragments <li>item</li>"
             }
    end

    test "includes useViewTransition when true" do
      result =
        Datastar.patch_elements("<div>x</div>",
          selector: "#box",
          use_view_transition: true
        )

      assert result == %{
               event: "datastar-patch-elements",
               data: "selector #box\nuseViewTransition true\nfragments <div>x</div>"
             }
    end

    test "omits useViewTransition when false" do
      result = Datastar.patch_elements("<div>x</div>", use_view_transition: false)

      assert result == %{
               event: "datastar-patch-elements",
               data: "fragments <div>x</div>"
             }
    end

    test "all options combined" do
      result =
        Datastar.patch_elements("<p>new</p>",
          selector: ".content",
          mode: "inner",
          use_view_transition: true
        )

      assert result == %{
               event: "datastar-patch-elements",
               data:
                 "selector .content\nmode inner\nuseViewTransition true\nfragments <p>new</p>"
             }
    end
  end

  describe "patch_signals/2" do
    test "builds event with map signals" do
      result = Datastar.patch_signals(%{count: 1, name: "Nex"})

      assert result.event == "datastar-patch-signals"
      decoded = result.data |> String.trim_leading("signals ") |> Jason.decode!()
      assert decoded == %{"count" => 1, "name" => "Nex"}
    end

    test "builds event with pre-encoded JSON string" do
      result = Datastar.patch_signals(~s({"ready":true}))

      assert result == %{
               event: "datastar-patch-signals",
               data: ~s(signals {"ready":true})
             }
    end

    test "includes onlyIfMissing when true" do
      result = Datastar.patch_signals(%{theme: "dark"}, only_if_missing: true)

      assert result.event == "datastar-patch-signals"
      assert result.data =~ "onlyIfMissing true"
      assert result.data =~ "signals "
    end

    test "omits onlyIfMissing when false" do
      result = Datastar.patch_signals(%{x: 1}, only_if_missing: false)
      refute result.data =~ "onlyIfMissing"
    end
  end

  describe "integration with format_sse_chunk" do
    test "patch_elements output produces valid SSE when formatted" do
      event = Datastar.patch_elements("<div>hi</div>", selector: "#target")
      # Simulate what Nex.Handler.Stream.format_sse_chunk/1 does for %{event, data} maps
      formatted = format_sse(event)

      assert formatted == "event: datastar-patch-elements\ndata: selector #target\ndata: fragments <div>hi</div>\n\n"
    end

    test "patch_signals output produces valid SSE when formatted" do
      event = Datastar.patch_signals(%{count: 42})
      formatted = format_sse(event)

      assert formatted =~ "event: datastar-patch-signals\n"
      assert formatted =~ "data: signals "
      assert formatted =~ ~s("count":42)
    end

    # Mirrors Nex.Handler.Stream.format_sse_chunk/1 logic for %{event, data} maps
    defp format_sse(%{event: event, data: data}) do
      formatted_data =
        data
        |> String.split("\n")
        |> Enum.map(&"data: #{&1}")
        |> Enum.join("\n")

      "event: #{event}\n#{formatted_data}\n\n"
    end
  end
end
