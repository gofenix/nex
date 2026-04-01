defmodule Nex.RouteDiscoveryTest do
  use ExUnit.Case, async: false
  alias Nex.RouteDiscovery

  setup do
    original_src_path = Application.get_env(:nex_core, :src_path)
    original_app_module = Application.get_env(:nex_core, :app_module)

    on_exit(fn ->
      restore_env(:src_path, original_src_path)
      restore_env(:app_module, original_app_module)
      RouteDiscovery.clear_cache()
    end)

    :ok
  end

  describe "discover_routes/2" do
    test "returns empty list for non-existent directory" do
      routes = RouteDiscovery.discover_routes("non_existent_path_xyz", :pages)
      assert routes == []
    end

    test "discovers routes from valid directory" do
      tmp_dir = "/tmp/nex_test_routes_#{:rand.uniform(10000)}"
      File.mkdir_p("#{tmp_dir}/pages")
      File.write!("#{tmp_dir}/pages/index.ex", "")
      File.write!("#{tmp_dir}/pages/users.ex", "")

      routes = RouteDiscovery.discover_routes(tmp_dir, :pages)
      assert is_list(routes)

      File.rm_rf!(tmp_dir)
    end

    test "discovers dynamic routes" do
      tmp_dir = "/tmp/nex_test_dynamic_#{:rand.uniform(10000)}"
      File.mkdir_p("#{tmp_dir}/pages/users")
      File.write!("#{tmp_dir}/pages/users/[id].ex", "")

      routes = RouteDiscovery.discover_routes(tmp_dir, :pages)
      assert length(routes) > 0

      File.rm_rf!(tmp_dir)
    end

    test "discovers api routes" do
      tmp_dir = "/tmp/nex_test_api_#{:rand.uniform(10000)}"
      File.mkdir_p("#{tmp_dir}/api")
      File.write!("#{tmp_dir}/api/todos.ex", "")

      routes = RouteDiscovery.discover_routes(tmp_dir, :api)
      assert is_list(routes)

      File.rm_rf!(tmp_dir)
    end

    test "handles file system errors gracefully" do
      routes = RouteDiscovery.discover_routes("/root/secret_dir_xyz", :pages)
      assert routes == []
    end
  end

  describe "match_route/4" do
    test "matches static route" do
      routes = [
        %{
          pattern: [{:static, "users"}],
          module_parts: ["Users"],
          segment_count: 1
        }
      ]

      result = RouteDiscovery.match_route(routes, ["users"], "MyApp", "Pages")
      assert result == {:ok, "MyApp.Pages.Users", %{}}
    end

    test "matches dynamic route" do
      routes = [
        %{
          pattern: [{:static, "users"}, {:dynamic, "id"}],
          module_parts: ["Users", "Id"],
          segment_count: 2
        }
      ]

      result = RouteDiscovery.match_route(routes, ["users", "123"], "MyApp", "Pages")
      assert result == {:ok, "MyApp.Pages.Users.Id", %{"id" => "123"}}
    end

    test "matches catch-all route" do
      routes = [
        %{
          pattern: [{:static, "docs"}, {:catchall, "path"}],
          module_parts: ["Docs", "Path"],
          segment_count: 2,
          has_catchall: true
        }
      ]

      result = RouteDiscovery.match_route(routes, ["docs", "a", "b", "c"], "MyApp", "Pages")
      assert result == {:ok, "MyApp.Pages.Docs.Path", %{"path" => ["a", "b", "c"]}}
    end

    test "returns error for non-matching route" do
      routes = [
        %{
          pattern: [{:static, "users"}],
          module_parts: ["Users"],
          segment_count: 1
        }
      ]

      result = RouteDiscovery.match_route(routes, ["posts"], "MyApp", "Pages")
      assert result == :error
    end

    test "static routes take priority over dynamic" do
      static_route = %{pattern: [{:static, "users"}], module_parts: ["Users"], segment_count: 1}
      dynamic_route = %{pattern: [{:dynamic, "id"}], module_parts: ["Id"], segment_count: 1}

      result =
        RouteDiscovery.match_route([static_route, dynamic_route], ["users"], "MyApp", "Pages")

      assert {:ok, "MyApp.Pages.Users", %{}} = result
    end

    test "empty pattern matches empty path" do
      routes = [
        %{
          pattern: [],
          module_parts: [],
          segment_count: 0
        }
      ]

      result = RouteDiscovery.match_route(routes, [], "MyApp", "Pages")
      assert result == {:ok, "MyApp.Pages", %{}}
    end

    test "pattern with remaining path returns error" do
      routes = [
        %{
          pattern: [{:static, "users"}],
          module_parts: ["Users"],
          segment_count: 1
        }
      ]

      result = RouteDiscovery.match_route(routes, ["users", "extra"], "MyApp", "Pages")
      assert result == :error
    end

    test "matches optional catch-all with segments" do
      routes = [
        %{
          pattern: [{:static, "docs"}, {:optional_catchall, "slug"}],
          module_parts: ["Docs", "Slug"],
          segment_count: 2,
          has_catchall: true
        }
      ]

      result = RouteDiscovery.match_route(routes, ["docs", "a", "b"], "MyApp", "Pages")
      assert result == {:ok, "MyApp.Pages.Docs.Slug", %{"slug" => ["a", "b"]}}
    end

    test "matches optional catch-all with no segments" do
      routes = [
        %{
          pattern: [{:static, "docs"}, {:optional_catchall, "slug"}],
          module_parts: ["Docs", "Slug"],
          segment_count: 2,
          has_catchall: true
        }
      ]

      result = RouteDiscovery.match_route(routes, ["docs"], "MyApp", "Pages")
      assert result == {:ok, "MyApp.Pages.Docs.Slug", %{"slug" => []}}
    end

    test "discovers optional catch-all from filesystem" do
      tmp_dir = "/tmp/nex_test_opt_catchall_#{:rand.uniform(10000)}"
      File.mkdir_p("#{tmp_dir}/pages/docs")
      File.write!("#{tmp_dir}/pages/docs/[[...slug]].ex", "")

      routes = RouteDiscovery.discover_routes(tmp_dir, :pages)
      assert length(routes) == 1

      [route] = routes
      assert route.pattern == [{:static, "docs"}, {:optional_catchall, "slug"}]
      assert route.param_names == ["slug"]
      assert route.has_catchall == true

      File.rm_rf!(tmp_dir)
    end

    test "dynamic routes take priority over optional catch-all siblings" do
      with_tmp_src_path(fn tmp_dir ->
        File.mkdir_p!(Path.join(tmp_dir, "pages/docs"))
        File.write!(Path.join(tmp_dir, "pages/docs/[id].ex"), "")
        File.write!(Path.join(tmp_dir, "pages/docs/[[...slug]].ex"), "")

        routes = RouteDiscovery.discover_routes(tmp_dir, :pages)
        result = RouteDiscovery.match_route(routes, ["docs", "123"], "MyApp", "Pages")
        assert result == {:ok, "MyApp.Pages.Docs.Id", %{"id" => "123"}}
      end)
    end

    test "required catch-all takes priority over optional catch-all siblings for non-empty paths" do
      with_tmp_src_path(fn tmp_dir ->
        File.mkdir_p!(Path.join(tmp_dir, "pages/docs"))
        File.write!(Path.join(tmp_dir, "pages/docs/[...slug].ex"), "")
        File.write!(Path.join(tmp_dir, "pages/docs/[[...optional_slug]].ex"), "")

        routes = RouteDiscovery.discover_routes(tmp_dir, :pages)
        result = RouteDiscovery.match_route(routes, ["docs", "a", "b"], "MyApp", "Pages")
        assert result == {:ok, "MyApp.Pages.Docs.Slug", %{"slug" => ["a", "b"]}}
      end)
    end
  end

  describe "get_routes/2" do
    test "caches routes in ETS" do
      tmp_dir = "/tmp/nex_test_cache_#{:rand.uniform(10000)}"
      File.mkdir_p("#{tmp_dir}/pages")
      File.write!("#{tmp_dir}/pages/index.ex", "")

      routes1 = RouteDiscovery.get_routes(tmp_dir, :pages)
      assert is_list(routes1)

      routes2 = RouteDiscovery.get_routes(tmp_dir, :pages)
      assert routes1 == routes2

      File.rm_rf!(tmp_dir)
    end

    test "discovers routes for different types" do
      tmp_dir = "/tmp/nex_test_types_#{:rand.uniform(10000)}"
      File.mkdir_p("#{tmp_dir}/pages")
      File.mkdir_p("#{tmp_dir}/api")
      File.write!("#{tmp_dir}/pages/index.ex", "")
      File.write!("#{tmp_dir}/api/todos.ex", "")

      page_routes = RouteDiscovery.get_routes(tmp_dir, :pages)
      api_routes = RouteDiscovery.get_routes(tmp_dir, :api)

      assert is_list(page_routes)
      assert is_list(api_routes)

      File.rm_rf!(tmp_dir)
    end
  end

  describe "clear_cache/0" do
    test "clears the route cache" do
      tmp_dir = "/tmp/nex_test_clear_#{:rand.uniform(10000)}"
      File.mkdir_p("#{tmp_dir}/pages")
      File.write!("#{tmp_dir}/pages/test.ex", "")

      RouteDiscovery.get_routes(tmp_dir, :pages)
      :ok = RouteDiscovery.clear_cache()

      File.rm_rf!(tmp_dir)
    end

    test "clears cache when ETS table doesn't exist" do
      RouteDiscovery.clear_cache()
      :ok = RouteDiscovery.clear_cache()
    end
  end

  describe "resolve/2,3" do
    test "resolve returns error for unknown path" do
      Application.put_env(:nex_core, :src_path, "nonexistent_src_xyz")

      result = RouteDiscovery.resolve(:pages, ["unknown", "path"])
      assert result == :error

      Application.delete_env(:nex_core, :src_path)
    end

    test "resolve works with existing module" do
      result = RouteDiscovery.resolve(:pages, [])
      assert result == :error or match?({:ok, _, _}, result)
    end

    test "single-segment actions resolve to the current page before the index page" do
      with_tmp_src_path(fn tmp_dir ->
        File.mkdir_p!(Path.join(tmp_dir, "pages/users"))
        File.write!(Path.join(tmp_dir, "pages/index.ex"), "")
        File.write!(Path.join(tmp_dir, "pages/users/[id].ex"), "")

        Application.put_env(:nex_core, :src_path, tmp_dir)
        Application.put_env(:nex_core, :app_module, "RouteDiscoveryActionScope")
        RouteDiscovery.clear_cache()

        result = RouteDiscovery.resolve(:action, ["save"], ["users", "123"])
        assert result == {:ok, RouteDiscoveryActionScope.Pages.Users.Id, "save", %{}}
      end)
    end

    test "single-segment actions still resolve to Pages.Index when there is no referer page" do
      with_tmp_src_path(fn tmp_dir ->
        File.mkdir_p!(Path.join(tmp_dir, "pages"))
        File.write!(Path.join(tmp_dir, "pages/index.ex"), "")

        Application.put_env(:nex_core, :src_path, tmp_dir)
        Application.put_env(:nex_core, :app_module, "RouteDiscoveryActionScope")
        RouteDiscovery.clear_cache()

        result = RouteDiscovery.resolve(:action, ["save"], [])
        assert result == {:ok, RouteDiscoveryActionScope.Pages.Index, "save", %{}}
      end)
    end

    test "single-segment actions return error when the current page does not define them" do
      with_tmp_src_path(fn tmp_dir ->
        File.mkdir_p!(Path.join(tmp_dir, "pages/users"))
        File.write!(Path.join(tmp_dir, "pages/index.ex"), "")
        File.write!(Path.join(tmp_dir, "pages/users/[id].ex"), "")

        Application.put_env(:nex_core, :src_path, tmp_dir)
        Application.put_env(:nex_core, :app_module, "RouteDiscoveryMissingAction")
        RouteDiscovery.clear_cache()

        result = RouteDiscovery.resolve(:action, ["save"], ["users", "123"])
        assert result == :error
      end)
    end
  end

  defp restore_env(key, nil), do: Application.delete_env(:nex_core, key)
  defp restore_env(key, value), do: Application.put_env(:nex_core, key, value)

  defp with_tmp_src_path(fun) do
    tmp_dir = "/tmp/nex_test_routes_#{System.unique_integer([:positive])}"
    File.mkdir_p!(tmp_dir)

    try do
      fun.(tmp_dir)
    after
      File.rm_rf!(tmp_dir)
    end
  end
end

defmodule RouteDiscoveryActionScope.Pages.Index do
  def save(_req), do: :index
end

defmodule RouteDiscoveryActionScope.Pages.Users.Id do
  def save(_req), do: :user
end

defmodule RouteDiscoveryMissingAction.Pages.Index do
  def save(_req), do: :index
end

defmodule RouteDiscoveryMissingAction.Pages.Users.Id do
  def show(_req), do: :user
end
