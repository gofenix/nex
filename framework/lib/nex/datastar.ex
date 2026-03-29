defmodule Nex.Datastar do
  @moduledoc """
  Server-side helpers for the Datastar hypermedia framework.

  Produces SSE event maps compatible with `Nex.stream/1` that follow
  the Datastar wire protocol.

  ## Usage

      Nex.stream(fn send ->
        send.(Nex.Datastar.patch_elements(~s(<div id="feed">Hello</div>)))
        send.(Nex.Datastar.patch_signals(%{count: 1}))
      end)
  """

  @doc """
  Builds a `datastar-patch-elements` SSE event.

  Returns a map that can be passed directly to the `send` function
  inside `Nex.stream/1`.

  ## Options

    * `:selector` - CSS selector for the target element. If omitted,
      Datastar uses the fragment's `id` attribute.
    * `:mode` - Merge mode. One of `"morph"`, `"inner"`, `"outer"`,
      `"prepend"`, `"append"`, `"before"`, `"after"`, `"upsertAttributes"`.
    * `:use_view_transition` - Whether to use view transitions. Defaults to `false`.

  ## Examples

      Nex.Datastar.patch_elements(~s(<div id="counter">42</div>))
      #=> %{event: "datastar-patch-elements", data: "fragments <div id=\\"counter\\">42</div>"}

      Nex.Datastar.patch_elements("<span>hi</span>", selector: "#feed", mode: "append")
  """
  def patch_elements(fragments, opts \\ []) do
    lines =
      [
        if(opts[:selector], do: "selector #{opts[:selector]}"),
        if(opts[:mode], do: "mode #{opts[:mode]}"),
        if(opts[:use_view_transition], do: "useViewTransition true"),
        "fragments #{fragments}"
      ]
      |> Enum.reject(&is_nil/1)

    %{event: "datastar-patch-elements", data: Enum.join(lines, "\n")}
  end

  @doc """
  Builds a `datastar-patch-signals` SSE event.

  Signals are encoded as JSON following RFC 7396 (JSON Merge Patch).

  ## Options

    * `:only_if_missing` - Only set signals that don't already exist
      on the client. Defaults to `false`.

  ## Examples

      Nex.Datastar.patch_signals(%{count: 1, name: "Nex"})
      #=> %{event: "datastar-patch-signals", data: "signals {\\"count\\":1,\\"name\\":\\"Nex\\"}"}
  """
  def patch_signals(signals, opts \\ []) do
    json = if is_binary(signals), do: signals, else: Jason.encode!(signals)

    lines =
      [
        if(opts[:only_if_missing], do: "onlyIfMissing true"),
        "signals #{json}"
      ]
      |> Enum.reject(&is_nil/1)

    %{event: "datastar-patch-signals", data: Enum.join(lines, "\n")}
  end
end
