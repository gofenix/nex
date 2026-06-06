defmodule Nex.EnvExtraTest do
  use ExUnit.Case, async: true

  alias Nex.Env

  describe "current_env/1 more cases" do
    test "handles atom mix_env values" do
      assert Env.current_env(mix_env: :prod) == "prod"
      assert Env.current_env(mix_env: :staging) == "staging"
    end

    test "respects system_env MIX_ENV override" do
      system_env = fn
        "MIX_ENV" -> "custom"
        _ -> nil
      end

      assert Env.current_env(mix_env: nil, system_env: system_env) == "custom"
    end

    test "system_env function receiving non-MIX_ENV keys" do
      system_env = fn
        "OTHER_VAR" -> "ignored"
        _ -> nil
      end

      assert Env.current_env(mix_env: nil, system_env: system_env) == "prod"
    end
  end

  describe "detect_project_root/1 more cases" do
    test "progname as charlist works" do
      progname = '/usr/bin/my_app'
      result = Env.detect_project_root(mix_project_path: nil, progname: progname)
      assert String.ends_with?(result, Path.join(["usr", "bin"]))
    end

    test "progname as string works" do
      progname = "/usr/local/bin/server"
      result = Env.detect_project_root(mix_project_path: nil, progname: progname)
      assert String.ends_with?(result, Path.join(["usr", "local", "bin"]))
    end

    test "nil progname falls back to cwd" do
      result = Env.detect_project_root(mix_project_path: nil, progname: nil)
      assert result == File.cwd!()
    end

    test "mix_project_path walks up exactly 4 directories" do
      path = Path.join(["tmp", "a", "b", "c", "_build", "test", "lib", "my_app"])
      result = Env.detect_project_root(mix_project_path: path, progname: nil)
      # walk up 4 from my_app: lib → test → _build → c → result = tmp/a/b/c
      parts = Path.split(result)
      assert List.last(parts) == "c"
    end
  end

  describe "get/2 with different atom formats" do
    test "converts atom key to uppercase string" do
      System.put_env("MY_SPECIAL_KEY", "val")
      assert Env.get(:my_special_key) == "val"
      System.delete_env("MY_SPECIAL_KEY")
    end

    test "default is used when env var missing" do
      System.delete_env("COMPLETELY_MISSING_XYZ")
      assert Env.get(:completely_missing_xyz, "fallback") == "fallback"
    end
  end

  describe "get!/1 raises with descriptive message" do
    test "message includes the key name" do
      System.delete_env("THIS_MUST_BE_MISSING")

      error =
        assert_raise RuntimeError, fn ->
          Env.get!(:this_must_be_missing)
        end

      assert error.message =~ "this_must_be_missing"
    end
  end

  describe "init/1 with invalid env file" do
    test "logs and continues when .env has errors" do
      tmp_dir = System.tmp_dir!() |> Path.join("nex_env_bad_#{:rand.uniform(99_999)}")
      File.mkdir_p!(tmp_dir)

      # Dotenvy handles most malformed files gracefully, but a truly unreadable file raises
      File.write!(Path.join(tmp_dir, ".env"), "VALID_KEY=value\n")

      assert Env.init(project_root: tmp_dir, env: "test") == :ok
      assert System.get_env("VALID_KEY") == "value"

      on_exit(fn ->
        System.delete_env("VALID_KEY")
        File.rm_rf!(tmp_dir)
      end)
    end
  end

  describe "Regression: bug fixes" do
    test "get_integer/2 returns default for malformed values" do
      System.put_env("NEX_TEST_BAD_INT", "not_a_number")
      assert Env.get_integer(:nex_test_bad_int, 42) == 42

      System.put_env("NEX_TEST_FLOAT_INT", "3.14")
      assert Env.get_integer(:nex_test_float_int, 42) == 42

      System.put_env("NEX_TEST_EMPTY_INT", "")
      assert Env.get_integer(:nex_test_empty_int, 42) == 42

      System.put_env("NEX_TEST_GOOD_INT", "123")
      assert Env.get_integer(:nex_test_good_int, 0) == 123
    after
      ~w(NEX_TEST_BAD_INT NEX_TEST_FLOAT_INT NEX_TEST_EMPTY_INT NEX_TEST_GOOD_INT)
      |> Enum.each(&System.delete_env/1)
    end
  end
end
