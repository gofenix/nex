defmodule E2E.Artifacts do
  alias E2E.Root

  def root do
    Root.repo_path(["e2e", "artifacts"])
  end

  def logs_dir do
    Path.join(root(), "logs")
  end

  def example_dir(example_name) do
    Path.join(root(), example_name)
  end

  def log_path(example) do
    Path.join(logs_dir(), "#{example.name}.log")
  end

  def ensure! do
    File.mkdir_p!(logs_dir())
  end

  def write(example, filename, content) do
    path = Path.join(example_dir(example.name), filename)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, content)
    path
  end
end
