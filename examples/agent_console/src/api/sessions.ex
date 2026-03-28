defmodule AgentConsole.Api.Sessions do
  use Nex

  def delete(req) do
    session_key = req.path_params["key"]

    Nex.Agent.SessionManager.invalidate(session_key)
    Nex.Agent.SessionManager.save(Nex.Agent.Session.new(session_key))

    Nex.json(%{success: true})
  end
end
