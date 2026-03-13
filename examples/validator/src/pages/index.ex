defmodule NexValidatorExample.Pages.Index do
  @moduledoc """Validator example page using Nex.Validator (if available) and HTMX"""

  alias NexValidatorExample.Layouts

  # Public render function: accepts a map of params (string keys) and returns HTML string
  def render(params \\ %{}) do
    params = to_string_keys(params)
    errors = collect_errors(params)
    html = build_form(params, errors)
    Layouts.render(html)
  end

  defp to_string_keys(map) when is_map(map) do
    for {k, v} <- map, into: %{}, do: {to_string(k), v}
  end
  defp to_string_keys(other), do: other

  defp collect_errors(params) do
    if function_exported?(Nex.Validator, :validate, 2) do
      case Nex.Validator.validate(params, [
             name: [:required, :string],
             email: [:required, :string, :email],
             age: [:required, {:min, 0}, {:max, 120}],
             password: [:required, :string, {:min, 6}, {:max, 128}],
             website: [{:format, ~r/^(https?:\/\/)?([\w\-]+\.)+[\w\-]+(\/.*)?$/}]
           ]) do
        {:ok, _} -> %{}
        {:error, errs} -> errs
      end
    else
      %{}
    end
  end

  defp build_form(params, errors) do
    name = Map.get(params, "name", "")
    email = Map.get(params, "email", "")
    age = Map.get(params, "age", "")
    website = Map.get(params, "website", "")

    error_tag = fn field_served ->
      case Map.get(errors, field_served) do
        nil -> ""
        msg -> "<span class=\"error\">#{escape_html(msg)}</span>"
      end
    end

    # HTMX-enabled form with per-field partial updates
    """
    <form id=\"registration\" hx-post=\"/validate\" hx-trigger=\"submit\" hx-target=\"#form-status\" method=\"post\" action=\"/validate\" class=\"form\">
      <div class=\"field\">
        <label>Name</label>
        <input type=\"text\" name=\"name\" value=\"#{escape_html(name)}\" hx-post=\"/validate\" hx-trigger=\"change blur\" hx-target=\"#error-name\" hx-swap=\"outerHTML\" />
        <div id=\"error-name\">#{error_tag.("name")}</div>
      </div>

      <div class=\"field\">
        <label>Email</label>
        <input type=\"email\" name=\"email\" value=\"#{escape_html(email)}\" hx-post=\"/validate\" hx-trigger=\"change blur\" hx-target=\"#error-email\" hx-swap=\"outerHTML\" />
        <div id=\"error-email\">#{error_tag.("email")}</div>
      </div>

      <div class=\"field\">
        <label>Age</label>
        <input type=\"number\" name=\"age\" value=\"#{escape_html(age)}\" min=\"0\" hx-post=\"/validate\" hx-trigger=\"change blur\" hx-target=\"#error-age\" hx-swap=\"outerHTML\" />
        <div id=\"error-age\">#{error_tag.("age")}</div>
      </div>

      <div class=\"field\">
        <label>Password</label>
        <input type=\"password\" name=\"password\" value=\"\" hx-post=\"/validate\" hx-trigger=\"change blur\" hx-target=\"#error-password\" hx-swap=\"outerHTML\" />
        <div id=\"error-password\">#{error_tag.("password")}</div>
      </div>

      <div class=\"field\">
        <label>Website</label>
        <input type=\"text\" name=\"website\" value=\"#{escape_html(website)}\" hx-post=\"/validate\" hx-trigger=\"change blur\" hx-target=\"#error-website\" hx-swap=\"outerHTML\" />
        <div id=\"error-website\">#{error_tag.("website")}</div>
      </div>

      <div class=\"form-actions\">
        <button type=\"submit\">Register</button>
      </div>
    </form>

    <div id=\"form-status\"></div>
    """
  end

  defp escape_html(nil), do: ""
  defp escape_html(s) when is_binary(s) do
    s
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
end
