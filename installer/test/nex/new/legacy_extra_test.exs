defmodule Nex.New.LegacyExtraTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Nex.New.{Legacy, Options}

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "nex_new_legacy_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)

    on_exit(fn ->
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  describe "Legacy.normalize_starter/1" do
    test "nil defaults to :basic" do
      assert Legacy.normalize_starter(nil) == :basic
    end

    test "\"basic\" becomes :basic" do
      assert Legacy.normalize_starter("basic") == :basic
    end

    test "\"saas\" becomes :saas" do
      assert Legacy.normalize_starter("saas") == :saas
    end

    test "unknown starter raises Mix.Error" do
      assert_raise Mix.Error, ~r/Unknown starter/, fn ->
        Legacy.normalize_starter("enterprise")
      end
    end
  end

  describe "Legacy.normalize_frontend/1" do
    test "nil defaults to :htmx" do
      assert Legacy.normalize_frontend(nil) == :htmx
    end

    test "\"htmx\" becomes :htmx" do
      assert Legacy.normalize_frontend("htmx") == :htmx
    end

    test "\"datastar\" becomes :datastar" do
      assert Legacy.normalize_frontend("datastar") == :datastar
    end

    test "unknown frontend raises Mix.Error" do
      assert_raise Mix.Error, ~r/Unknown frontend/, fn ->
        Legacy.normalize_frontend("react")
      end
    end
  end

  describe "Legacy.starter_label/1" do
    test ":basic returns empty string" do
      assert Legacy.starter_label(:basic) == ""
    end

    test ":saas returns (starter: saas)" do
      assert Legacy.starter_label(:saas) == " (starter: saas)"
    end
  end

  describe "Legacy.frontend_label/1" do
    test ":htmx returns empty string" do
      assert Legacy.frontend_label(:htmx) == ""
    end

    test ":datastar returns (frontend: datastar)" do
      assert Legacy.frontend_label(:datastar) == " (frontend: datastar)"
    end
  end

  describe "Legacy.skip_deps_install?/0" do
    test "returns true when NEX_NEW_SKIP_DEPS=1" do
      System.put_env("NEX_NEW_SKIP_DEPS", "1")
      assert Legacy.skip_deps_install?() == true
    after
      System.delete_env("NEX_NEW_SKIP_DEPS")
    end

    test "returns false when NEX_NEW_SKIP_DEPS is not set" do
      System.delete_env("NEX_NEW_SKIP_DEPS")
      assert Legacy.skip_deps_install?() == false
    end
  end

  describe "Legacy.valid_name?/1" do
    test "accepts valid lowercase names" do
      assert Legacy.valid_name?("my_app")
      assert Legacy.valid_name?("app")
      assert Legacy.valid_name?("app123")
    end

    test "rejects uppercase names" do
      refute Legacy.valid_name?("MyApp")
      refute Legacy.valid_name?("APP")
    end

    test "rejects names starting with digits" do
      refute Legacy.valid_name?("123_app")
    end

    test "rejects names with special characters" do
      refute Legacy.valid_name?("my-app")
      refute Legacy.valid_name?("my app")
      refute Legacy.valid_name?("my@app")
    end

    test "rejects reserved names" do
      refute Legacy.valid_name?("elixir")
      refute Legacy.valid_name?("mix")
      refute Legacy.valid_name?("nex")
    end

    test "rejects empty strings" do
      refute Legacy.valid_name?("")
    end
  end

  describe "Legacy.success_message/3" do
    test "basic with deps installed" do
      msg = Legacy.success_message("myapp", :basic, true)
      assert msg =~ "Project created successfully"
      assert msg =~ "cd myapp"
      assert msg =~ "mix nex.dev"
    end

    test "basic without deps installed" do
      msg = Legacy.success_message("myapp", :basic, false)
      assert msg =~ "Dependencies were not installed"
      assert msg =~ "mix deps.get"
    end

    test "saas with deps installed" do
      msg = Legacy.success_message("saasapp", :saas, true)
      assert msg =~ "SaaS starter created successfully"
      assert msg =~ "SQLite"
    end

    test "saas without deps installed" do
      msg = Legacy.success_message("saasapp", :saas, false)
      assert msg =~ "Dependencies were not installed"
    end
  end

  describe "Legacy.run/1 error paths" do
    test "empty args raises asking for project name" do
      assert_raise Mix.Error, ~r/Expected project name/, fn ->
        Legacy.run([])
      end
    end

    test "invalid name raises validation error", %{tmp_dir: tmp_dir} do
      assert_raise Mix.Error, ~r/Project name must start with a letter/, fn ->
        capture_io(fn ->
          Legacy.run(["123_invalid", "--path", tmp_dir])
        end)
      end
    end
  end

  describe "Options.parse!/1 error paths" do
    test "missing project name raises" do
      assert_raise Mix.Error, ~r/Expected project name/, fn ->
        Options.parse!([])
      end
    end

    test "invalid project name raises" do
      assert_raise Mix.Error, ~r/Project name must start with a letter/, fn ->
        Options.parse!(["123Bad"])
      end
    end

    test "unknown starter raises" do
      assert_raise Mix.Error, ~r/Unknown starter/, fn ->
        Options.parse!(["myapp", "--starter", "nonexistent"])
      end
    end

    test "unknown frontend raises" do
      assert_raise Mix.Error, ~r/Unknown frontend/, fn ->
        Options.parse!(["myapp", "--frontend", "nonexistent"])
      end
    end

    test "directory already exists raises", %{tmp_dir: tmp_dir} do
      existing = Path.join(tmp_dir, "existing")
      File.mkdir_p!(existing)

      assert_raise Mix.Error, ~r/Path .* already exists/, fn ->
        Options.parse!(["existing", "--path", tmp_dir])
      end
    end
  end

  describe "Options.parse!/1 success paths" do
    test "parses valid app with defaults", %{tmp_dir: tmp_dir} do
      result = Options.parse!(["testapp", "--path", tmp_dir])
      assert result.name == "testapp"
      assert result.starter == :basic
      assert result.frontend == :htmx
      assert result.assigns.app_name == "testapp"
      assert result.assigns.module_name == "Testapp"
    end

    test "parses saas starter", %{tmp_dir: tmp_dir} do
      result = Options.parse!(["mysaas", "--starter", "saas", "--path", tmp_dir])
      assert result.starter == :saas
    end

    test "parses datastar frontend", %{tmp_dir: tmp_dir} do
      result = Options.parse!(["dsapp", "--frontend", "datastar", "--path", tmp_dir])
      assert result.frontend == :datastar
    end
  end

  describe "Options delegated functions" do
    test "starter_label delegates to Legacy" do
      assert Options.starter_label(:basic) == Legacy.starter_label(:basic)
    end

    test "frontend_label delegates to Legacy" do
      assert Options.frontend_label(:htmx) == Legacy.frontend_label(:htmx)
    end

    test "skip_deps_install? delegates to Legacy" do
      assert is_boolean(Options.skip_deps_install?())
    end
  end

  describe "Regression: bug fixes" do
    test "existing non-directory file at path is detected" do
      tmp_dir = Path.join(System.tmp_dir!(), "nex_new_file_#{System.unique_integer([:positive])}")
      File.mkdir_p!(tmp_dir)
      existing_file = Path.join(tmp_dir, "myapp")
      File.write!(existing_file, "i am a regular file")

      on_exit(fn -> File.rm_rf!(tmp_dir) end)

      assert_raise Mix.Error, ~r/Path .* already exists/, fn ->
        capture_io(fn ->
          Legacy.run(["myapp", "--path", tmp_dir])
        end)
      end
    end

    test "unknown CLI options raise instead of being silently ignored", %{tmp_dir: tmp_dir} do
      assert_raise Mix.Error, ~r/Unknown option/, fn ->
        Options.parse!(["myapp", "--statrer", "saas", "--path", tmp_dir])
      end
    end

    test "success_message with explicit path shows correct cd instructions" do
      msg = Legacy.success_message("myapp", :basic, true, "/tmp")
      assert msg =~ "cd /tmp/myapp"
      refute msg =~ "cd myapp\n"
    end

    test "success_message with default path shows just app name" do
      msg = Legacy.success_message("myapp", :basic, true, ".")
      assert msg =~ "cd myapp"
    end

    test "success_message 3-arg variant still works (backward compat)" do
      msg = Legacy.success_message("myapp", :basic, true)
      assert msg =~ "cd myapp"
      assert msg =~ "Project created successfully"
    end
  end
end
