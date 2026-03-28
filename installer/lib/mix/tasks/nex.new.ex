defmodule Mix.Tasks.Nex.New do
  @moduledoc """
  Creates a new Nex project.

  ## Usage

      mix nex.new my_app                 # default: basic starter
      mix nex.new my_app --starter saas
      mix nex.new my_app --path ~/projects

  ## Options

      --path PATH          Directory to create project in (default: current directory)
      --starter STARTER   Project template to generate (default: basic)
                          basic = minimal scaffold for learning Nex
                          saas  = auth + database + dashboard starter

  ## Installation

      cd installer
      mix archive.build
      mix archive.install
  """

  use Mix.Task

  alias Nex.New.{Generator, Messages, Options}

  @shortdoc "Create a new Nex project"

  def run([]) do
    Mix.raise(
      "Expected project name. Usage: mix nex.new my_app [--path PATH] [--starter STARTER]"
    )
  end

  def run(args) do
    %{assigns: assigns, name: name, project_path: project_path, starter: starter} =
      Options.parse!(args)

    Mix.shell().info("\n🚀 Creating Nex project: #{name}#{Options.starter_label(starter)}\n")
    Generator.create_project(project_path, assigns, starter)
    maybe_init_git(project_path)
    maybe_install_deps(project_path, name, starter)
  end

  defp maybe_init_git(project_path) do
    if System.find_executable("git") do
      Mix.shell().info("\n🌿 Initializing Git repository...\n")

      case System.cmd("git", ["init"], cd: project_path, stderr_to_stdout: true) do
        {_, 0} -> :ok
        {error, _} -> Mix.shell().error("Git init failed: #{error}")
      end
    end
  end

  defp maybe_install_deps(project_path, name, starter) do
    Mix.shell().info("\n📦 Installing dependencies...\n")

    if Options.skip_deps_install?() do
      Mix.shell().info(Messages.success_message(name, starter, false))
    else
      case System.cmd("mix", ["deps.get"], cd: project_path, stderr_to_stdout: true) do
        {_, 0} ->
          Mix.shell().info(Messages.success_message(name, starter, true))

        {error, _} ->
          Mix.raise("""
          Dependencies installation failed!

          Error: #{error}

          You can try installing manually:
              cd #{name}
              mix deps.get
          """)
      end
    end
  end
end
