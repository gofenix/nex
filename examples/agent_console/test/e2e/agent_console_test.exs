defmodule AgentConsole.E2ETest do
  use AgentConsole.ExampleCase

  test "renders the chat shell and sessions page", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_status(home, 200)
    assert_has_test_id(home.body, "agent-console-page")
    assert home.body =~ "Agent Console"

    {sessions, _jar} = HTTP.get(client, "/sessions")
    assert_status(sessions, 200)
    assert_has_test_id(sessions.body, "agent-console-sessions-page")
    assert sessions.body =~ "Session Management"
  end
end
