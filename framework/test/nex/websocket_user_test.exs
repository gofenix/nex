defmodule Nex.WebSocket.UserTest do
  use ExUnit.Case, async: true

  describe "Nex.WebSocket module" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(Nex.WebSocket)
    end

    test "exports broadcast and subscribe functions" do
      functions = Nex.WebSocket.__info__(:functions)
      assert {:broadcast, 2} in functions
      assert {:subscribe, 1} in functions
    end
  end
end
