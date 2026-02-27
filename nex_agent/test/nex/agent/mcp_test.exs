defmodule Nex.Agent.MCPTest do
  use ExUnit.Case
  alias Nex.Agent.MCP

  describe "API functions" do
    test "module is loaded" do
      assert Code.ensure_loaded?(MCP)
    end
  end
end
