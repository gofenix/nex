defmodule Nex.RouteDiscoveryTest do
  use ExUnit.Case, async: true
  alias Nex.RouteDiscovery

  describe "discover_routes/2" do
    test "returns empty list for non-existent directory" do
      routes = RouteDiscovery.discover_routes("non_existent_path_xyz", :pages)
      assert routes == []
    end
  end
end
