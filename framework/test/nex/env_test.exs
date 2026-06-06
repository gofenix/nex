defmodule Nex.EnvTest do
  use ExUnit.Case, async: true

  alias Nex.Env

  setup do
    # Backup and restore relevant env vars
    backups =
      [:test_key, :test_bool, :test_int, :database_url, :missing_key]
      |> Map.new(fn k -> {k, System.get_env(Atom.to_string(k) |> String.upcase())} end)

    on_exit(fn ->
      for {k, v} <- backups do
        key_str = Atom.to_string(k) |> String.upcase()

        if v do
          System.put_env(key_str, v)
        else
          System.delete_env(key_str)
        end
      end
    end)

    :ok
  end

  describe "get/2" do
    test "returns env var by atom key (uppercased)" do
      System.put_env("TEST_KEY", "hello")
      assert Env.get(:test_key) == "hello"
    end

    test "returns default when var is not set" do
      System.delete_env("MISSING_KEY")
      assert Env.get(:missing_key) == nil
      assert Env.get(:missing_key, "fallback") == "fallback"
    end
  end

  describe "get!/1" do
    test "returns value when present" do
      System.put_env("TEST_KEY", "here")
      assert Env.get!(:test_key) == "here"
    end

    test "raises when missing" do
      System.delete_env("MISSING_KEY")

      assert_raise RuntimeError,
                   "Missing required environment variable: missing_key",
                   fn -> Env.get!(:missing_key) end
    end
  end

  describe "get_integer/3" do
    test "parses integer from env" do
      System.put_env("TEST_INT", "42")
      assert Env.get_integer(:test_int, 0) == 42
    end

    test "returns default when missing" do
      System.delete_env("MISSING_KEY")
      assert Env.get_integer(:missing_key, 99) == 99
    end
  end

  describe "get_boolean/3" do
    test "parses \"true\" as true" do
      System.put_env("TEST_BOOL", "true")
      assert Env.get_boolean(:test_bool, false) == true
    end

    test "parses \"1\" as true" do
      System.put_env("TEST_BOOL", "1")
      assert Env.get_boolean(:test_bool, false) == true
    end

    test "treats other values as false" do
      System.put_env("TEST_BOOL", "false")
      assert Env.get_boolean(:test_bool, true) == false

      System.put_env("TEST_BOOL", "no")
      assert Env.get_boolean(:test_bool, true) == false
    end

    test "returns default when missing" do
      System.delete_env("MISSING_KEY")
      assert Env.get_boolean(:missing_key, true) == true
      assert Env.get_boolean(:missing_key, false) == false
    end
  end

  describe "current_env/1" do
    test "uses provided mix_env option" do
      assert Env.current_env(mix_env: :dev) == "dev"
      assert Env.current_env(mix_env: :test) == "test"
      assert Env.current_env(mix_env: :prod) == "prod"
    end

    test "falls back to system_env function when mix_env is nil" do
      system_env = fn "MIX_ENV" -> "staging" end
      assert Env.current_env(mix_env: nil, system_env: system_env) == "staging"
    end

    test "defaults to prod when nothing is set" do
      system_env = fn _ -> nil end
      assert Env.current_env(mix_env: nil, system_env: system_env) == "prod"
    end
  end

  describe "detect_project_root/1" do
    test "uses mix_project_path option by walking up 4 dirs" do
      # If app_path = /a/b/c/_build/dev/lib/my_app, we walk up 4 to /a/b/c
      path = Path.join(["tmp", "a", "b", "c", "_build", "dev", "lib", "my_app"])
      result = Env.detect_project_root(mix_project_path: path, progname: nil)

      # walk up 4: my_app -> lib -> dev -> _build -> c
      assert String.ends_with?(result, Path.join(["tmp", "a", "b", "c"]))
    end

    test "uses progname when mix_project_path is nil" do
      # Expand the progname path and take its dirname
      progname = '/usr/local/bin/my_app'

      result = Env.detect_project_root(mix_project_path: nil, progname: progname)
      assert String.ends_with?(result, Path.join(["usr", "local", "bin"]))
    end

    test "falls back to cwd when both are nil" do
      result = Env.detect_project_root(mix_project_path: nil, progname: nil)
      assert result == File.cwd!()
    end
  end

  describe "init/1" do
    test "loads env vars from a temp .env file" do
      tmp_dir = System.tmp_dir!() |> Path.join("nex_env_test_#{:rand.uniform(99_999)}")
      File.mkdir_p!(tmp_dir)

      env_file = Path.join(tmp_dir, ".env")
      File.write!(env_file, "NEX_TEST_VAR=loaded_value\n")

      System.delete_env("NEX_TEST_VAR")
      Env.init(project_root: tmp_dir, env: "test")

      assert System.get_env("NEX_TEST_VAR") == "loaded_value"

      on_exit(fn ->
        System.delete_env("NEX_TEST_VAR")
        File.rm_rf!(tmp_dir)
      end)
    end

    test "loads both .env and .env.<env> files" do
      tmp_dir = System.tmp_dir!() |> Path.join("nex_env_test_#{:rand.uniform(99_999)}")
      File.mkdir_p!(tmp_dir)

      File.write!(Path.join(tmp_dir, ".env"), "NEX_BASE=base_value\n")
      File.write!(Path.join(tmp_dir, ".env.test"), "NEX_OVERRIDE=override_value\n")

      System.delete_env("NEX_BASE")
      System.delete_env("NEX_OVERRIDE")

      Env.init(project_root: tmp_dir, env: "test")

      assert System.get_env("NEX_BASE") == "base_value"
      assert System.get_env("NEX_OVERRIDE") == "override_value"

      on_exit(fn ->
        System.delete_env("NEX_BASE")
        System.delete_env("NEX_OVERRIDE")
        File.rm_rf!(tmp_dir)
      end)
    end

    test "returns :ok when no .env files exist" do
      tmp_dir = System.tmp_dir!() |> Path.join("nex_env_empty_#{:rand.uniform(99_999)}")
      File.mkdir_p!(tmp_dir)

      assert Env.init(project_root: tmp_dir, env: "nonexistent") == :ok

      File.rm_rf!(tmp_dir)
    end
  end
end
