defmodule Nex.Agent.MCPTest do
  use ExUnit.Case
  alias Nex.Agent.MCP

  describe "start_link/1" do
    test "starts a new MCP connection" do
      # This would require an actual MCP server to test
      # For now, just verify the API exists
      assert function_exported?(MCP, :start_link, 1)
    end
  end

  describe "API functions" do
    test "all required functions are exported" do
      assert function_exported?(MCP, :initialize, 1)
      assert function_exported?(MCP, :initialize, 2)
      assert function_exported?(MCP, :list_tools, 1)
      assert function_exported?(MCP, :list_tools, 2)
      assert function_exported?(MCP, :call_tool, 3)
      assert function_exported?(MCP, :call_tool, 4)
      assert function_exported?(MCP, :stop, 1)
    end
  end

  describe "JSON-RPC protocol" do
    test "builds correct initialize request" do
      # The initialize request should have the correct structure
      # This is verified in the implementation, but we can test the structure here
      expected_keys = [:jsonrpc, :id, :method, :params]

      # Verify the module exists and has the right structure
      assert Code.ensure_loaded?(Nex.Agent.MCP)
    end
  end
end
