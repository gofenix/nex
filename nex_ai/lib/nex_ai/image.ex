defmodule NexAI.Image do
  @moduledoc "Image generation for NexAI."
  alias NexAI.Provider.OpenAI

  def generate_image(opts) do
    model = opts[:model] || OpenAI
    model.generate_image(opts[:prompt], opts)
  end
end
