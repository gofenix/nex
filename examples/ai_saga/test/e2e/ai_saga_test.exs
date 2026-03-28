defmodule AiSaga.E2ETest do
  use AiSaga.ExampleCase

  test "renders the homepage with seeded paper data", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_status(home, 200)
    assert_has_test_id(home.body, "ai-saga-page")
    assert home.body =~ "AI Saga"
    assert home.body =~ "Attention Is All You Need"
  end
end
