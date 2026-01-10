defmodule NexAI.Middleware.SmoothStream do
  @moduledoc """
  Smooths out the text stream by introducing artificial delays between tokens.
  Equivalent to Vercel AI SDK's smoothStream().
  """
  @behaviour NexAI.Middleware

  def wrap_generate(model, params, _opts, next), do: next.(model, params)

  def wrap_stream(model, params, opts, next) do
    delay = opts[:delay] || get_in(params, [:config, :smooth_stream, :delay]) || 10

    model
    |> next.(params)
    |> Stream.flat_map(fn event ->
      if event.type == :text do
        # Split text into small chunks/tokens and add delay
        # This is a simplified version of smoothing
        tokens = String.split(event.payload, ~r/(?<=\s)|(?=\s)/)
        Enum.map(tokens, fn token ->
          Process.sleep(delay)
          %{event | payload: token}
        end)
      else
        [event]
      end
    end)
  end
end
