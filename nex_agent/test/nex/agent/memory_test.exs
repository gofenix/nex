defmodule Nex.Agent.MemoryTest do
  use ExUnit.Case
  alias Nex.Agent.Memory

  describe "module loaded" do
    test "Memory module is loaded" do
      assert Code.ensure_loaded?(Memory)
    end
  end

  describe "search/2" do
    test "returns search results" do
      results = Memory.search("test query", limit: 5)
      assert is_list(results)
    end
  end

  describe "get/1" do
    test "returns entries for a date" do
      entries = Memory.get(Date.to_string(Date.utc_today()))
      assert is_list(entries)
    end
  end
end
