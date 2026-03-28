defmodule E2E.Root do
  @repo_root Path.expand("../../..", __DIR__)
  @project_root Path.expand("../..", __DIR__)

  def repo_root, do: @repo_root
  def project_root, do: @project_root

  def repo_path(parts) when is_list(parts) do
    Path.join([@repo_root | parts])
  end

  def repo_path(part) when is_binary(part) do
    Path.join(@repo_root, part)
  end
end
