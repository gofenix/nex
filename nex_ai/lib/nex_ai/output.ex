defmodule NexAI.Output do
  @moduledoc """
  Output specification for NexAI, aligned with Vercel AI SDK v6.
  Defines how the AI should format its output (text, object, array, json).
  """

  def text, do: %{type: :text}

  def object(opts) do
    schema = if is_map(opts), do: opts[:schema], else: opts
    %{
      type: :object,
      schema: schema,
      name: if(is_map(opts), do: opts[:name]),
      description: if(is_map(opts), do: opts[:description])
    }
  end

  def array(opts) do
    element = if is_map(opts), do: opts[:element], else: opts
    %{
      type: :array,
      element: element,
      name: if(is_map(opts), do: opts[:name]),
      description: if(is_map(opts), do: opts[:description])
    }
  end

  def json(opts \\ []) do
    %{
      type: :json,
      name: opts[:name],
      description: opts[:description]
    }
  end
end
