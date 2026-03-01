defmodule Mix.Tasks.Nex.Agent do
  @moduledoc """
  Nex Agent CLI
  """

  use Mix.Task
  require Logger

  @shortdoc "Nex Agent CLI"

  def run(args) do
    # Ensure Finch is started for HTTP requests
    ensure_finch_started()

    {opts, args} =
      OptionParser.parse!(args,
        switches: [
          message: :string,
          model: :string,
          provider: :string,
          help: :boolean,
          log: :boolean,
          log_level: :string
        ],
        aliases: [m: :message, h: :help, l: :log]
      )

    configure_logging(opts)

    if opts[:help] do
      print_help()
      System.halt(0)
    end

    cond do
      args == ["onboard"] -> run_onboard()
      args == ["status"] -> run_status()
      args == ["gateway"] -> run_gateway()
      List.starts_with?(args, ["config"]) -> run_config(args)
      opts[:message] != nil -> run_single(opts)
      true -> run_interactive()
    end
  end

  defp ensure_finch_started do
    case Application.ensure_all_started(:req) do
      {:ok, _apps} ->
        :ok

      {:error, {:already_started, _app}} ->
        :ok

      {:error, reason} ->
        Mix.raise("Failed to start :req application: #{inspect(reason)}")
    end
  end

  defp print_help do
    Mix.shell().info("Nex Agent CLI")
    Mix.shell().info("  mix nex.agent                  Interactive REPL")
    Mix.shell().info("  mix nex.agent onboard          Initialize")
    Mix.shell().info("  mix nex.agent -m \"hello\"       Single message")
    Mix.shell().info("  mix nex.agent gateway          Start gateway")
    Mix.shell().info("  mix nex.agent status           Show status")
    Mix.shell().info("  mix nex.agent gateway --log    Enable debug logs")
    Mix.shell().info("  mix nex.agent --log-level debug|info|warning|error")
  end

  defp configure_logging(opts) do
    level =
      cond do
        is_binary(opts[:log_level]) -> parse_log_level(opts[:log_level])
        opts[:log] == true -> :debug
        true -> nil
      end

    if level do
      Logger.configure(level: level)
      Mix.shell().info("Logger level set to #{level}")
    end
  end

  defp parse_log_level(raw) do
    case raw |> String.trim() |> String.downcase() do
      "debug" -> :debug
      "info" -> :info
      "warn" -> :warning
      "warning" -> :warning
      "error" -> :error
      _ -> :info
    end
  end

  defp run_onboard do
    Mix.shell().info("Initializing Nex Agent...")
    Nex.Agent.Onboarding.ensure_initialized()
    Mix.shell().info("Workspace: #{Nex.Agent.Workspace.workspace_path()}")
    Mix.shell().info("Config:   #{Nex.Agent.Config.config_path()}")
  end

  defp run_status do
    config = Nex.Agent.Config.load()
    Mix.shell().info("Provider: #{config.provider}")
    Mix.shell().info("Model:    #{config.model}")
  end

  defp run_gateway do
    Mix.shell().info("Starting Gateway...")

    lock_socket =
      case acquire_gateway_lock() do
        {:ok, socket} ->
          socket

        {:error, :already_running} ->
          Mix.shell().error("Gateway is already running (port lock is held).")
          System.halt(1)

        {:error, reason} ->
          Mix.shell().error("Failed to acquire gateway port lock: #{inspect(reason)}")
          System.halt(1)
      end

    case Process.whereis(Nex.Agent.Gateway) do
      nil ->
        {:ok, _} = Nex.Agent.Gateway.start_link()

      _pid ->
        :ok
    end

    Process.put(:gateway_lock_socket, lock_socket)
    Nex.Agent.Gateway.start()
    Process.sleep(:infinity)
  end

  defp acquire_gateway_lock do
    config = Nex.Agent.Config.load()
    gateway = config.gateway || %{}
    port = Map.get(gateway, "port", 18790)

    :gen_tcp.listen(port, [
      :binary,
      {:packet, 0},
      {:active, false},
      {:reuseaddr, false},
      {:ip, {127, 0, 0, 1}}
    ])
    |> case do
      {:ok, socket} -> {:ok, socket}
      {:error, :eaddrinuse} -> {:error, :already_running}
      other -> other
    end
  end

  defp run_config(args) do
    case args do
      ["config", "show"] ->
        config = Nex.Agent.Config.load()
        Mix.shell().info("Provider: #{config.provider}")
        Mix.shell().info("Model:    #{config.model}")

      ["config", "set", "provider", value] ->
        config = Nex.Agent.Config.load()
        Nex.Agent.Config.save(Nex.Agent.Config.set(config, :provider, value))
        Mix.shell().info("Updated provider = #{value}")

      ["config", "set", "model", value] ->
        config = Nex.Agent.Config.load()
        Nex.Agent.Config.save(Nex.Agent.Config.set(config, :model, value))
        Mix.shell().info("Updated model = #{value}")

      ["config", "set", "api_key", provider, key] ->
        config = Nex.Agent.Config.load()
        Nex.Agent.Config.save(Nex.Agent.Config.set(config, :api_key, {provider, key}))
        Mix.shell().info("Updated #{provider} API key")

      ["config", "set", "telegram.token", value] ->
        config = Nex.Agent.Config.load()
        Nex.Agent.Config.save(Nex.Agent.Config.set(config, :telegram_token, value))
        Mix.shell().info("Updated telegram.token")

      ["config", "set", "telegram.enabled", value] ->
        config = Nex.Agent.Config.load()

        case parse_boolean(value) do
          {:ok, bool} ->
            Nex.Agent.Config.save(Nex.Agent.Config.set(config, :telegram_enabled, bool))
            Mix.shell().info("Updated telegram.enabled = #{bool}")

          :error ->
            Mix.shell().error("Invalid boolean: #{value} (expected true/false)")
        end

      ["config", "set", "telegram.allow_from", value] ->
        config = Nex.Agent.Config.load()
        allow_from = parse_csv_list(value)
        Nex.Agent.Config.save(Nex.Agent.Config.set(config, :telegram_allow_from, allow_from))
        Mix.shell().info("Updated telegram.allow_from = #{Enum.join(allow_from, ",")}")

      ["config", "set", "telegram.reply_to_message", value] ->
        config = Nex.Agent.Config.load()

        case parse_boolean(value) do
          {:ok, bool} ->
            Nex.Agent.Config.save(Nex.Agent.Config.set(config, :telegram_reply_to_message, bool))
            Mix.shell().info("Updated telegram.reply_to_message = #{bool}")

          :error ->
            Mix.shell().error("Invalid boolean: #{value} (expected true/false)")
        end

      _ ->
        Mix.shell().error("Unknown config command")
    end
  end

  defp parse_boolean(value) when is_binary(value) do
    case String.downcase(String.trim(value)) do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
      _ -> :error
    end
  end

  defp parse_csv_list(value) when is_binary(value) do
    value
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp run_single(opts) do
    config = Nex.Agent.Config.load()

    unless Nex.Agent.Config.valid?(config) do
      Mix.shell().error("No API key. Run: mix nex.agent onboard")
      System.halt(1)
    end

    Nex.Agent.Onboarding.ensure_initialized()

    {:ok, agent} =
      Nex.Agent.start(
        provider: String.to_atom(config.provider),
        model: config.model,
        api_key: Nex.Agent.Config.get_current_api_key(config),
        base_url: Nex.Agent.Config.get_current_base_url(config)
      )

    {:ok, result, _} = Nex.Agent.prompt(agent, opts[:message])
    Mix.shell().info(result)
  end

  defp run_interactive do
    config = Nex.Agent.Config.load()

    unless Nex.Agent.Config.valid?(config) do
      Mix.shell().error("No API key. Run: mix nex.agent onboard")
      System.halt(1)
    end

    Nex.Agent.Onboarding.ensure_initialized()

    Mix.shell().info("Nex Agent (type 'exit' to quit)")

    {:ok, agent} =
      Nex.Agent.start(
        provider: String.to_atom(config.provider),
        model: config.model,
        api_key: Nex.Agent.Config.get_current_api_key(config),
        base_url: Nex.Agent.Config.get_current_base_url(config)
      )

    loop(agent)
  end

  defp loop(agent) do
    case Mix.shell().prompt("You> ") do
      :eof ->
        Mix.shell().info("Goodbye!")

      input ->
        input = String.trim(input)

        if input in ["exit", "quit"] do
          Mix.shell().info("Goodbye!")
        else
          if input != "" do
            {:ok, result, _} = Nex.Agent.prompt(agent, input)
            Mix.shell().info(result)
          end

          loop(agent)
        end
    end
  end
end
