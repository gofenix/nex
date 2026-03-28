defmodule E2E.TodosApiTest do
  use E2E.ExampleCase, example: "todos_api"

  test "supports CRUD operations through the JSON API", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_has_test_id(home.body, "todos-api-page")

    {created, _jar} =
      HTTP.post(client, "/api/todos", json: %{"text" => "Review ExUnit harness"})

    assert_status(created, 201)
    created_payload = HTTP.json_body(created)
    todo_id = created_payload["data"]["id"]

    {listed, _jar} = HTTP.get(client, "/api/todos")
    assert_status(listed, 200)
    list_payload = HTTP.json_body(listed)
    assert Enum.any?(list_payload["data"], &(&1["id"] == todo_id))

    {updated, _jar} =
      HTTP.put(client, "/api/todos/#{todo_id}", json: %{"completed" => true})

    assert_status(updated, 200)
    assert HTTP.json_body(updated)["data"]["completed"] == true

    {shown, _jar} = HTTP.get(client, "/api/todos/#{todo_id}")
    assert_status(shown, 200)
    assert HTTP.json_body(shown)["data"]["completed"] == true

    {deleted, _jar} = HTTP.delete(client, "/api/todos/#{todo_id}")
    assert_status(deleted, 204)

    {missing, _jar} = HTTP.get(client, "/api/todos/#{todo_id}")
    assert_status(missing, 404)
  end
end
