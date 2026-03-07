defmodule Nex.Agent.GatewayTest do
  use ExUnit.Case, async: false

  alias Nex.Agent.Gateway

  setup do
    tmp_dir = Path.join(System.tmp_dir!(), "nex_agent_gateway_test")
    File.mkdir_p!(tmp_dir)
    config_path = Path.join(tmp_dir, "config.json")

    File.write!(
      config_path,
      Jason.encode!(%{
        "provider" => "ollama",
        "model" => "llama3.1",
        "providers" => %{
          "ollama" => %{"api_key" => nil, "base_url" => "http://localhost:11434"}
        },
        "telegram" => %{"enabled" => false}
      })
    )

    previous = Application.get_env(:nex_agent, :config_path)
    Application.put_env(:nex_agent, :config_path, config_path)

    # Ensure Gateway is running (may have been stopped by prior test)
    ensure_started(Nex.Agent.Gateway, fn -> Gateway.start_link() end)

    # Make sure Gateway is in stopped state
    try do
      Gateway.stop()
    catch
      :exit, _ -> :ok
    end

    on_exit(fn ->
      try do
        Gateway.stop()
      catch
        :exit, _ -> :ok
      end

      if previous do
        Application.put_env(:nex_agent, :config_path, previous)
      else
        Application.delete_env(:nex_agent, :config_path)
      end
    end)

    :ok
  end

  test "gateway start boots inbound worker and keeps telegram off when disabled" do
    assert Process.whereis(Nex.Agent.Gateway) != nil

    assert :ok == Gateway.start()

    status = Gateway.status()
    assert status.status == :running
    assert status.services.bus
    assert status.services.cron
    assert status.services.inbound_worker
    refute status.services.telegram_channel

    assert :ok == Gateway.stop()
  end

  defp ensure_started(name, start_fn) do
    unless Process.whereis(name) do
      start_fn.()
    end
  end
end
