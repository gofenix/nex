defmodule Nex.New.Template.Basic do
  @moduledoc false

  alias Nex.New.Legacy
  alias Nex.New.Template.Shared

  def project_dirs(path) do
    [path, "#{path}/src", "#{path}/src/pages", "#{path}/src/api", "#{path}/src/components"]
  end

  def project_files(assigns) do
    [
      {"mix.exs", Legacy.mix_exs(assigns)},
      {"src/application.ex", Legacy.application(assigns)},
      {"src/layouts.ex", Legacy.layouts(assigns)},
      {"src/pages/index.ex", Legacy.index(assigns)},
      {"src/api/hello.ex", Legacy.api_hello(assigns)},
      {"src/components/card.ex", Legacy.component_card(assigns)},
      {".gitignore", Shared.gitignore()},
      {".dockerignore", Shared.dockerignore()},
      {"Dockerfile", Shared.dockerfile()},
      {".env.example", Shared.env_example()},
      {".formatter.exs", Shared.formatter_exs()},
      {"AGENTS.md", Shared.agents_md(assigns)},
      {"README.md", Legacy.readme(assigns)}
    ]
  end
end
