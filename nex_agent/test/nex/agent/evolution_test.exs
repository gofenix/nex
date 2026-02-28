defmodule Nex.Agent.EvolutionTest do
  use ExUnit.Case, async: false
  alias Nex.Agent.Evolution

  describe "list_versions/1" do
    test "returns empty list for non-existing module" do
      non_existing = Module.concat(Nex.Agent.Test, "NonExisting#{:rand.uniform(100_000_000)}")

      versions = Evolution.list_versions(non_existing)

      assert versions == []
    end
  end

  describe "current_version/1" do
    test "returns nil for non-existing module" do
      non_existing = Module.concat(Nex.Agent.Test, "NonExisting#{:rand.uniform(100_000_000)}")

      version = Evolution.current_version(non_existing)

      assert version == nil
    end
  end

  describe "get_version/2" do
    test "returns nil for non-existing module" do
      non_existing = Module.concat(Nex.Agent.Test, "NonExisting#{:rand.uniform(100_000_000)}")

      version = Evolution.get_version(non_existing, "any-version")

      assert version == nil
    end

    test "returns nil for non-existing version" do
      version = Evolution.get_version(Nex.Agent.Runner, "non-existent-version-id")

      assert version == nil
    end
  end

  describe "can_evolve?/1" do
    test "returns false for non-existing module" do
      non_existing = Module.concat(Nex.Agent.Test, "NonExisting#{:rand.uniform(100_000_000)}")

      assert Evolution.can_evolve?(non_existing) == false
    end
  end
end
