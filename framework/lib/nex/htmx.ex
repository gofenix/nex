defmodule Nex.HTMX do
  @moduledoc """
  Pipeline-friendly functions for generating HTMX responses.

  These functions allow you to attach HTMX-specific headers (like `HX-Trigger`, `HX-Push-Url`) 
  to your HEEx templates seamlessly.

  ## Example

      def create_todo(req) do
        ~H"\""
        <div id="todo-1">New Todo</div>
        "\""
        |> push_url("/todos/1")
        |> trigger("todo-created", %{id: 1})
      end
  """

  alias Nex.Response

  @doc """
  Pushes a new URL into the browser's history stack.
  Sets the `HX-Push-Url` header.
  """
  @spec push_url(term(), String.t()) :: Response.t()
  def push_url(html_or_resp, url) do
    put_header(html_or_resp, "hx-push-url", url)
  end

  @doc """
  Replaces the current URL in the browser's history stack.
  Sets the `HX-Replace-Url` header.
  """
  @spec replace_url(term(), String.t()) :: Response.t()
  def replace_url(html_or_resp, url) do
    put_header(html_or_resp, "hx-replace-url", url)
  end

  @doc """
  Triggers a client-side event.
  Sets the `HX-Trigger` header. Multiple triggers will be merged.
  """
  @spec trigger(term(), String.t(), term()) :: Response.t()
  def trigger(html_or_resp, event_name, detail \\ nil) do
    merge_trigger(html_or_resp, "hx-trigger", event_name, detail)
  end

  @doc """
  Triggers a client-side event after the swap step.
  Sets the `HX-Trigger-After-Swap` header.
  """
  @spec trigger_after_swap(term(), String.t(), term()) :: Response.t()
  def trigger_after_swap(html_or_resp, event_name, detail \\ nil) do
    merge_trigger(html_or_resp, "hx-trigger-after-swap", event_name, detail)
  end

  @doc """
  Triggers a client-side event after the settle step.
  Sets the `HX-Trigger-After-Settle` header.
  """
  @spec trigger_after_settle(term(), String.t(), term()) :: Response.t()
  def trigger_after_settle(html_or_resp, event_name, detail \\ nil) do
    merge_trigger(html_or_resp, "hx-trigger-after-settle", event_name, detail)
  end

  @doc """
  Changes the target element of the response.
  Sets the `HX-Retarget` header.
  """
  @spec retarget(term(), String.t()) :: Response.t()
  def retarget(html_or_resp, selector) do
    put_header(html_or_resp, "hx-retarget", selector)
  end

  @doc """
  Changes the swap method of the response.
  Sets the `HX-Reswap` header.
  """
  @spec reswap(term(), String.t()) :: Response.t()
  def reswap(html_or_resp, swap_style) do
    put_header(html_or_resp, "hx-reswap", swap_style)
  end

  # --- Internal Helpers ---

  defp wrap(%Response{} = resp), do: resp

  defp wrap(html) do
    %Response{
      status: 200,
      body: html,
      content_type: "text/html"
    }
  end

  defp put_header(html_or_resp, key, value) do
    resp = wrap(html_or_resp)
    %Response{resp | headers: Map.put(resp.headers, key, value)}
  end

  defp merge_trigger(html_or_resp, header_key, event_name, detail) do
    resp = wrap(html_or_resp)
    existing_header = Map.get(resp.headers, header_key)

    new_trigger = if detail, do: %{event_name => detail}, else: event_name

    merged =
      case {existing_header, new_trigger} do
        {nil, str} when is_binary(str) ->
          str

        {nil, map} when is_map(map) ->
          Jason.encode!(map)

        {existing, str} when is_binary(existing) and is_binary(str) ->
          if String.starts_with?(existing, "{") do
            # existing is JSON
            case Jason.decode(existing) do
              {:ok, map} -> Map.put(map, str, %{}) |> Jason.encode!()
              _ -> "#{existing}, #{str}"
            end
          else
            "#{existing}, #{str}"
          end

        {existing, map} when is_binary(existing) and is_map(map) ->
          if String.starts_with?(existing, "{") do
            case Jason.decode(existing) do
              {:ok, existing_map} -> Map.merge(existing_map, map) |> Jason.encode!()
              _ -> Map.put(map, existing, %{}) |> Jason.encode!()
            end
          else
            Map.put(map, existing, %{}) |> Jason.encode!()
          end
      end

    %Response{resp | headers: Map.put(resp.headers, header_key, merged)}
  end
end
