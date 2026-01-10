defmodule NexAI.Schema do
  @moduledoc """
  Schema utilities for NexAI.
  Provides helpers for defining and validating JSON schemas.
  """

  @doc """
  Converts a schema definition to JSON Schema format.
  Currently a passthrough, but can be extended for validation.
  """
  def json_schema(schema), do: schema

  @doc """
  Creates an object schema.

  ## Examples

      schema = NexAI.Schema.object(%{
        name: NexAI.Schema.string(description: "User name"),
        age: NexAI.Schema.number(description: "User age")
      }, required: ["name"])
  """
  def object(properties, opts \\ []) do
    %{
      type: "object",
      properties: properties,
      required: opts[:required] || []
    }
    |> maybe_add(:description, opts[:description])
  end

  @doc """
  Creates a string schema.
  """
  def string(opts \\ []) do
    %{type: "string"}
    |> maybe_add(:description, opts[:description])
    |> maybe_add(:enum, opts[:enum])
    |> maybe_add(:minLength, opts[:min_length])
    |> maybe_add(:maxLength, opts[:max_length])
  end

  @doc """
  Creates a number schema.
  """
  def number(opts \\ []) do
    %{type: "number"}
    |> maybe_add(:description, opts[:description])
    |> maybe_add(:minimum, opts[:minimum])
    |> maybe_add(:maximum, opts[:maximum])
  end

  @doc """
  Creates an integer schema.
  """
  def integer(opts \\ []) do
    %{type: "integer"}
    |> maybe_add(:description, opts[:description])
    |> maybe_add(:minimum, opts[:minimum])
    |> maybe_add(:maximum, opts[:maximum])
  end

  @doc """
  Creates a boolean schema.
  """
  def boolean(opts \\ []) do
    %{type: "boolean"}
    |> maybe_add(:description, opts[:description])
  end

  @doc """
  Creates an array schema.
  """
  def array(items, opts \\ []) do
    %{type: "array", items: items}
    |> maybe_add(:description, opts[:description])
    |> maybe_add(:minItems, opts[:min_items])
    |> maybe_add(:maxItems, opts[:max_items])
  end

  @doc """
  Creates an enum schema.
  """
  def enum(values, opts \\ []) do
    %{type: "string", enum: values}
    |> maybe_add(:description, opts[:description])
  end

  @doc """
  Creates a nullable schema.
  """
  def nullable(schema) do
    Map.put(schema, :nullable, true)
  end

  @doc """
  Creates an optional field (for use in object properties).
  """
  def optional(schema) do
    Map.put(schema, :optional, true)
  end

  defp maybe_add(map, _key, nil), do: map
  defp maybe_add(map, key, value), do: Map.put(map, key, value)
end
