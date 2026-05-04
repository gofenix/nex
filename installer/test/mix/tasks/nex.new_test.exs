defmodule Mix.Tasks.Nex.NewTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    original_skip = System.get_env("NEX_NEW_SKIP_DEPS")
    System.put_env("NEX_NEW_SKIP_DEPS", "1")
    Mix.Task.reenable("nex.new")

    tmp_dir = Path.join(System.tmp_dir!(), "nex_new_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(tmp_dir)

    on_exit(fn ->
      restore_env("NEX_NEW_SKIP_DEPS", original_skip)
      File.rm_rf!(tmp_dir)
    end)

    {:ok, tmp_dir: tmp_dir}
  end

  test "generates the basic starter by default", %{tmp_dir: tmp_dir} do
    project_path = generate_project(tmp_dir, "basic_app")

    assert File.exists?(Path.join(project_path, "src/pages/index.ex"))
    assert File.exists?(Path.join(project_path, "src/pages/_app.ex"))
    assert File.exists?(Path.join(project_path, "src/pages/_document.ex"))
    assert File.exists?(Path.join(project_path, "src/api/hello.ex"))
    refute File.exists?(Path.join(project_path, "src/layouts.ex"))
    refute File.exists?(Path.join(project_path, "src/pages/dashboard.ex"))
    refute File.exists?(Path.join(project_path, "db"))
    assert_ai_onboarding_files(project_path)

    mix_exs = File.read!(Path.join(project_path, "mix.exs"))
    assert mix_exs =~ "{:nex_core,"
    refute mix_exs =~ "{:nex_base,"

    doc = File.read!(Path.join(project_path, "src/pages/_document.ex"))
    assert doc =~ "BasicApp.Pages.Document"
    assert doc =~ "htmx.org"

    readme = File.read!(Path.join(project_path, "README.md"))
    assert readme =~ "_document.ex"
    assert readme =~ "_app.ex"
    assert readme =~ ".agents/skills/nex-project/SKILL.md"
    refute readme =~ "src/layouts.ex"

    agents = File.read!(Path.join(project_path, "AGENTS.md"))
    assert agents =~ ".agents/skills/nex-project/SKILL.md"
    refute agents =~ "Critical Anti-Patterns"

    skill = File.read!(Path.join(project_path, ".agents/skills/nex-project/SKILL.md"))
    assert skill =~ "name: nex-project"
    assert skill =~ "Nex.Req"
    assert skill =~ "req.body"
  end

  test "generates the basic starter with datastar frontend", %{tmp_dir: tmp_dir} do
    project_path = generate_project(tmp_dir, "ds_app", ["--frontend", "datastar"])

    assert File.exists?(Path.join(project_path, "src/pages/_app.ex"))
    assert File.exists?(Path.join(project_path, "src/pages/_document.ex"))
    assert File.exists?(Path.join(project_path, "src/api/counter.ex"))
    refute File.exists?(Path.join(project_path, "src/layouts.ex"))
    assert_ai_onboarding_files(project_path)

    doc = File.read!(Path.join(project_path, "src/pages/_document.ex"))
    assert doc =~ "datastar"
    refute doc =~ "htmx"

    index = File.read!(Path.join(project_path, "src/pages/index.ex"))
    assert index =~ "data-signals"

    readme = File.read!(Path.join(project_path, "README.md"))
    assert readme =~ "_document.ex"
    assert readme =~ "_app.ex"
    assert readme =~ ".agents/skills/nex-project/SKILL.md"
    refute readme =~ "src/layouts.ex"
  end

  test "generates the saas starter with auth, data, and req-based actions", %{tmp_dir: tmp_dir} do
    project_path = generate_project(tmp_dir, "saas_app", ["--starter", "saas"])

    assert File.exists?(Path.join(project_path, "db/.gitkeep"))
    assert File.exists?(Path.join(project_path, "src/accounts.ex"))
    assert File.exists?(Path.join(project_path, "src/data.ex"))
    assert File.exists?(Path.join(project_path, "src/workspace.ex"))
    assert File.exists?(Path.join(project_path, "src/pages/dashboard.ex"))
    assert File.exists?(Path.join(project_path, "src/plugs/require_auth.ex"))
    assert File.exists?(Path.join(project_path, "src/api/health.ex"))
    assert_ai_onboarding_files(project_path)

    mix_exs = File.read!(Path.join(project_path, "mix.exs"))
    assert mix_exs =~ "{:nex_base,"
    assert mix_exs =~ "{:nex_env,"
    assert mix_exs =~ "{:ecto_sqlite3,"
    assert mix_exs =~ "{:pbkdf2_elixir,"

    application = File.read!(Path.join(project_path, "src/application.ex"))
    assert application =~ "Application.put_env(:nex_core, :plugs, ["
    assert application =~ "NexBase.init("

    dashboard = File.read!(Path.join(project_path, "src/pages/dashboard.ex"))
    assert dashboard =~ "hx-post=\"/dashboard/create_project\""
    assert dashboard =~ "def create_project(req) do"
    assert dashboard =~ "def archive_project(req) do"
    assert dashboard =~ "name=\"project_id\""
    assert dashboard =~ "req.body[\"project_id\"]"

    signup = File.read!(Path.join(project_path, "src/pages/signup.ex"))
    assert signup =~ "def create_account(req) do"
    assert signup =~ "Accounts.register_user(req.body)"

    flash_component = File.read!(Path.join(project_path, "src/components/flash.ex"))
    assert flash_component =~ "Map.put(assigns, :flash, flash)"
    refute flash_component =~ "assign(assigns, :flash"

    layouts = File.read!(Path.join(project_path, "src/pages/_app.ex"))
    assert layouts =~ ":if={@current_user}"
    refute layouts =~ "<%= if"

    document = File.read!(Path.join(project_path, "src/pages/_document.ex"))
    assert document =~ "<!DOCTYPE html>"
    assert document =~ "Pages.Document"

    agents = File.read!(Path.join(project_path, "AGENTS.md"))
    assert agents =~ ".agents/skills/nex-project/SKILL.md"
    refute agents =~ "def save(req) do"
    refute agents =~ "single source of truth"

    skill = File.read!(Path.join(project_path, ".agents/skills/nex-project/SKILL.md"))
    assert skill =~ "def save(req) do"
    assert skill =~ "name = req.body[\"name\"]"
    assert skill =~ "layout, do: :none"

    env_example = File.read!(Path.join(project_path, ".env.example"))
    assert env_example =~ "DATABASE_URL=sqlite://db/saas_app_dev.db"
  end

  test "rejects unknown starters", %{tmp_dir: tmp_dir} do
    assert_raise Mix.Error, ~r/Unknown starter/, fn ->
      capture_io(fn ->
        Mix.Tasks.Nex.New.run(["bad_app", "--starter", "unknown", "--path", tmp_dir])
      end)
    end
  end

  defp generate_project(tmp_dir, name, extra_args \\ []) do
    args = [name, "--path", tmp_dir | extra_args]

    capture_io(fn ->
      Mix.Tasks.Nex.New.run(args)
    end)

    Path.join(tmp_dir, name)
  end

  defp assert_ai_onboarding_files(project_path) do
    assert File.exists?(Path.join(project_path, "AGENTS.md"))
    assert File.exists?(Path.join(project_path, ".agents/skills/nex-project/SKILL.md"))

    assert File.exists?(Path.join(project_path, ".agents/skills/nex-project/agents/openai.yaml"))
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end
