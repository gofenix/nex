defmodule E2E.ExampleServer do
  use GenServer

  alias E2E.{Artifacts, Example}

  @startup_timeout 180_000

  def start_link(%Example{} = example) do
    GenServer.start(__MODULE__, example)
  end

  def wait_until_ready(server, %Example{} = example, timeout \\ @startup_timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_wait_until_ready(server, Example.ready_url(example), deadline, "server not ready")
  end

  def stop(server) when is_pid(server) do
    if Process.alive?(server) do
      GenServer.call(server, :shutdown, 15_000)
    else
      :ok
    end
  catch
    :exit, _reason -> :ok
  end

  def status(server) do
    GenServer.call(server, :status)
  end

  @impl true
  def init(example) do
    Process.flag(:trap_exit, true)

    Artifacts.ensure!()

    log_path = Artifacts.log_path(example)
    File.mkdir_p!(Path.dirname(log_path))
    {:ok, log_device} = File.open(log_path, [:write, :binary])

    mix = System.find_executable("mix") || raise "could not find mix executable"

    case System.cmd(mix, ["deps.get"], cd: example.cwd, stderr_to_stdout: true) do
      {output, 0} ->
        IO.binwrite(log_device, output)

      {output, status} ->
        IO.binwrite(log_device, output)
        File.close(log_device)
        {:stop, {:deps_get_failed, status}}
    end

    port =
      Port.open({:spawn_executable, mix}, [
        :binary,
        :use_stdio,
        :stderr_to_stdout,
        :exit_status,
        {:cd, example.cwd},
        {:args, ["nex.dev", "--port", Integer.to_string(example.port), "--host", "127.0.0.1"]}
      ])

    os_pid =
      case Port.info(port, :os_pid) do
        {:os_pid, pid} -> pid
        _ -> nil
      end

    IO.binwrite(log_device, "Starting #{example.name} on #{Example.base_url(example)}\n")

    {:ok,
     %{
       example: example,
       exit_status: nil,
       log_device: log_device,
       log_path: log_path,
       os_pid: os_pid,
       port: port
     }}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, Map.take(state, [:exit_status, :log_path, :os_pid]), state}
  end

  @impl true
  def handle_call(:shutdown, _from, state) do
    state = shutdown_port(state)
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_info({port, {:data, data}}, %{port: port} = state) do
    IO.binwrite(state.log_device, data)
    {:noreply, state}
  end

  @impl true
  def handle_info({port, {:exit_status, exit_status}}, %{port: port} = state) do
    IO.binwrite(state.log_device, "\nExited with status #{exit_status}\n")
    {:noreply, %{state | exit_status: exit_status}}
  end

  @impl true
  def handle_info({:EXIT, _port, _reason}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(_message, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    shutdown_port(state)
    File.close(state.log_device)
    :ok
  end

  defp do_wait_until_ready(server, ready_url, deadline, last_error) do
    status = status(server)

    cond do
      is_integer(status.exit_status) ->
        {:error,
         "example server exited before readiness: #{status.exit_status}\n" <>
           tail_log(status.log_path)}

      System.monotonic_time(:millisecond) >= deadline ->
        {:error,
         "timed out waiting for #{ready_url}: #{last_error}\n" <> tail_log(status.log_path)}

      true ->
        case Req.get(url: ready_url, retry: false, redirect: false, receive_timeout: 1_000) do
          {:ok, %{status: code}} when code in 200..399 ->
            :ok

          {:ok, %{status: code}} ->
            Process.sleep(500)
            do_wait_until_ready(server, ready_url, deadline, "received HTTP #{code}")

          {:error, error} ->
            Process.sleep(500)
            do_wait_until_ready(server, ready_url, deadline, Exception.message(error))
        end
    end
  end

  defp shutdown_port(%{exit_status: exit_status} = state) when is_integer(exit_status), do: state

  defp shutdown_port(%{os_pid: nil} = state), do: state

  defp shutdown_port(%{os_pid: os_pid, port: port} = state) do
    _ = System.cmd("kill", ["-TERM", Integer.to_string(os_pid)], stderr_to_stdout: true)
    wait_for_exit(os_pid, 10_000)

    if process_alive?(os_pid) do
      _ = System.cmd("kill", ["-KILL", Integer.to_string(os_pid)], stderr_to_stdout: true)
      wait_for_exit(os_pid, 2_000)
    end

    safe_close_port(port)
    state
  end

  defp wait_for_exit(os_pid, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    Stream.repeatedly(fn -> :tick end)
    |> Enum.reduce_while(nil, fn _, _ ->
      cond do
        not process_alive?(os_pid) ->
          {:halt, :ok}

        System.monotonic_time(:millisecond) >= deadline ->
          {:halt, :timeout}

        true ->
          Process.sleep(100)
          {:cont, nil}
      end
    end)
  end

  defp process_alive?(os_pid) do
    case System.cmd("kill", ["-0", Integer.to_string(os_pid)], stderr_to_stdout: true) do
      {_, 0} -> true
      _ -> false
    end
  end

  defp safe_close_port(port) do
    Port.close(port)
  rescue
    _ -> :ok
  end

  defp tail_log(path) do
    path
    |> File.read!()
    |> String.trim()
    |> String.split("\n")
    |> Enum.take(-40)
    |> Enum.join("\n")
  end
end
