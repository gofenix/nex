defmodule Nex.ConfigTest do
  use ExUnit.Case, async: false

  alias Nex.Config

  setup do
    original_app = Application.get_env(:nex_core, :app_module)
    original_src = Application.get_env(:nex_core, :src_path)
    original_env = Application.get_env(:nex_core, :env)
    original_error = Application.get_env(:nex_core, :error_page_module)

    on_exit(fn ->
      restore_env(:app_module, original_app)
      restore_env(:src_path, original_src)
      restore_env(:env, original_env)
      restore_env(:error_page_module, original_error)
    end)

    :ok
  end

  defp restore_env(key, nil), do: Application.delete_env(:nex_core, key)
  defp restore_env(key, val), do: Application.put_env(:nex_core, key, val)

  describe "app_module/0" do
    test "returns normalized module name from string config" do
      Application.put_env(:nex_core, :app_module, "MyApp")
      assert Config.app_module() == "MyApp"
    end

    test "returns normalized module name from atom config" do
      Application.put_env(:nex_core, :app_module, MyAppTest)
      assert Config.app_module() == "MyAppTest"
    end

    test "falls back to \"MyApp\" when unset" do
      Application.delete_env(:nex_core, :app_module)
      assert Config.app_module() == "MyApp"
    end
  end

  describe "src_path/0" do
    test "returns configured src path" do
      Application.put_env(:nex_core, :src_path, "custom_src")
      assert Config.src_path() == "custom_src"
    end

    test "defaults to \"src\" when unset" do
      Application.delete_env(:nex_core, :src_path)
      assert Config.src_path() == "src"
    end
  end

  describe "dev?/0" do
    test "returns true when env is :dev" do
      Application.put_env(:nex_core, :env, :dev)
      assert Config.dev?() == true
    end

    test "returns false when env is :test or :prod" do
      Application.put_env(:nex_core, :env, :test)
      assert Config.dev?() == false

      Application.put_env(:nex_core, :env, :prod)
      assert Config.dev?() == false
    end

    test "defaults to false (prod)" do
      Application.delete_env(:nex_core, :env)
      assert Config.dev?() == false
    end
  end

  describe "error_page_module/0" do
    test "returns configured module" do
      Application.put_env(:nex_core, :error_page_module, MyErrorModule)
      assert Config.error_page_module() == MyErrorModule
    end

    test "returns nil when unset" do
      Application.delete_env(:nex_core, :error_page_module)
      assert Config.error_page_module() == nil
    end
  end
end
