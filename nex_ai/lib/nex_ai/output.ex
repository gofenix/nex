defmodule NexAI.Output do
  @moduledoc """
  Defines output specifications for generation functions.
  Use with `generate_text` and `stream_text` via the `:output` option.
  """

  @type t :: %{mode: :text | :object | :array | :enum | :json, schema: map() | nil, description: String.t() | nil}

  @doc """
  Specifies that the output should be plain text.
  """
  def text, do: %{mode: :text, schema: nil}

  @doc """
  Specifies that the output should be a structured object matching the given schema.
  """
  def object(schema, opts \\ []) do
    %{
      mode: :object, 
      schema: schema,
      name: opts[:name],
      description: opts[:description]
    }
  end

  @doc """
  Specifies that the output should be an array of items matching the schema.
  """
  def array(element_schema, opts \\ []) do
    %{
      mode: :array,
      schema: element_schema,
      name: opts[:name],
      description: opts[:description]
    }
  end

  @doc """
  Specifies that the output should be one of the provided options (enum).
  """
  def choice(options, opts \\ []) when is_list(options) do
    %{
      mode: :enum,
      schema: %{type: "string", enum: options},
      options: options,
      description: opts[:description]
    }
  end

  @doc """
  Specifies that the output should be a JSON object (without strict schema validation).
  """
  def json(opts \\ []) do
    %{
      mode: :json,
      schema: nil,
      description: opts[:description]
    }
  end
end
