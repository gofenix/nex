defmodule ErrorPagesExample.E2ETest do
  use ErrorPagesExample.ExampleCase

  test "renders custom 404, 403, and 500 pages", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_has_test_id(home.body, "error-pages-page")

    {not_found, _jar} = HTTP.get(client, "/this-page-does-not-exist")
    assert_status(not_found, 404)
    assert_has_test_id(not_found.body, "error-page-404")

    {forbidden, _jar} = HTTP.post(client, "/forbidden")
    assert_status(forbidden, 403)
    assert_has_test_id(forbidden.body, "error-page-403")

    {server_error, _jar} = HTTP.get(client, "/cause_error")
    assert_status(server_error, 500)
    assert_has_test_id(server_error.body, "error-page-500")
  end
end
