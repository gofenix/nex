defmodule BestofEx.E2ETest do
  use BestofEx.ExampleCase

  test "renders the homepage and trending page with seeded project data", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_status(home, 200)
    assert_has_test_id(home.body, "bestof-ex-page")
    assert home.body =~ "Phoenix Live Dashboard"

    {trending, _jar} = HTTP.get(client, "/trending")
    assert_status(trending, 200)
    assert_has_test_id(trending.body, "bestof-ex-trending-page")
  end
end
