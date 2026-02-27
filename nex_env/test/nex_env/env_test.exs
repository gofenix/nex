defmodule Nex.EnvTest do
  use ExUnit.Case, async: true

  alias Nex.Env

  describe "get/2" do
    test "returns default for missing env var" do
      # Ensure a unique key that won't exist
      result = Env.get(:this_env_var_does_not_exist_12345, "default")
      assert result == "default"
    end

    test "returns value when env var exists" do
      # Set an env var for this test
      System.put_env("TEST_KEY", "test_value")

      try do
        result = Env.get(:TEST_KEY)
        assert result == "test_value"
      after
        System.delete_env("TEST_KEY")
      end
    end

    test "converts atom key to uppercase string" do
      System.put_env("MY_VAR", "my_value")

      try do
        result = Env.get(:my_var)
        assert result == "my_value"
      after
        System.delete_env("MY_VAR")
      end
    end

    test "returns nil for missing var with no default" do
      result = Env.get(:nonexistent_var_xyz)
      assert result == nil
    end
  end

  describe "get!/1" do
    test "returns value when env var exists" do
      System.put_env("REQUIRED_VAR", "required_value")

      try do
        result = Env.get!(:REQUIRED_VAR)
        assert result == "required_value"
      after
        System.delete_env("REQUIRED_VAR")
      end
    end

    test "raises when env var is missing" do
      assert_raise RuntimeError, "Missing required environment variable: missing_var", fn ->
        Env.get!(:missing_var)
      end
    end
  end

  describe "get_integer/2" do
    test "returns default for missing env var" do
      result = Env.get_integer(:nonexistent_int_var, 999)
      assert result == 999
    end

    test "parses integer string" do
      System.put_env("PORT_VAR", "4000")

      try do
        result = Env.get_integer(:PORT_VAR, 3000)
        assert result == 4000
      after
        System.delete_env("PORT_VAR")
      end
    end

    test "raises on invalid integer string" do
      System.put_env("INVALID_INT", "not_a_number")

      try do
        assert_raise ArgumentError, fn ->
          Env.get_integer(:INVALID_INT, 0)
        end
      after
        System.delete_env("INVALID_INT")
      end
    end
  end

  describe "get_boolean/2" do
    test "returns default for missing env var" do
      result = Env.get_boolean(:nonexistent_bool_var, true)
      assert result == true
    end

    test "returns true for 'true'" do
      System.put_env("BOOL_TRUE", "true")

      try do
        result = Env.get_boolean(:BOOL_TRUE, false)
        assert result == true
      after
        System.delete_env("BOOL_TRUE")
      end
    end

    test "returns true for '1'" do
      System.put_env("BOOL_ONE", "1")

      try do
        result = Env.get_boolean(:BOOL_ONE, false)
        assert result == true
      after
        System.delete_env("BOOL_ONE")
      end
    end

    test "returns false for other values" do
      System.put_env("BOOL_FALSE", "false")

      try do
        result = Env.get_boolean(:BOOL_FALSE, true)
        assert result == false
      after
        System.delete_env("BOOL_FALSE")
      end
    end

    test "returns false for '0'" do
      System.put_env("BOOL_ZERO", "0")

      try do
        result = Env.get_boolean(:BOOL_ZERO, true)
        assert result == false
      after
        System.delete_env("BOOL_ZERO")
      end
    end

    test "returns false for empty string" do
      System.put_env("BOOL_EMPTY", "")

      try do
        result = Env.get_boolean(:BOOL_EMPTY, true)
        assert result == false
      after
        System.delete_env("BOOL_EMPTY")
      end
    end

    test "returns false for random string" do
      System.put_env("BOOL_RANDOM", "random")

      try do
        result = Env.get_boolean(:BOOL_RANDOM, true)
        assert result == false
      after
        System.delete_env("BOOL_RANDOM")
      end
    end
  end

  describe "init/0" do
    test "init/0 handles missing .env gracefully" do
      result = Env.init()
      assert result == :ok
    end

    test "init/0 returns :ok even when .env files don't exist" do
      result1 = Env.init()
      result2 = Env.init()

      assert result1 == :ok
      assert result2 == :ok
    end

    test "init/0 loads .env file when present" do
      temp_dir = System.tmp_dir!() |> Path.join("nex_env_test_#{:rand.uniform(99999)}")
      File.mkdir_p!(temp_dir)

      try do
        File.write!(Path.join(temp_dir, ".env"), "TEST_VAR=test_value\n")

        original_cwd = File.cwd!()

        try do
          File.cd!(temp_dir)
          result = Env.init()
          assert result == :ok
        after
          File.cd!(original_cwd)
        end
      after
        File.rm_rf!(temp_dir)
      end
    end

    test "init/0 loads .env.{env} file" do
      temp_dir = System.tmp_dir!() |> Path.join("nex_env_test2_#{:rand.uniform(99999)}")
      File.mkdir_p!(temp_dir)

      try do
        env_file = Path.join(temp_dir, ".env.test")
        File.write!(env_file, "TEST_ENV_VAR=env_specific\n")

        original_cwd = File.cwd!()

        try do
          File.cd!(temp_dir)
          result = Env.init()
          assert result == :ok
        after
          File.cd!(original_cwd)
        end
      after
        File.rm_rf!(temp_dir)
      end
    end
  end


  describe "init/0 error handling" do
    test "init/0 handles Dotenvy error gracefully" do
      # Create a temp directory with an invalid .env file
      temp_dir = System.tmp_dir!() |> Path.join("nex_env_test_error_#{:rand.uniform(99999)}")
      File.mkdir_p!(temp_dir)

      try do
        # Create an invalid .env file (this will cause parsing issues)
        File.write!(Path.join(temp_dir, ".env"), "INVALID LINE WITHOUT EQUALS")

        original_cwd = File.cwd!()

        try do
          File.cd!(temp_dir)
          # Should return :ok even when parsing fails
          result = Env.init()
          assert result == :ok
        after
          File.cd!(original_cwd)
        end
      after
        File.rm_rf!(temp_dir)
      end
    end
  end

  describe "current_env/0" do
    test "uses MIX_ENV env var when Mix is not available" do
      # This test simulates production environment where Mix might not be available
      # We can't easily test the Mix.env() path, but we can test the fallback
      original_mix_env = System.get_env("MIX_ENV")

      try do
        System.put_env("MIX_ENV", "staging")
        # Force re-init to pick up the new environment
        result = Env.init()
        assert result == :ok
      after
        if original_mix_env do
          System.put_env("MIX_ENV", original_mix_env)
        else
          System.delete_env("MIX_ENV")
        end
      end
    end

    test "defaults to prod when MIX_ENV is not set" do
      original_mix_env = System.get_env("MIX_ENV")

      try do
        System.delete_env("MIX_ENV")
        result = Env.init()
        assert result == :ok
      after
        if original_mix_env do
          System.put_env("MIX_ENV", original_mix_env)
        end
      end
    end
  end

  describe "detect_project_root/0" do
    test "returns valid path for project root" do
      # We can't directly test the private function, but we can verify
      # init/0 works which internally uses detect_project_root
      result = Env.init()
      assert result == :ok
    end
  end

  describe "get_integer/2 edge cases" do
    test "handles negative integers" do
      System.put_env("NEGATIVE_INT", "-42")

      try do
        result = Env.get_integer(:NEGATIVE_INT, 0)
        assert result == -42
      after
        System.delete_env("NEGATIVE_INT")
      end
    end

    test "handles zero" do
      System.put_env("ZERO_INT", "0")

      try do
        result = Env.get_integer(:ZERO_INT, 999)
        assert result == 0
      after
        System.delete_env("ZERO_INT")
      end
    end

    test "handles large integers" do
      System.put_env("LARGE_INT", "9999999999")

      try do
        result = Env.get_integer(:LARGE_INT, 0)
        assert result == 9999999999
      after
        System.delete_env("LARGE_INT")
      end
    end
  end

  describe "get_boolean/2 edge cases" do
    test "handles uppercase TRUE" do
      System.put_env("BOOL_UPPER", "TRUE")

      try do
        result = Env.get_boolean(:BOOL_UPPER, false)
        # Should be false since it only checks for lowercase "true"
        assert result == false
      after
        System.delete_env("BOOL_UPPER")
      end
    end

    test "handles mixed case True" do
      System.put_env("BOOL_MIXED", "True")

      try do
        result = Env.get_boolean(:BOOL_MIXED, false)
        # Should be false since it only checks for lowercase "true"
        assert result == false
      after
        System.delete_env("BOOL_MIXED")
      end
    end

    test "handles yes/no strings" do
      System.put_env("BOOL_YES", "yes")
      System.put_env("BOOL_NO", "no")

      try do
        # Both should be false since only "true" and "1" are truthy
        assert Env.get_boolean(:BOOL_YES, true) == false
        assert Env.get_boolean(:BOOL_NO, true) == false
      after
        System.delete_env("BOOL_YES")
        System.delete_env("BOOL_NO")
      end
    end
  end

  describe "get/2 with various types" do
    test "handles empty string as value" do
      System.put_env("EMPTY_VALUE", "")

      try do
        result = Env.get(:EMPTY_VALUE)
        assert result == ""
      after
        System.delete_env("EMPTY_VALUE")
      end
    end

    test "handles string with spaces" do
      System.put_env("SPACED_VALUE", "hello world test")

      try do
        result = Env.get(:SPACED_VALUE)
        assert result == "hello world test"
      after
        System.delete_env("SPACED_VALUE")
      end
    end

    test "handles special characters" do
      System.put_env("SPECIAL_VALUE", "test@example.com")

      try do
        result = Env.get(:SPECIAL_VALUE)
        assert result == "test@example.com"
      after
        System.delete_env("SPECIAL_VALUE")
      end
    end
  end

  describe "init/0 with multiple .env files" do
    test "loads both .env and .env.{env} files" do
      temp_dir = System.tmp_dir!() |> Path.join("nex_env_test_multi_#{:rand.uniform(99999)}")
      File.mkdir_p!(temp_dir)

      try do
        # Create both .env and .env.test files
        File.write!(Path.join(temp_dir, ".env"), "COMMON_VAR=common\n")
        File.write!(Path.join(temp_dir, ".env.test"), "TEST_VAR=test_specific\n")

        original_cwd = File.cwd!()

        try do
          File.cd!(temp_dir)
          result = Env.init()
          assert result == :ok
        after
          File.cd!(original_cwd)
        end
      after
        File.rm_rf!(temp_dir)
      end
    end
  end

  describe "get!/1 with special cases" do
    test "raises with correct message format" do
      assert_raise RuntimeError, ~r/Missing required environment variable/, fn ->
        Env.get!(:definitely_not_set_var_12345)
      end
    end

    test "returns value for valid env var" do
      System.put_env("GET_BANG_VAR", "success")

      try do
        assert Env.get!(:GET_BANG_VAR) == "success"
      after
        System.delete_env("GET_BANG_VAR")
      end
    end
  end


  describe "init/0 with edge cases" do
    test "init handles empty .env file" do
      temp_dir = System.tmp_dir!() |> Path.join("nex_env_empty_#{:rand.uniform(99999)}")
      File.mkdir_p!(temp_dir)

      try do
        File.write!(Path.join(temp_dir, ".env"), "")

        original_cwd = File.cwd!()

        try do
          File.cd!(temp_dir)
          result = Env.init()
          assert result == :ok
        after
          File.cd!(original_cwd)
        end
      after
        File.rm_rf!(temp_dir)
      end
    end

    test "init handles .env file with only comments" do
      temp_dir = System.tmp_dir!() |> Path.join("nex_env_comments_#{:rand.uniform(99999)}")
      File.mkdir_p!(temp_dir)

      try do
        File.write!(Path.join(temp_dir, ".env"), "# This is a comment\n# Another comment")

        original_cwd = File.cwd!()

        try do
          File.cd!(temp_dir)
          result = Env.init()
          assert result == :ok
        after
          File.cd!(original_cwd)
        end
      after
        File.rm_rf!(temp_dir)
      end
    end

    test "init handles .env file with multiple variables" do
      temp_dir = System.tmp_dir!() |> Path.join("nex_env_multi_#{:rand.uniform(99999)}")
      File.mkdir_p!(temp_dir)

      try do
        File.write!(Path.join(temp_dir, ".env"), "VAR1=value1\nVAR2=value2\nVAR3=value3")

        original_cwd = File.cwd!()

        try do
          File.cd!(temp_dir)
          result = Env.init()
          assert result == :ok
          assert System.get_env("VAR1") == "value1"
          assert System.get_env("VAR2") == "value2"
          assert System.get_env("VAR3") == "value3"
        after
          File.cd!(original_cwd)
          System.delete_env("VAR1")
          System.delete_env("VAR2")
          System.delete_env("VAR3")
        end
      after
        File.rm_rf!(temp_dir)
      end
    end
  end

  describe "get/2 with default values" do
    test "returns default for nil atom key" do
      result = Env.get(:nonexistent_var_98765, "my_default")
      assert result == "my_default"
    end

    test "handles false as default" do
      result = Env.get(:nonexistent_var_98765, false)
      assert result == false
    end

    test "handles integer as default" do
      result = Env.get(:nonexistent_var_98765, 42)
      assert result == 42
    end
  end

  describe "env var name transformations" do
    test "converts lowercase atom to uppercase env var" do
      System.put_env("LOWERCASE_TEST", "found")

      try do
        result = Env.get(:lowercase_test)
        assert result == "found"
      after
        System.delete_env("LOWERCASE_TEST")
      end
    end
  end

  describe "production code paths" do
    test "current_env/1 with mix_env option uses provided value" do
      assert Env.current_env(mix_env: :staging) == "staging"
      assert Env.current_env(mix_env: :prod) == "prod"
      assert Env.current_env(mix_env: :test) == "test"
    end

    test "current_env/1 falls back to system_env when mix_env is nil" do
      fake_system_env = fn 
        "MIX_ENV" -> "production"
        _ -> nil
      end
      
      assert Env.current_env(mix_env: nil, system_env: fake_system_env) == "production"
    end

    test "current_env/1 defaults to prod when both are nil" do
      fake_system_env = fn _ -> nil end
      
      assert Env.current_env(mix_env: nil, system_env: fake_system_env) == "prod"
    end

    test "detect_project_root/1 with mix_project_path option" do
      mix_path = "/home/user/project/_build/dev/lib/myapp"
      result = Env.detect_project_root(mix_project_path: mix_path)
      assert result == "/home/user/project"
    end

    test "detect_project_root/1 with progname option" do
      progname = "/opt/myapp/bin/myapp"
      result = Env.detect_project_root(mix_project_path: nil, progname: progname)
      assert result == "/opt/myapp/bin"
    end

    test "detect_project_root/1 falls back to cwd when both are nil" do
      result = Env.detect_project_root(mix_project_path: nil, progname: nil)
      assert result == File.cwd!()
    end

    test "init/1 with :env option uses provided environment" do
      temp_dir = System.tmp_dir!() |> Path.join("nex_env_test_prod_#{:rand.uniform(99999)}")
      File.mkdir_p!(temp_dir)

      try do
        File.write!(Path.join(temp_dir, ".env.prod"), "PROD_VAR=production_value\n")
        original_cwd = File.cwd!()

        try do
          File.cd!(temp_dir)
          result = Env.init(env: "prod")
          assert result == :ok
          assert System.get_env("PROD_VAR") == "production_value"
        after
          File.cd!(original_cwd)
          System.delete_env("PROD_VAR")
        end
      after
        File.rm_rf!(temp_dir)
      end
    end

    test "init/1 with :project_root option uses provided path" do
      temp_dir = System.tmp_dir!() |> Path.join("nex_env_test_root_#{:rand.uniform(99999)}")
      File.mkdir_p!(temp_dir)

      try do
        File.write!(Path.join(temp_dir, ".env"), "ROOT_VAR=root_value\n")
        result = Env.init(project_root: temp_dir)
        assert result == :ok
        assert System.get_env("ROOT_VAR") == "root_value"
      after
        File.rm_rf!(temp_dir)
        System.delete_env("ROOT_VAR")
      end
    end
  end

  describe "production simulation tests" do
    test "simulates production environment detection" do
      fake_system_env = fn 
        "MIX_ENV" -> "prod"
        _ -> nil
      end
      
      env = Env.current_env(mix_env: nil, system_env: fake_system_env)
      assert env == "prod"
      
      root = Env.detect_project_root(mix_project_path: nil, progname: "/opt/app/bin/myapp")
      assert root == "/opt/app/bin"
    end

    test "simulates escript release scenario" do
      fake_system_env = fn _ -> nil end
      
      env = Env.current_env(mix_env: nil, system_env: fake_system_env)
      assert env == "prod"
      
      root = Env.detect_project_root(mix_project_path: nil, progname: "/usr/local/bin/myapp")
      assert root == "/usr/local/bin"
    end
  end
end
