defmodule Nex.New.Generator do
  @moduledoc false

  alias Nex.New.Template.{Basic, Saas}

  def create_project(path, assigns, starter) do
    path
    |> project_dirs(starter)
    |> Enum.each(fn dir ->
      File.mkdir_p!(dir)
      Mix.shell().info("  Created: #{dir}/")
    end)

    assigns
    |> project_files(starter)
    |> Enum.each(fn {file, content} ->
      full_path = Path.join(path, file)
      File.write!(full_path, content)
      Mix.shell().info("  Created: #{full_path}")
    end)
  end

  defp project_dirs(path, :basic), do: Basic.project_dirs(path)
  defp project_dirs(path, :saas), do: Saas.project_dirs(path)

  defp project_files(assigns, :basic), do: Basic.project_files(assigns)
  defp project_files(assigns, :saas), do: Saas.project_files(assigns)
end
