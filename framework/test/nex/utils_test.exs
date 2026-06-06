defmodule Nex.UtilsTest do
  use ExUnit.Case, async: true

  alias Nex.Utils

  describe "safe_to_existing_atom/1" do
    test "returns {:ok, atom} for existing module atom string" do
      assert Utils.safe_to_existing_atom("Elixir.Nex") == {:ok, Nex}
      assert Utils.safe_to_existing_atom("Elixir.String") == {:ok, String}
    end

    test "returns {:ok, atom} for plain existing atoms" do
      assert Utils.safe_to_existing_atom("ok") == {:ok, :ok}
    end

    test "returns :error for nonexistent atom string" do
      assert Utils.safe_to_existing_atom("ThisAtomDefinitelyDoesNotExistXYZ123") == :error
    end
  end

  describe "normalize_module_name/1" do
    test "handles module atoms" do
      assert Utils.normalize_module_name(Nex.Utils) == "Nex.Utils"
      assert Utils.normalize_module_name(String) == "String"
    end

    test "handles binary strings with Elixir. prefix" do
      assert Utils.normalize_module_name("Elixir.MyApp.Pages.Index") == "MyApp.Pages.Index"
    end

    test "handles binary strings without Elixir. prefix" do
      assert Utils.normalize_module_name("MyApp.Pages.Index") == "MyApp.Pages.Index"
    end
  end

  describe "safe_to_existing_module/1" do
    test "returns {:ok, module} for loaded module string" do
      assert Utils.safe_to_existing_module("Nex.Handler") == {:ok, Nex.Handler}
      assert Utils.safe_to_existing_module(Nex.Handler) == {:ok, Nex.Handler}
    end

    test "returns :error for nonexistent module" do
      assert Utils.safe_to_existing_module("Totally.Fake.Module.ZZZ") == :error
    end

    test "returns :error for nonexistent atom string" do
      assert Utils.safe_to_existing_module("FakeModuleXYZ") == :error
    end
  end

  describe "generate_token/1" do
    test "generates URL-safe base64 token" do
      token = Utils.generate_token(24)
      assert is_binary(token)
      assert byte_size(token) > 20
      # URL-safe base64 uses no padding
      refute token =~ "="
    end

    test "generates unique tokens" do
      assert Utils.generate_token() != Utils.generate_token()
    end
  end

  describe "generate_hex/1" do
    test "generates lowercase hex string of proper length" do
      hex = Utils.generate_hex(16)
      assert is_binary(hex)
      assert byte_size(hex) == 32
      assert hex =~ ~r/^[0-9a-f]+$/
    end
  end
end
