defmodule Nex.New.Template.Shared do
  @moduledoc false

  alias Nex.New.Legacy

  def gitignore, do: Legacy.gitignore()
  def dockerignore, do: Legacy.dockerignore()
  def dockerfile, do: Legacy.dockerfile()
  def env_example, do: Legacy.env_example()
  def formatter_exs, do: Legacy.formatter_exs()
  def ai_onboarding_dirs(path), do: Legacy.ai_onboarding_dirs(path)
  def ai_onboarding_files(assigns), do: Legacy.ai_onboarding_files(assigns)
  def agents_md(assigns), do: Legacy.agents_md(assigns)
end
