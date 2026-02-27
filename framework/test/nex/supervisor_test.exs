defmodule Nex.SupervisorTest do
  use ExUnit.Case, async: false

  alias Nex.Supervisor

  setup do
    Nex.Session.ensure_table()
    :ok
  end

  describe "Nex.Supervisor" do
    test "module loads correctly" do
      assert Code.ensure_loaded?(Nex.Supervisor)
    end

    test "is a Supervisor" do
      # Check that it uses Supervisor behaviour
      {:ok, pid} = Supervisor.start_link(name: TestSup)
      assert is_pid(pid)
      Process.exit(pid, :shutdown)
    end
  end
end
