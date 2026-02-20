defmodule Nex.CSRF do
  @moduledoc """
  CSRF (Cross-Site Request Forgery) protection for Nex applications.

  Uses **signed tokens** via `Phoenix.Token` — cryptographically verified across
  request cycles without server-side session storage. Tokens are signed with a
  secret derived from the application's secret key base.

  ## How it works

  1. On page render (`GET`), `generate_token/0` creates a signed token and stores
     it in the process dictionary for the current request.
  2. The token is injected into `<head>` as a `<meta>` tag and into every form
     automatically by `Nex.Handler`.
  3. On `POST/PUT/PATCH/DELETE`, `validate/1` verifies the submitted token's
     cryptographic signature — no session lookup needed.

  ## Usage

  Everything is automatic. You do not need to call these functions manually.
  The framework handles injection and validation transparently.
  """

  require Logger

  @token_key "_csrf_token"
  @header_name "x-csrf-token"
  @salt "nex.csrf"
  @max_age 86_400

  @doc """
  Generates a new signed CSRF token for the current request.

  The token is a `Phoenix.Token`-signed value containing a random nonce.
  It is stored in the process dictionary so helpers (`csrf_input_tag/0` etc.)
  can retrieve it without regenerating.
  """
  def generate_token do
    nonce = :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
    token = Phoenix.Token.sign(endpoint_or_secret(), @salt, nonce)
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
  def csrf_input_tag do
    token = get_token()
    {:safe, ~s(<input type="hidden" name="#{@token_key}" value="#{token}" />)}
  end

  @doc """
  Returns a JSON string for hx-headers attribute with CSRF token.
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
  Validates the CSRF token submitted with a request.

  Verifies the cryptographic signature of the token using `Phoenix.Token.verify/4`.
  Returns `:ok` if valid, `{:error, reason}` otherwise.
  """
  def validate(conn) do
    submitted_token = get_submitted_token(conn)

    if is_nil(submitted_token) or submitted_token == "" do
      {:error, :missing_token}
    else
      case Phoenix.Token.verify(endpoint_or_secret(), @salt, submitted_token,
             max_age: @max_age
           ) do
        {:ok, _nonce} ->
          :ok

        {:error, :expired} ->
          Logger.debug("[Nex.CSRF] Token expired")
          {:error, :invalid_token}

        {:error, reason} ->
          Logger.debug("[Nex.CSRF] Token invalid: #{inspect(reason)}")
          {:error, :invalid_token}
      end
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
    case Plug.Conn.get_req_header(conn, @header_name) do
      [token | _] when is_binary(token) and token != "" ->
        token

      _ ->
        conn.params[@token_key]
    end
  end

  # Returns the secret key base for signing tokens.
  # Reads SECRET_KEY_BASE env var, falls back to a deterministic dev secret.
  # In production, SECRET_KEY_BASE must be set to a strong random value.
  defp endpoint_or_secret do
    case System.get_env("SECRET_KEY_BASE") do
      nil ->
        Logger.warning(
          "[Nex.CSRF] SECRET_KEY_BASE not set — using insecure dev default. " <>
            "Set SECRET_KEY_BASE in production!"
        )

        "nex_dev_secret_key_base_do_not_use_in_production_replace_with_64_char_random_string"

      secret ->
        secret
    end
  end
end
