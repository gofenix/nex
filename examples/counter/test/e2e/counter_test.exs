defmodule Counter.E2ETest do
  use Counter.ExampleCase

  test "increments, decrements, and resets the counter", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_status(home, 200)
    assert_has_test_id(home.body, "counter-page")
    assert_test_id_text(home.body, "counter-value", "0")

    headers = HTTP.nex_headers(home.body, htmx: true, target: "#counter-display")

    {increment, _jar} = HTTP.post(client, "/increment", headers: headers)
    assert_test_id_text(increment.body, "counter-value", "1")

    {decrement, _jar} = HTTP.post(client, "/decrement", headers: headers)
    assert_test_id_text(decrement.body, "counter-value", "0")

    {still_zero, _jar} = HTTP.post(client, "/decrement", headers: headers)
    assert_test_id_text(still_zero.body, "counter-value", "0")

    {_, _jar} = HTTP.post(client, "/increment", headers: headers)
    {two, _jar} = HTTP.post(client, "/increment", headers: headers)
    assert_test_id_text(two.body, "counter-value", "2")

    {reset, _jar} = HTTP.post(client, "/reset", headers: headers)
    assert_test_id_text(reset.body, "counter-value", "0")
  end
end
