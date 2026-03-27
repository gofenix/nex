defmodule NexValidatorExample.Pages.Index do
  use Nex

  @field_rules %{
    "name" => [:required, :string],
    "email" => [:required, :string, :email],
    "age" => [:required, :number, {:min, 0}, {:max, 120}],
    "password" => [
      :required,
      :string,
      {&__MODULE__.validate_password_length/2, min: 6},
      {&__MODULE__.validate_password_length/2, max: 128}
    ]
  }
  @website_pattern ~r/^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/.*)?$/
  @fields ["name", "email", "age", "password", "website"]

  def mount(_params) do
    %{title: "Nex Validator Example"}
  end

  def render(assigns) do
    ~H"""
    <div data-testid="validator-page" class="rounded-3xl bg-white p-8 shadow-sm ring-1 ring-slate-200">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-slate-900">Nex.Validator Demo</h1>
        <p class="mt-2 text-slate-600">
          Validate each field with HTMX and submit once the form is clean.
        </p>
      </div>

      <form id="registration"
            hx-post="/validate"
            hx-target="#form-status"
            hx-swap="outerHTML"
            method="post"
            action="/validate"
            data-testid="validator-form"
            class="grid gap-5">
        <div class="grid gap-2">
          <label for="validator-name" class="text-sm font-semibold text-slate-700">Name</label>
          <input id="validator-name"
                 type="text"
                 name="name"
                 data-testid="validator-name"
                 hx-post="/validate"
                 hx-trigger="change blur"
                 hx-target="#error-name"
                 hx-swap="outerHTML"
                 class="rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-sky-500 focus:ring-2 focus:ring-sky-200" />
          <div id="error-name" data-testid="validator-error-name" class="min-h-6 text-sm text-red-600"></div>
        </div>

        <div class="grid gap-2">
          <label for="validator-email" class="text-sm font-semibold text-slate-700">Email</label>
          <input id="validator-email"
                 type="email"
                 name="email"
                 data-testid="validator-email"
                 hx-post="/validate"
                 hx-trigger="change blur"
                 hx-target="#error-email"
                 hx-swap="outerHTML"
                 class="rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-sky-500 focus:ring-2 focus:ring-sky-200" />
          <div id="error-email" data-testid="validator-error-email" class="min-h-6 text-sm text-red-600"></div>
        </div>

        <div class="grid gap-2">
          <label for="validator-age" class="text-sm font-semibold text-slate-700">Age</label>
          <input id="validator-age"
                 type="number"
                 name="age"
                 min="0"
                 data-testid="validator-age"
                 hx-post="/validate"
                 hx-trigger="change blur"
                 hx-target="#error-age"
                 hx-swap="outerHTML"
                 class="rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-sky-500 focus:ring-2 focus:ring-sky-200" />
          <div id="error-age" data-testid="validator-error-age" class="min-h-6 text-sm text-red-600"></div>
        </div>

        <div class="grid gap-2">
          <label for="validator-password" class="text-sm font-semibold text-slate-700">Password</label>
          <input id="validator-password"
                 type="password"
                 name="password"
                 data-testid="validator-password"
                 hx-post="/validate"
                 hx-trigger="change blur"
                 hx-target="#error-password"
                 hx-swap="outerHTML"
                 class="rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-sky-500 focus:ring-2 focus:ring-sky-200" />
          <div id="error-password" data-testid="validator-error-password" class="min-h-6 text-sm text-red-600"></div>
        </div>

        <div class="grid gap-2">
          <label for="validator-website" class="text-sm font-semibold text-slate-700">Website</label>
          <input id="validator-website"
                 type="text"
                 name="website"
                 placeholder="Optional"
                 data-testid="validator-website"
                 hx-post="/validate"
                 hx-trigger="change blur"
                 hx-target="#error-website"
                 hx-swap="outerHTML"
                 class="rounded-xl border border-slate-300 px-4 py-3 outline-none transition focus:border-sky-500 focus:ring-2 focus:ring-sky-200" />
          <div id="error-website" data-testid="validator-error-website" class="min-h-6 text-sm text-red-600"></div>
        </div>

        <div class="flex items-center justify-between pt-2">
          <p class="text-sm text-slate-500">Name, email, age, and password are required.</p>
          <button type="submit"
                  data-testid="validator-submit"
                  class="rounded-xl bg-sky-600 px-5 py-3 text-sm font-semibold text-white transition hover:bg-sky-700">
            Register
          </button>
        </div>
      </form>

      <div id="form-status" data-testid="validator-form-status" class="mt-6 min-h-12 rounded-2xl border border-dashed border-slate-300 p-4 text-sm text-slate-500">
        Submit the form to validate the full payload.
      </div>
    </div>
    """
  end

  def validate(req) do
    params =
      req.body
      |> stringify_keys()
      |> Map.drop(["_csrf_token"])

    case normalize_target(Map.get(req.headers, "hx-target")) do
      "form-status" ->
        errors = validate_form(params)
        render_form_status(errors)

      "error-" <> field when field in @fields ->
        render_field_error(field, validate_field(field, Map.get(params, field)))

      _ ->
        keys = Enum.filter(Map.keys(params), &(&1 in @fields))

        case keys do
          [field] ->
            render_field_error(field, validate_field(field, Map.get(params, field)))

          _ ->
            errors = validate_form(params)
            render_form_status(errors)
        end
    end
  end

  defp render_field_error(field, nil) do
    assigns = %{field: field}

    ~H"""
    <div id={"error-#{@field}"} data-testid={"validator-error-#{@field}"} class="min-h-6 text-sm text-red-600"></div>
    """
  end

  defp render_field_error(field, message) do
    assigns = %{field: field, message: message}

    ~H"""
    <div id={"error-#{@field}"} data-testid={"validator-error-#{@field}"} class="min-h-6 text-sm text-red-600">
      {@message}
    </div>
    """
  end

  defp render_form_status(errors) when map_size(errors) == 0 do
    assigns = %{}

    ~H"""
    <div id="form-status" data-testid="validator-form-status" class="mt-6 rounded-2xl border border-green-200 bg-green-50 p-4 text-sm text-green-700">
      Registration looks good.
    </div>
    """
  end

  defp render_form_status(_errors) do
    assigns = %{}

    ~H"""
    <div id="form-status" data-testid="validator-form-status" class="mt-6 rounded-2xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
      Please fix the highlighted validation errors before submitting.
    </div>
    """
  end

  defp validate_form(params) do
    params
    |> normalize_for_validation()
    |> Nex.Validator.validate(@field_rules)
    |> case do
      {:ok, _params} -> %{}
      {:error, errors} -> Map.new(errors)
    end
    |> validate_website(Map.get(params, "website"))
  end

  defp validate_field("website", value) do
    case validate_website(%{}, value) do
      %{"website" => message} -> message
      _ -> nil
    end
  end

  defp validate_field(field, value) do
    schema = %{field => Map.fetch!(@field_rules, field)}

    %{field => value}
    |> normalize_for_validation()
    |> Nex.Validator.validate(schema)
    |> case do
      {:ok, _params} -> nil
      {:error, errors} -> errors |> Map.new() |> Map.get(field)
    end
  end

  defp validate_website(errors, nil), do: errors
  defp validate_website(errors, ""), do: errors

  defp validate_website(errors, value) do
    if Regex.match?(@website_pattern, to_string(value)) do
      errors
    else
      Map.put(errors, "website", "must be a valid URL")
    end
  end

  defp normalize_for_validation(params) do
    Map.update(params, "age", nil, &normalize_age/1)
  end

  defp normalize_age(""), do: nil
  defp normalize_age(value) when is_integer(value), do: value

  defp normalize_age(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} -> parsed
      _ -> value
    end
  end

  defp normalize_age(value), do: value

  defp stringify_keys(map) when is_map(map) do
    for {key, value} <- map, into: %{}, do: {to_string(key), value}
  end

  def validate_password_length(value, opts) when is_binary(value) do
    cond do
      min = opts[:min] ->
        if String.length(value) >= min do
          :ok
        else
          {:error, "must be at least #{min} characters"}
        end

      max = opts[:max] ->
        if String.length(value) <= max do
          :ok
        else
          {:error, "must be at most #{max} characters"}
        end

      true ->
        :ok
    end
  end

  def validate_password_length(_value, _opts), do: {:error, "must be a string"}

  defp normalize_target(nil), do: nil
  defp normalize_target("#" <> target), do: target
  defp normalize_target(target), do: target
end
