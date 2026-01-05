defmodule NexAI.Middleware do
  @moduledoc """
  Proper middleware system for NexAI.
  Wraps a LanguageModel and intercepts calls using the Interceptor pattern.
  
  ### Creating a Middleware
  A middleware is a module that optionally implements `do_generate/3` and `do_stream/3`.
  
  Example:
  ```elixir
  defmodule MyLogger do
    def do_generate(model, params, opts) do
      IO.inspect(params, label: "Request")
      NexAI.LanguageModel.Protocol.do_generate(model, params)
    end
  end
  ```
  """
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol

  defstruct [:inner_model, :middleware_mod, :middleware_opts]

  @doc "Wraps a model with a list of middlewares."
  def wrap_model(model, middlewares) when is_list(middlewares) do
    Enum.reduce(middlewares, model, fn
      {mod, opts}, acc -> %__MODULE__{inner_model: acc, middleware_mod: mod, middleware_opts: opts}
      mod, acc when is_atom(mod) -> %__MODULE__{inner_model: acc, middleware_mod: mod, middleware_opts: []}
      _other, acc -> acc
    end)
  end

  defimpl ModelProtocol do
    def do_generate(wrapper, params) do
      if function_exported?(wrapper.middleware_mod, :do_generate, 3) do
        wrapper.middleware_mod.do_generate(wrapper.inner_model, params, wrapper.middleware_opts)
      else
        ModelProtocol.do_generate(wrapper.inner_model, params)
      end
    end

    def do_stream(wrapper, params) do
      if function_exported?(wrapper.middleware_mod, :do_stream, 3) do
        wrapper.middleware_mod.do_stream(wrapper.inner_model, params, wrapper.middleware_opts)
      else
        ModelProtocol.do_stream(wrapper.inner_model, params)
      end
    end
  end
end
