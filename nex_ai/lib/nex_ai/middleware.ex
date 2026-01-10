defmodule NexAI.Middleware do
  @moduledoc """
  Proper middleware system for NexAI.
  Wraps a LanguageModel and intercepts calls using the Interceptor pattern.
  """
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol

  defstruct [:inner_model, :middleware_mod, :middleware_opts]

  @callback wrap_generate(model :: any(), params :: map(), opts :: keyword(), next :: (any(), map() -> any())) :: any()
  @callback wrap_stream(model :: any(), params :: map(), opts :: keyword(), next :: (any(), map() -> Enumerable.t())) :: Enumerable.t()

  @doc "Wraps a model with a list of middlewares."
  def wrap_model(model, middlewares) when is_list(middlewares) do
    Enum.reduce(middlewares, model, fn
      {mod, opts}, acc -> %__MODULE__{inner_model: acc, middleware_mod: mod, middleware_opts: opts}
      mod, acc when is_atom(mod) -> %__MODULE__{inner_model: acc, middleware_mod: mod, middleware_opts: []}
    end)
  end

  def wrap_model(model, middleware_mod) when is_atom(middleware_mod) do
    wrap_model(model, [{middleware_mod, []}])
  end

  defimpl ModelProtocol do
    def provider(wrapper), do: ModelProtocol.provider(wrapper.inner_model)
    def model_id(wrapper), do: ModelProtocol.model_id(wrapper.inner_model)

    def do_generate(wrapper, params) do
      if function_exported?(wrapper.middleware_mod, :wrap_generate, 4) do
        wrapper.middleware_mod.wrap_generate(wrapper.inner_model, params, wrapper.middleware_opts, &ModelProtocol.do_generate/2)
      else
        ModelProtocol.do_generate(wrapper.inner_model, params)
      end
    end

    def do_stream(wrapper, params) do
      if function_exported?(wrapper.middleware_mod, :wrap_stream, 4) do
        wrapper.middleware_mod.wrap_stream(wrapper.inner_model, params, wrapper.middleware_opts, &ModelProtocol.do_stream/2)
      else
        ModelProtocol.do_stream(wrapper.inner_model, params)
      end
    end
  end
end
