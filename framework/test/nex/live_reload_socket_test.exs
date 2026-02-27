defmodule Nex.LiveReloadSocketTest do
  use ExUnit.Case, async: true

  describe "Nex.LiveReloadSocket" do
    test "module exists" do
      assert {:module, _} = Code.ensure_loaded(Nex.LiveReloadSocket)
    end

    test "handle_in ignores messages" do
      result = Nex.LiveReloadSocket.handle_in({"test", [opcode: :text]}, %{})
      assert {:ok, %{}} = result
    end

    test "handle_info sends reload on :reload message" do
      result = Nex.LiveReloadSocket.handle_info({:reload, "/path/to/file.ex"}, %{})
      assert {:push, {:text, json}, %{}} = result
      assert json =~ "reload"
    end

    test "handle_info ignores other messages" do
      result = Nex.LiveReloadSocket.handle_info(:other_message, %{})
      assert {:ok, %{}} = result
    end

    test "terminate returns :ok" do
      assert Nex.LiveReloadSocket.terminate(:normal, %{}) == :ok
    end
  end
end
