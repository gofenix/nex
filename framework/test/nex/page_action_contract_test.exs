defmodule NexPageActionContractApp.Pages.Index do
  use Nex

  def create_todo(%Nex.Req{body: %{"text" => text}}) do
    "created:#{text}"
  end
end

defmodule NexPageActionContractApp.Pages.Users.Id do
  use Nex

  def follow(%Nex.Req{query: %{"id" => id}}) do
    "followed:#{id}"
  end
end

defmodule Nex.PageActionContractTest do
  use ExUnit.Case, async: false
  import Plug.Test
  import Plug.Conn

  alias Nex.Handler
  alias Nex.RouteDiscovery

  setup do
    Process.delete(:csrf_token)
    Process.delete(:nex_pending_cookies)
    Process.delete(:nex_incoming_cookies)

    case Process.whereis(Nex.Store) do
      nil ->
        start_supervised!({Nex.Store, []})

      _pid ->
        :ok
    end

    previous_plugs = Application.get_env(:nex_core, :plugs)
    previous_env = Application.get_env(:nex_core, :env)
    previous_src_path = Application.get_env(:nex_core, :src_path)
    previous_app_module = Application.get_env(:nex_core, :app_module)
    previous_secret = System.get_env("SECRET_KEY_BASE")

    tmp_dir = Path.join(System.tmp_dir!(), "nex_page_actions_#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join(tmp_dir, "pages/users"))
    File.write!(Path.join(tmp_dir, "pages/index.ex"), "")
    File.write!(Path.join(tmp_dir, "pages/users/[id].ex"), "")

    Application.delete_env(:nex_core, :plugs)
    Application.put_env(:nex_core, :env, :test)
    Application.put_env(:nex_core, :src_path, tmp_dir)
    Application.put_env(:nex_core, :app_module, "NexPageActionContractApp")
    System.put_env("SECRET_KEY_BASE", String.duplicate("test-secret-", 4))
    RouteDiscovery.clear_cache()

    on_exit(fn ->
      Process.delete(:csrf_token)
      Process.delete(:nex_pending_cookies)
      Process.delete(:nex_incoming_cookies)
      File.rm_rf!(tmp_dir)
      RouteDiscovery.clear_cache()

      restore_env(:plugs, previous_plugs)
      restore_env(:env, previous_env)
      restore_env(:src_path, previous_src_path)
      restore_env(:app_module, previous_app_module)

      if previous_secret == nil do
        System.delete_env("SECRET_KEY_BASE")
      else
        System.put_env("SECRET_KEY_BASE", previous_secret)
      end
    end)

    :ok
  end

  describe "handler runtime contract" do
    test "single-path page actions read form data from req.body" do
      token = Nex.CSRF.generate_token()

      conn =
        conn(:post, "/create_todo", %{"text" => "Buy milk"})
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> put_req_header("referer", "http://localhost:4000/")
        |> put_req_header("x-csrf-token", token)
        |> put_req_header("hx-request", "true")

      result = Handler.handle(conn)

      assert result.status == 200
      assert result.resp_body == "created:Buy milk"
    end

    test "multi-path page actions read dynamic params from req.query" do
      token = Nex.CSRF.generate_token()

      conn =
        conn(:post, "/users/123/follow", %{})
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> put_req_header("referer", "http://localhost:4000/users/123")
        |> put_req_header("x-csrf-token", token)
        |> put_req_header("hx-request", "true")

      result = Handler.handle(conn)

      assert result.status == 200
      assert result.resp_body == "followed:123"
    end
  end

  describe "example source contract" do
    test "affected example page actions no longer use flat map params" do
      assert_example_contract(
        "examples/todos/src/pages/index.ex",
        ["req.body[\"text\"]", "req.body[\"id\"]"],
        ["def create_todo(%{\"text\" => text})", "def toggle_todo(%{\"id\" => id})", "def delete_todo(%{\"id\" => id})"]
      )

      assert_example_contract(
        "examples/guestbook/src/pages/index.ex",
        ["req.body[\"name\"]", "req.body[\"content\"]", "req.query[\"id\"]"],
        ["def create_message(%{\"name\" => name, \"content\" => content})", "def delete_message(%{\"id\" => id})", "def delete(%{\"id\" => id})"]
      )

      assert_example_contract(
        "examples/auth_demo/src/pages/login.ex",
        ["req.body[\"email\"]", "req.body[\"password\"]"],
        ["def login(%{\"email\" => email, \"password\" => password})"]
      )

      assert_example_contract(
        "examples/auth_demo/src/pages/index.ex",
        ["req.body[\"theme\"]"],
        ["def set_theme(%{\"theme\" => theme})"]
      )

      assert_example_contract(
        "examples/alpine_showcase/src/pages/index.ex",
        ["req.body[\"name\"]", "req.body[\"email\"]"],
        ["name: params[\"name\"]", "email: params[\"email\"]"]
      )

      assert_example_contract(
        "examples/dynamic_routes/src/pages/users/[id].ex",
        ["req.query[\"id\"]"],
        ["def follow(%{\"id\" => id})"]
      )
    end
  end

  describe "documentation contract" do
    test "action docs describe Nex.Req instead of a flat map" do
      tutorial_actions = read_repo_file("website/priv/docs/tutorial_02_actions.md")
      tutorial_forms = read_repo_file("website/priv/docs/tutorial_03_forms.md")
      core_action = read_repo_file("website/priv/docs/core_action_guide.md")
      ext_sse = read_repo_file("website/priv/docs/ext_sse_guide.md")
      vibe = read_repo_file("website/priv/docs/vibe_coding_guide.md")
      faq = read_repo_file("website/priv/docs/reference_faq.md")

      assert tutorial_actions =~ "req.query[\"id\"]"
      refute tutorial_actions =~ "def delete(%{\"id\" => id})"

      assert tutorial_forms =~ "req.body[\"name\"]"
      assert tutorial_forms =~ "req.body[\"avatar\"]"
      refute tutorial_forms =~ "Action functions receive a Map"

      assert core_action =~ "req.query[\"id\"]"
      refute core_action =~ "delete(%{\"id\" => \"123\"})"

      assert ext_sse =~ "req.body[\"message\"]"
      refute ext_sse =~ "def chat(%{\"message\" => msg})"

      assert vibe =~ "Receives a **`Nex.Req` struct**"
      refute vibe =~ "Receives a flat **Map**"
      refute vibe =~ "def action_name(params)"

      assert faq =~ "def add(req)"
      refute faq =~ "def add(_params)"
    end
  end

  defp assert_example_contract(path, required_snippets, forbidden_snippets) do
    contents = read_repo_file(path)

    Enum.each(required_snippets, fn snippet ->
      assert contents =~ snippet
    end)

    Enum.each(forbidden_snippets, fn snippet ->
      refute contents =~ snippet
    end)
  end

  defp read_repo_file(path) do
    repo_root = Path.expand("../../..", __DIR__)
    repo_root |> Path.join(path) |> File.read!()
  end

  defp restore_env(key, nil), do: Application.delete_env(:nex_core, key)
  defp restore_env(key, value), do: Application.put_env(:nex_core, key, value)
end
