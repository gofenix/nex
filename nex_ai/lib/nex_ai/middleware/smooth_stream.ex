defmodule NexAI.Middleware.SmoothStream do
  @moduledoc """
  Smooths out the text stream by introducing artificial delays between tokens.
  Equivalent to Vercel AI SDK's smoothStream().
  """
  @behaviour NexAI.Middleware

  def wrap_generate(model, params, _opts, next), do: next.(model, params)

  def wrap_stream(model, params, opts, next) do
    delay = opts[:delay] || 50

    model
    |> next.(params)
    |> Stream.flat_map(fn event ->
      if event.type == :text_delta do
        # Split text into small chunks/tokens and add delay
        text = event.text || ""
        tokens = String.split(text, ~r/(?<=\s)|(?=\s)/, include_captures: true)
        Enum.map(tokens, fn token ->
          Process.sleep(delay)
          # Use struct/2 to preserve StreamPart type instead of creating plain map
          struct(event, text: token)
        end)
      else
        [event]
      end
    end)
  end
end
