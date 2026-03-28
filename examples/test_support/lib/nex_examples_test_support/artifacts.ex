defmodule NexExamplesTestSupport.Artifacts do
  alias NexExamplesTestSupport.Config

  def root(%Config{cwd: cwd}) do
    Path.join(cwd, "tmp/test_artifacts")
  end

  def logs_dir(%Config{} = config) do
    Path.join(root(config), "logs")
  end

  def log_path(%Config{} = config) do
    Path.join(logs_dir(config), "server.log")
  end

  def command_log_path(%Config{} = config, name) do
    Path.join([root(config), "commands", "#{name}.log"])
  end

  def ensure!(%Config{} = config) do
    File.mkdir_p!(logs_dir(config))
  end

  def write(%Config{} = config, filename, content) do
    path = Path.join(root(config), filename)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
    path
  end
end
