defmodule Nex.MiddlewareTest do
  use ExUnit.Case, async: true

  defmodule TestPlug do
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, _opts) do
      assign(conn, :test_plug_ran, true)
    end
  end

  defmodule HaltingPlug do
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, _opts) do
      conn
      |> put_resp_header("x-halted", "true")
      |> halt()
    end
  end

  setup do
    # Clear any configured plugs
    Application.delete_env(:nex_core, :plugs)
    :ok
  end

  describe "run/1" do
    test "returns conn unchanged when no plugs configured" do
      Application.put_env(:nex_core, :plugs, [])

      conn = %Plug.Conn{}
      result = Nex.Middleware.run(conn)

      assert result == conn
    end

    test "runs configured plugs in order" do
      Application.put_env(:nex_core, :plugs, [Nex.MiddlewareTest.TestPlug])

      conn = %Plug.Conn{}
      result = Nex.Middleware.run(conn)

      assert result.assigns[:test_plug_ran] == true
    end

    test "runs multiple plugs in order" do
      defmodule SecondPlug do
        import Plug.Conn
        def init(opts), do: opts
        def call(conn, _opts), do: assign(conn, :second_ran, true)
      end

      Application.put_env(:nex_core, :plugs, [Nex.MiddlewareTest.TestPlug, SecondPlug])

      conn = %Plug.Conn{}
      result = Nex.Middleware.run(conn)

      assert result.assigns[:test_plug_ran] == true
      assert result.assigns[:second_ran] == true
    end

    test "stops running plugs when one halts" do
      defmodule ThirdPlug do
        import Plug.Conn
        def init(opts), do: opts
        def call(conn, _opts), do: assign(conn, :third_ran, true)
      end

      Application.put_env(:nex_core, :plugs, [
        Nex.MiddlewareTest.HaltingPlug,
        ThirdPlug
      ])

      conn = %Plug.Conn{}
      result = Nex.Middleware.run(conn)

      assert result.halted == true
      assert result.assigns[:third_ran] != true
    end
  end
end
