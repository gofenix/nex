defmodule NexExamplesTestSupport.Commands do
  alias NexExamplesTestSupport.{Artifacts, Config}

  def run!(%Config{} = config, name, [command | args]) do
    run!(config, name, command, args)
  end

  def run!(%Config{} = config, name, command, args) do
    Artifacts.ensure!(config)
    log_path = Artifacts.command_log_path(config, name)

    {output, exit_status} =
      System.cmd(command, args,
        cd: config.cwd,
        env: config.env,
        stderr_to_stdout: true
      )

    File.mkdir_p!(Path.dirname(log_path))
    File.write!(log_path, output)

    if exit_status != 0 do
      raise """
      command #{name} failed for #{config.slug} (exit #{exit_status})

      #{output}
      """
    end

    output
  end
end
