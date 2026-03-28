defmodule Nex.New.Options do
  @moduledoc false

  alias Nex.New.Legacy

  def parse!(args) do
    {opts, parsed_args, _} =
      OptionParser.parse(args, switches: [path: :string, starter: :string])

    name =
      case parsed_args do
        [project_name | _] ->
          project_name

        [] ->
          Mix.raise(
            "Expected project name. Usage: mix nex.new my_app [--path PATH] [--starter STARTER]"
          )
      end

    unless Legacy.valid_name?(name) do
      Mix.raise(
        "Project name must start with a letter and contain only lowercase letters, numbers, and underscores. Reserved names (elixir, mix, nex, etc.) are not allowed."
      )
    end

    starter = Legacy.normalize_starter(opts[:starter])
    base_path = opts[:path] || "."
    project_path = Path.expand(Path.join(base_path, name))

    if File.dir?(project_path) do
      Mix.raise("Directory #{project_path} already exists")
    end

    %{
      name: name,
      starter: starter,
      project_path: project_path,
      assigns: %{app_name: name, module_name: Macro.camelize(name)}
    }
  end

  def starter_label(starter), do: Legacy.starter_label(starter)
  def skip_deps_install?, do: Legacy.skip_deps_install?()
end
