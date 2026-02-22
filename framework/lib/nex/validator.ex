defmodule Nex.Validator do
  @moduledoc """
  Params validation for Nex applications.

  ## Usage

      defmodule MyApp.Pages.Users do
        use Nex

        def create(params) do
          case validate(params, %{
            "name" => [:required, :string],
            "email" => [:required, :string, :email],
            "age" => [:number, min: 18]
          }) do
            {:ok, valid_params} ->
              # Create user
            {:error, errors} ->
              Nex.json(%{errors: errors}, status: 422)
          end
        end
      end

  ## Validators

  - `:required` - Field must be present and not empty
  - `:string` - Must be a string
  - `:number` - Must be a number
  - `:boolean` - Must be true or false
  - `:email` - Must be a valid email format
  - `:url` - Must be a valid URL
  - `:min` - Minimum length/value (requires :string or :number)
  - `:max` - Maximum length/value (requires :string or :number)
  - `:format` - Regex pattern match
  - `:in` - Must be in list of allowed values

  ## Custom Validators

      def my_validator(value, _opts) do
        if valid?(value) do
          :ok
        else
          {:error, "must be valid"}
        end
      end

      validate(params, %{"field" => [:required, {&my_validator/2, [arg1: "value"]}]})
  """

  @type validation_error :: {String.t(), String.t()}
  @type validation_result :: {:ok, map()} | {:error, [validation_error()]}

  @doc """
  Validates params against a schema.

  ## Arguments

    * `params` - Map of parameters to validate
    * `schema` - Map of field names to validator rules

  ## Returns

    * `{:ok, validated_params}` - Validation passed
    * `{:error, errors}` - Validation failed

  ## Examples

      validate(%{"name" => "John"}, %{
        "name" => [:required, :string]
      })
      # => {:ok, %{"name" => "John"}}

      validate(%{}, %{
        "name" => [:required, :string]
      })
      # => {:error, [{"name", "is required"}]}
  """
  @spec validate(map(), map()) :: validation_result()
  def validate(params, schema) when is_map(params) and is_map(schema) do
    errors =
      schema
      |> Enum.flat_map(fn {field, rules} ->
        validate_field(field, Map.get(params, field), rules)
      end)

    if errors == [] do
      {:ok, params}
    else
      {:error, errors}
    end
  end

  @doc """
  Same as `validate/2` but raises on validation error.
  """
  @spec validate!(map(), map()) :: map()
  def validate!(params, schema) do
    case validate(params, schema) do
      {:ok, valid_params} -> valid_params
      {:error, errors} -> raise ArgumentError, inspect(errors)
    end
  end

  defp validate_field(field, value, rules) do
    rules
    |> Enum.flat_map(fn
      {:required, _opts} ->
        validate_required(field, value)

      :required ->
        validate_required(field, value)

      :string ->
        validate_type(field, value, &is_binary/1, "must be a string")

      :number ->
        validate_type(field, value, &is_number/1, "must be a number")

      :boolean ->
        validate_type(field, value, &is_boolean/1, "must be a boolean")

      :email ->
        validate_format(field, value, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, "must be a valid email")

      :url ->
        validate_format(field, value, ~r/^https?:\/\/.+/, "must be a valid URL")

      {:min, min} when is_number(min) ->
        validate_min_number(field, value, min)

      {:min, min} when is_integer(min) ->
        validate_min_length(field, value, min)

      {:max, max} when is_number(max) ->
        validate_max_number(field, value, max)

      {:max, max} when is_integer(max) ->
        validate_max_length(field, value, max)

      {:format, pattern} when is_binary(pattern) ->
        validate_format(field, value, Regex.compile!(pattern), "must match format")

      {:format, pattern} ->
        validate_format(field, value, pattern, "must match format")

      {:in, values} when is_list(values) ->
        validate_in(field, value, values)

      {custom, opts} when is_function(custom, 2) ->
        validate_custom(field, value, custom, opts)

      {custom, _opts} when is_function(custom, 1) ->
        validate_custom(field, value, custom, [])

      other ->
        [{field, "unknown validator: #{inspect(other)}"}]
    end)
  end

  defp validate_required(field, nil), do: [{field, "is required"}]
  defp validate_required(field, ""), do: [{field, "is required"}]
  defp validate_required(_field, _value), do: []

  defp validate_type(_field, nil, _type_check, _msg), do: []

  defp validate_type(field, value, type_check, msg) do
    if type_check.(value) do
      []
    else
      [{field, msg}]
    end
  end

  defp validate_format(_field, nil, _pattern, _msg), do: []

  defp validate_format(field, value, pattern, msg) do
    case Regex.run(pattern, to_string(value)) do
      nil -> [{field, msg}]
      _ -> []
    end
  end

  defp validate_min_number(_field, nil, _min), do: []

  defp validate_min_number(field, value, min) do
    if is_number(value) && value >= min do
      []
    else
      [{field, "must be at least #{min}"}]
    end
  end

  defp validate_min_length(_field, nil, _min), do: []

  defp validate_min_length(field, value, min) do
    if is_binary(value) && String.length(value) >= min do
      []
    else
      [{field, "must be at least #{min} characters"}]
    end
  end

  defp validate_max_number(_field, nil, _max), do: []

  defp validate_max_number(field, value, max) do
    if is_number(value) && value <= max do
      []
    else
      [{field, "must be at most #{max}"}]
    end
  end

  defp validate_max_length(_field, nil, _max), do: []

  defp validate_max_length(field, value, max) do
    if is_binary(value) && String.length(value) <= max do
      []
    else
      [{field, "must be at most #{max} characters"}]
    end
  end

  defp validate_in(_field, nil, _values), do: []

  defp validate_in(field, value, values) do
    if value in values do
      []
    else
      [{field, "must be one of: #{Enum.join(values, ", ")}"}]
    end
  end

  defp validate_custom(_field, nil, _validator, _opts), do: []

  defp validate_custom(field, value, validator, opts) do
    case validator.(value, opts) do
      :ok -> []
      {:ok, _} -> []
      {:error, msg} -> [{field, msg}]
      msg when is_binary(msg) -> [{field, msg}]
      _ -> [{field, "is invalid"}]
    end
  end
end
