defmodule NexAI.Middleware do
  @moduledoc """
  Middleware behavior for intercepting and modifying AI model requests and responses.
  """

  @callback wrap(model :: any(), opts :: keyword()) :: any()

  @doc """
  Wraps a model with a list of middlewares.
  """
  def wrap_model(model, middlewares) when is_list(middlewares) do
    Enum.reduce(middlewares, model, fn middleware, current_model ->
      cond do
        is_function(middleware) -> 
          middleware.(current_model)
        is_tuple(middleware) and tuple_size(middleware) == 2 ->
          {mod, opts} = middleware
          if module_loaded?(mod), do: mod.wrap(current_model, opts), else: current_model
        module_loaded?(middleware) -> 
          middleware.wrap(current_model, [])
        true -> 
          current_model
      end
    end)
  end

  defp module_loaded?(module) do
    Code.ensure_loaded?(module) && function_exported?(module, :wrap, 2)
  end
end
