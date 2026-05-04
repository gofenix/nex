defmodule Nex.New.Template.Basic do
  @moduledoc false

  alias Nex.New.Legacy
  alias Nex.New.Template.Shared

  def project_dirs(path) do
    [
      path,
      "#{path}/src",
      "#{path}/src/pages",
      "#{path}/src/api",
      "#{path}/src/components"
      | Shared.ai_onboarding_dirs(path)
    ]
  end

  def project_files(%{frontend: :datastar} = assigns) do
    [
      {"mix.exs", Legacy.mix_exs(assigns)},
      {"src/application.ex", Legacy.application(assigns)},
      {"src/pages/_app.ex", Legacy.datastar_app_template(assigns)},
      {"src/pages/_document.ex", Legacy.datastar_document_template(assigns)},
      {"src/pages/index.ex", Legacy.datastar_index(assigns)},
      {"src/api/counter.ex", Legacy.datastar_api_counter(assigns)},
      {"src/api/hello.ex", Legacy.api_hello(assigns)},
      {"src/components/card.ex", Legacy.component_card(assigns)},
      {".gitignore", Shared.gitignore()},
      {".dockerignore", Shared.dockerignore()},
      {"Dockerfile", Shared.dockerfile()},
      {".env.example", Shared.env_example()},
      {".formatter.exs", Shared.formatter_exs()},
      {"README.md", Legacy.readme(assigns)}
      | Shared.ai_onboarding_files(assigns)
    ]
  end

  def project_files(assigns) do
    [
      {"mix.exs", Legacy.mix_exs(assigns)},
      {"src/application.ex", Legacy.application(assigns)},
      {"src/pages/_app.ex", Legacy.app_template(assigns)},
      {"src/pages/_document.ex", Legacy.document_template(assigns)},
      {"src/pages/index.ex", Legacy.index(assigns)},
      {"src/api/hello.ex", Legacy.api_hello(assigns)},
      {"src/components/card.ex", Legacy.component_card(assigns)},
      {".gitignore", Shared.gitignore()},
      {".dockerignore", Shared.dockerignore()},
      {"Dockerfile", Shared.dockerfile()},
      {".env.example", Shared.env_example()},
      {".formatter.exs", Shared.formatter_exs()},
      {"README.md", Legacy.readme(assigns)}
      | Shared.ai_onboarding_files(assigns)
    ]
  end
end
