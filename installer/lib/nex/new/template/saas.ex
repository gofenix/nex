defmodule Nex.New.Template.Saas do
  @moduledoc false

  alias Nex.New.Legacy
  alias Nex.New.Template.Shared

  def project_dirs(path) do
    [
      path,
      "#{path}/db",
      "#{path}/src",
      "#{path}/src/api",
      "#{path}/src/components",
      "#{path}/src/pages",
      "#{path}/src/plugs"
    ]
  end

  def project_files(assigns) do
    [
      {"mix.exs", Legacy.saas_mix_exs(assigns)},
      {"src/application.ex", Legacy.saas_application(assigns)},
      {"src/layouts.ex", Legacy.saas_layouts(assigns)},
      {"src/data.ex", Legacy.saas_data(assigns)},
      {"src/accounts.ex", Legacy.saas_accounts(assigns)},
      {"src/workspace.ex", Legacy.saas_workspace(assigns)},
      {"src/plugs/require_auth.ex", Legacy.saas_require_auth(assigns)},
      {"src/components/flash.ex", Legacy.saas_flash_component(assigns)},
      {"src/pages/index.ex", Legacy.saas_index(assigns)},
      {"src/pages/login.ex", Legacy.saas_login(assigns)},
      {"src/pages/signup.ex", Legacy.saas_signup(assigns)},
      {"src/pages/dashboard.ex", Legacy.saas_dashboard(assigns)},
      {"src/api/health.ex", Legacy.saas_api_health(assigns)},
      {"db/.gitkeep", ""},
      {".gitignore", Shared.gitignore()},
      {".dockerignore", Shared.dockerignore()},
      {"Dockerfile", Shared.dockerfile()},
      {".env.example", Legacy.saas_env_example(assigns)},
      {".formatter.exs", Shared.formatter_exs()},
      {"AGENTS.md", Shared.agents_md(assigns)},
      {"README.md", Legacy.saas_readme(assigns)}
    ]
  end
end
