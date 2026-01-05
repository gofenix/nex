defmodule NexAI.Middleware.DefaultSettings do
  @moduledoc """
  Middleware that injects default settings into every model call.
  """
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol

  def do_generate(model, params, opts) do
    params = update_in(params.config, &Keyword.merge(opts, &1))
    ModelProtocol.do_generate(model, params)
  end

  def do_stream(model, params, opts) do
    params = update_in(params.config, &Keyword.merge(opts, &1))
    ModelProtocol.do_stream(model, params)
  end
end
