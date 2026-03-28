defmodule NexWebsite.Version do
  @repo_root Path.expand("../../..", __DIR__)
  @version_path Path.join(@repo_root, "VERSION")
  @current_version @version_path |> File.read!() |> String.trim()

  def current do
    @current_version
  end
end
