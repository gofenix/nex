defmodule Nex.CSRFTest do
  use ExUnit.Case, async: true
  alias Nex.CSRF

  setup do
    # Clear process state before each test
    Process.delete(:csrf_token)
    :ok
  end

  describe "generate_token/0" do
    test "generates a token and stores in process" do
      token = CSRF.generate_token()

      assert is_binary(token)
      assert Process.get(:csrf_token) == token
    end

    test "generates different tokens each time" do
      token1 = CSRF.generate_token()
      # Clear process state
      Process.delete(:csrf_token)
      token2 = CSRF.generate_token()

      assert token1 != token2
    end
  end

  describe "get_token/0" do
    test "returns existing token if present" do
      CSRF.generate_token()
      existing = Process.get(:csrf_token)

      assert CSRF.get_token() == existing
    end

    test "generates new token if none exists" do
      assert is_binary(CSRF.get_token())
    end
  end

  describe "csrf_input_tag/0" do
    test "returns hidden input tag" do
      CSRF.generate_token()
      token = Process.get(:csrf_token)

      tag = CSRF.csrf_input_tag()

      assert tag == {:safe, ~s(<input type="hidden" name="_csrf_token" value="#{token}" />)}
    end
  end

  describe "hx_headers/0" do
    test "returns JSON with CSRF header" do
      CSRF.generate_token()
      token = Process.get(:csrf_token)

      headers = CSRF.hx_headers()

      assert headers == ~s({"x-csrf-token": "#{token}"})
    end
  end

  describe "meta_tag/0" do
    test "returns meta tag" do
      CSRF.generate_token()
      token = Process.get(:csrf_token)

      tag = CSRF.meta_tag()

      assert tag == {:safe, ~s(<meta name="csrf-token" content="#{token}" />)}
    end
  end

  describe "validate/1" do
    test "returns :ok for valid token" do
      token = CSRF.generate_token()

      conn = %Plug.Conn{
        req_headers: [{"x-csrf-token", token}],
        params: %{"_csrf_token" => token}
      }

      assert CSRF.validate(conn) == :ok
    end

    test "returns error for missing token" do
      conn = %Plug.Conn{
        req_headers: [],
        params: %{}
      }

      assert CSRF.validate(conn) == {:error, :missing_token}
    end

    test "returns error for empty token" do
      conn = %Plug.Conn{
        req_headers: [{"x-csrf-token", ""}],
        params: %{}
      }

      assert CSRF.validate(conn) == {:error, :missing_token}
    end

    test "returns error for invalid token" do
      conn = %Plug.Conn{
        req_headers: [{"x-csrf-token", "invalid-token"}],
        params: %{}
      }

      assert CSRF.validate(conn) == {:error, :invalid_token}
    end

    test "accepts token from params" do
      token = CSRF.generate_token()

      conn = %Plug.Conn{
        req_headers: [],
        params: %{"_csrf_token" => token}
      }

      assert CSRF.validate(conn) == :ok
    end

    test "accepts token from header" do
      token = CSRF.generate_token()

      conn = %Plug.Conn{
        req_headers: [{"x-csrf-token", token}],
        params: %{}
      }

      assert CSRF.validate(conn) == :ok
    end

    test "header takes precedence over params" do
      token = CSRF.generate_token()

      conn = %Plug.Conn{
        req_headers: [{"x-csrf-token", token}],
        params: %{"_csrf_token" => "wrong-token"}
      }

      assert CSRF.validate(conn) == :ok
    end
  end

  describe "protected_method?/1" do
    test "returns true for post" do
      assert CSRF.protected_method?("post") == true
      assert CSRF.protected_method?(:post) == true
    end

    test "returns true for put" do
      assert CSRF.protected_method?("put") == true
      assert CSRF.protected_method?(:put) == true
    end

    test "returns true for patch" do
      assert CSRF.protected_method?("patch") == true
      assert CSRF.protected_method?(:patch) == true
    end

    test "returns true for delete" do
      assert CSRF.protected_method?("delete") == true
      assert CSRF.protected_method?(:delete) == true
    end

    test "returns false for get" do
      assert CSRF.protected_method?("get") == false
      assert CSRF.protected_method?(:get) == false
    end

    test "returns false for unknown methods" do
      assert CSRF.protected_method?("unknown") == false
    end

    test "handles uppercase methods" do
      assert CSRF.protected_method?("POST") == true
      assert CSRF.protected_method?("GET") == false
    end
  end
end
