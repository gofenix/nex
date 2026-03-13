defmodule ErrorPagesExample.Application do
  use Application

  def start(_type, _args) do
    # Configure custom error page module
    Application.put_env(:nex_core, :error_page_module, ErrorPagesExample.ErrorPages)

    children = []
    Supervisor.start_link(children, strategy: :one_for_one, name: ErrorPagesExample.Supervisor)
  end
end
