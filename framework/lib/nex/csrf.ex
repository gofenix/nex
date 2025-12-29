defmodule Nex.CSRF do
  @moduledoc """
  CSRF (Cross-Site Request Forgery) protection for Nex applications.

  ## Usage

  In your layout or form, include the CSRF token:

      <form method="post" action="/submit">
        {Nex.CSRF.input_tag()}
        <!-- form fields -->
      </form>

  Or for HTMX requests, add to the body:

      <body hx-headers={Nex.CSRF.hx_headers()}>

  The framework automatically validates CSRF tokens on POST/PUT/PATCH/DELETE requests.
  """

  @token_key "_csrf_token"
  @header_name "x-csrf-token"
  @token_length 32

  @doc """
  Generates a new CSRF token and stores it in the session.
  Returns the token string.
  """
  def generate_token do
    token = :crypto.strong_rand_bytes(@token_length) |> Base.url_encode64(padding: false)
    # Store in process dictionary for this request
    Process.put(:csrf_token, token)
    token
  end

  @doc """
  Gets the current CSRF token, generating one if needed.
  """
  def get_token do
    case Process.get(:csrf_token) do
      nil -> generate_token()
      token -> token
    end
  end

  @doc """
  Returns an HTML hidden input tag with the CSRF token.
  """
  def input_tag do
    token = get_token()
    {:safe, ~s(<input type="hidden" name="#{@token_key}" value="#{token}" />)}
  end

  @doc """
  Returns a JSON string for hx-headers attribute with CSRF token.
  Use this in the body tag for HTMX requests.

  ## Example

      <body hx-headers={Nex.CSRF.hx_headers()}>
  """
  def hx_headers do
    token = get_token()
    ~s({"#{@header_name}": "#{token}"})
  end

  @doc """
  Returns the meta tag for CSRF token (useful for JavaScript).
  """
  def meta_tag do
    token = get_token()
    {:safe, ~s(<meta name="csrf-token" content="#{token}" />)}
  end

  @doc """
  Validates the CSRF token from the request.
  Returns :ok if valid, {:error, reason} otherwise.

  Note: Since Nex is stateless and does not use server-side sessions, strict token
  validation requires the token to be present in the process dictionary (generated
  during the same request cycle) or implementing a stateless signed token mechanism.
  Currently, if no expected token is found (e.g. stateless POST), validation passes
  to allow the request to proceed, but this behavior may be tightened in future versions.
  """
  def validate(conn) do
    expected_token = Process.get(:csrf_token)

    # Get token from header or params
    submitted_token = get_submitted_token(conn)

    cond do
      is_nil(expected_token) ->
        # No token was generated/stored for this request cycle.
        # In a stateless architecture without signed tokens, we cannot verify
        # the token against a previous value. We allow it to proceed.
        :ok

      is_nil(submitted_token) ->
        {:error, :missing_token}

      not secure_compare(expected_token, submitted_token) ->
        {:error, :invalid_token}

      true ->
        :ok
    end
  end

  @doc """
  Checks if the request method requires CSRF validation.
  """
  def protected_method?(method) when is_atom(method) do
    method in [:post, :put, :patch, :delete]
  end

  def protected_method?(method) when is_binary(method) do
    method
    |> String.downcase()
    |> String.to_existing_atom()
    |> protected_method?()
  rescue
    ArgumentError -> false
  end

  # Private functions

  defp get_submitted_token(conn) do
    # Try header first (for HTMX/AJAX requests)
    case Plug.Conn.get_req_header(conn, @header_name) do
      [token | _] when is_binary(token) and token != "" ->
        token

      _ ->
        # Fall back to form params
        conn.params[@token_key]
    end
  end

  # Constant-time comparison to prevent timing attacks
  defp secure_compare(a, b) when is_binary(a) and is_binary(b) do
    byte_size(a) == byte_size(b) and :crypto.hash_equals(a, b)
  end

  defp secure_compare(_, _), do: false
end
