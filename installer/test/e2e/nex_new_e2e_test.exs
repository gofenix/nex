defmodule Mix.Tasks.Nex.NewE2ETest do
  @moduledoc """
  End-to-end tests for the Nex project generator.

  These tests generate real projects, compile them, start dev servers,
  and make HTTP requests to verify everything works.

  Run with: mix test --include e2e
  """
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  @moduletag timeout: 180_000

  # =========================================================================
  # basic (HTMX)
  # =========================================================================

  describe "basic starter (HTMX)" do
    setup do
      project = generate("e2e_basic")
      on_exit(fn -> cleanup(project) end)
      {:ok, project: project}
    end

    test "generates correct file set with no stale layouts.ex", %{project: p} do
      assert_files_exist(p, [
        "mix.exs",
        "src/application.ex",
        "src/pages/_app.ex",
        "src/pages/_document.ex",
        "src/pages/index.ex",
        "src/api/hello.ex",
        "src/components/card.ex",
        ".gitignore",
        "Dockerfile",
        "AGENTS.md",
        ".agents/skills/nex-project/SKILL.md",
        ".agents/skills/nex-project/agents/openai.yaml",
        "README.md"
      ])

      refute File.exists?(Path.join(p, "src/layouts.ex")),
             "src/layouts.ex should not exist (replaced by _app.ex + _document.ex)"

      app = File.read!(Path.join(p, "src/pages/_app.ex"))
      assert app =~ "Pages.App"

      doc = File.read!(Path.join(p, "src/pages/_document.ex"))
      assert doc =~ "Pages.Document"
      assert doc =~ "htmx.org"
    end

    test "compiles without errors", %{project: p} do
      assert {_, 0} = run(p, "mix", ["deps.get"])
      assert {_, 0} = run(p, "mix", ["compile"])
    end

    # Server test — run with: mix test --include e2e_server
    # Requires compiled project and available port
    @tag :e2e_server
    test "starts and serves pages and API", %{project: p} do
      run(p, "mix", ["deps.get"])
      port = 4301
      server = start_server(p, port)
      on_exit(fn -> stop_server(server) end)

      {status, body} = http_get(port, "/")
      assert status == 200
      assert body =~ "<!DOCTYPE html>"
      assert body =~ "htmx.org"
      assert body =~ "csrf-token"

      {status, body} = http_get(port, "/api/hello")
      assert status == 200
      assert body =~ "hello"
    end
  end

  # =========================================================================
  # basic (Datastar)
  # =========================================================================

  describe "basic starter (Datastar)" do
    setup do
      project = generate("e2e_datastar", ["--frontend", "datastar"])
      on_exit(fn -> cleanup(project) end)
      {:ok, project: project}
    end

    test "generates datastar-specific files without HTMX", %{project: p} do
      assert File.exists?(Path.join(p, "src/api/counter.ex"))
      assert File.exists?(Path.join(p, "src/pages/_app.ex"))
      assert File.exists?(Path.join(p, "src/pages/_document.ex"))
      assert File.exists?(Path.join(p, ".agents/skills/nex-project/SKILL.md"))
      assert File.exists?(Path.join(p, ".agents/skills/nex-project/agents/openai.yaml"))
      refute File.exists?(Path.join(p, "src/layouts.ex"))

      doc = File.read!(Path.join(p, "src/pages/_document.ex"))
      assert doc =~ "datastar"
      refute doc =~ "htmx"
    end

    test "compiles without errors", %{project: p} do
      assert {_, 0} = run(p, "mix", ["deps.get"])
      assert {_, 0} = run(p, "mix", ["compile"])
    end

    @tag :e2e_server
    test "starts and serves datastar page", %{project: p} do
      run(p, "mix", ["deps.get"])
      port = 4302
      server = start_server(p, port)
      on_exit(fn -> stop_server(server) end)

      {status, body} = http_get(port, "/")
      assert status == 200
      assert body =~ "datastar"
      refute body =~ "htmx.org"
    end
  end

  # =========================================================================
  # saas
  # =========================================================================

  describe "saas starter" do
    setup do
      project = generate("e2e_saas", ["--starter", "saas"])
      on_exit(fn -> cleanup(project) end)
      {:ok, project: project}
    end

    test "generates auth, database, and page files", %{project: p} do
      expected = ~w(
        src/accounts.ex src/data.ex src/workspace.ex
        src/plugs/require_auth.ex src/components/flash.ex
        src/pages/_app.ex src/pages/_document.ex
        src/pages/index.ex src/pages/login.ex
        src/pages/signup.ex src/pages/dashboard.ex
        src/api/health.ex db/.gitkeep
      )

      for file <- expected do
        assert File.exists?(Path.join(p, file)), "missing: #{file}"
      end

      assert File.exists?(Path.join(p, ".agents/skills/nex-project/SKILL.md"))
      assert File.exists?(Path.join(p, ".agents/skills/nex-project/agents/openai.yaml"))
      refute File.exists?(Path.join(p, "src/layouts.ex"))

      # Verify auth-aware layout
      app = File.read!(Path.join(p, "src/pages/_app.ex"))
      assert app =~ "@current_user"
    end

    test "compiles without errors", %{project: p} do
      assert {_, 0} = run(p, "mix", ["deps.get"])
      assert {_, 0} = run(p, "mix", ["compile"])
    end

    @tag :e2e_server
    test "starts and serves pages and health endpoint", %{project: p} do
      run(p, "mix", ["deps.get"])
      port = 4303
      server = start_server(p, port)
      on_exit(fn -> stop_server(server) end)

      # Homepage loads
      {status, body} = http_get(port, "/")
      assert status == 200
      assert body =~ "<!DOCTYPE html>"

      # Health API responds
      {status, body} = http_get(port, "/api/health")
      assert status == 200
      assert body =~ "ok"
    end
  end

  # =========================================================================
  # AI onboarding content verification
  # =========================================================================

  describe "AI onboarding files" do
    setup do
      project = generate("e2e_agents")
      on_exit(fn -> cleanup(project) end)
      {:ok, project: project}
    end

    test "keeps AGENTS.md lightweight and moves canonical rules into the project skill", %{
      project: p
    } do
      agents = File.read!(Path.join(p, "AGENTS.md"))
      skill = File.read!(Path.join(p, ".agents/skills/nex-project/SKILL.md"))
      openai_yaml = File.read!(Path.join(p, ".agents/skills/nex-project/agents/openai.yaml"))

      assert agents =~ ".agents/skills/nex-project/SKILL.md"
      assert agents =~ "nex-project"
      refute agents =~ "Critical Anti-Patterns"
      refute agents =~ "single source of truth"

      # Layout system
      assert skill =~ "_app.ex"
      assert skill =~ "_document.ex"
      refute skill =~ "layouts.ex"

      # Routing
      assert skill =~ "[[...path]]"
      assert skill =~ "[id]"

      # mount returns
      assert skill =~ ":not_found"
      assert skill =~ ~s({:redirect, "/path"})

      # Nex.Res pipeline
      assert skill =~ "Nex.Res"
      assert skill =~ "Nex.Res.json"

      # HTMX helpers
      assert skill =~ "Nex.HTMX"
      assert skill =~ "push_url"

      # Convention error pages
      assert skill =~ "Error404"

      # Per-page layout
      assert skill =~ "layout, do: :none"

      # req/body contract
      assert skill =~ "Nex.Req"
      assert skill =~ "req.body"
      assert skill =~ "nil for GET"

      assert openai_yaml =~ "display_name: \"Nex Project\""
      assert openai_yaml =~ "nex-project skill"
    end
  end

  # =========================================================================
  # Helpers
  # =========================================================================

  defp generate(name, extra_args \\ []) do
    tmp = Path.join(System.tmp_dir!(), "nex_e2e_#{System.unique_integer([:positive])}")
    File.rm_rf!(tmp)
    File.mkdir_p!(tmp)

    original_skip = System.get_env("NEX_NEW_SKIP_DEPS")
    System.put_env("NEX_NEW_SKIP_DEPS", "1")
    Mix.Task.reenable("nex.new")

    capture_io(fn ->
      Mix.Tasks.Nex.New.run([name, "--path", tmp | extra_args])
    end)

    restore_env("NEX_NEW_SKIP_DEPS", original_skip)

    project = Path.join(tmp, name)

    # Override hex dependency with local path for testing
    framework_path = Path.expand("../../../framework", __DIR__)
    patch_deps_to_local_path(project, framework_path)

    project
  end

  defp patch_deps_to_local_path(project, framework_path) do
    mix_path = Path.join(project, "mix.exs")
    content = File.read!(mix_path)

    patched =
      content
      |> String.replace(
        ~r/\{:nex_core, "~> [^"]+"\}/,
        "{:nex_core, path: \"#{framework_path}\"}"
      )
      |> String.replace(
        ~r/\{:nex_base, "~> [^"]+"\}/,
        "{:nex_base, path: \"#{Path.expand("../../../nex_base", __DIR__)}\"}"
      )
      |> String.replace(
        ~r/\{:nex_env, "~> [^"]+"\}/,
        "{:nex_env, path: \"#{Path.expand("../../../nex_env", __DIR__)}\"}"
      )

    File.write!(mix_path, patched)
  end

  defp run(project, cmd, args) do
    {output, code} =
      System.cmd(cmd, args,
        cd: project,
        stderr_to_stdout: true,
        env: [{"MIX_ENV", "dev"}]
      )

    {output, code}
  end

  defp start_server(project, port) do
    # Ensure deps are compiled first
    run(project, "mix", ["compile"])

    # Start server as a background OS process
    port_str = Integer.to_string(port)

    spawn_port =
      Port.open({:spawn_executable, System.find_executable("mix")}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        args: ["nex.dev"],
        cd: String.to_charlist(project),
        env: [
          {~c"PORT", String.to_charlist(port_str)},
          {~c"MIX_ENV", ~c"dev"}
        ]
      ])

    wait_for_port(port, 30_000)
    spawn_port
  end

  defp stop_server(port_ref) when is_port(port_ref) do
    try do
      Port.close(port_ref)
    catch
      _, _ -> :ok
    end

    # Also kill any lingering BEAM processes on the port
    System.cmd("lsof", ["-ti", ":4301,:4302,:4303"], stderr_to_stdout: true)
    |> case do
      {pids, 0} ->
        pids
        |> String.trim()
        |> String.split("\n", trim: true)
        |> Enum.each(fn pid -> System.cmd("kill", ["-9", pid]) end)

      _ ->
        :ok
    end
  end

  defp stop_server(_), do: :ok

  defp wait_for_port(port, timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_wait_for_port(port, deadline)
  end

  defp do_wait_for_port(port, deadline) do
    if System.monotonic_time(:millisecond) > deadline do
      raise "Server didn't start on port #{port} within timeout"
    end

    case :gen_tcp.connect(~c"127.0.0.1", port, [], 500) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        # Give server a moment to fully initialize
        Process.sleep(500)

      {:error, _} ->
        Process.sleep(1_000)
        do_wait_for_port(port, deadline)
    end
  end

  defp http_get(port, path) do
    {:ok, _} = Application.ensure_all_started(:req)
    url = "http://127.0.0.1:#{port}#{path}"

    case Req.get(url, receive_timeout: 10_000, retry: false, redirect: false) do
      {:ok, %{status: status, body: body}} ->
        {status, body}

      {:error, reason} ->
        raise "HTTP GET #{url} failed: #{inspect(reason)}"
    end
  end

  defp assert_files_exist(project, files) do
    for file <- files do
      assert File.exists?(Path.join(project, file)), "expected file missing: #{file}"
    end
  end

  defp cleanup(project) do
    # Stop any servers that may still be running
    parent = Path.dirname(project)
    File.rm_rf!(parent)
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end
