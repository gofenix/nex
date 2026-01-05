defmodule NexAI.Schema do
  @moduledoc """
  Helpers for creating JSON Schemas.
  Maps to `jsonSchema` in Vercel AI SDK.
  """

  @doc """
  Creates a JSON schema object definition.
  """
  def json_schema(schema) do
    schema
  end
  
  def object(properties, opts \\ []) do
    required = opts[:required] || Map.keys(properties)
    %{
      type: "object",
      properties: properties,
      required: required,
      additionalProperties: opts[:additional_properties] || false
    }
  end

  def string(description \\ nil) do
    if description, do: %{type: "string", description: description}, else: %{type: "string"}
  end

  def number(description \\ nil) do
    if description, do: %{type: "number", description: description}, else: %{type: "number"}
  end

  def boolean(description \\ nil) do
    if description, do: %{type: "boolean", description: description}, else: %{type: "boolean"}
  end

  def array(items, description \\ nil) do
    base = %{type: "array", items: items}
    if description, do: Map.put(base, :description, description), else: base
  end
end
