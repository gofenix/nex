defmodule Todos.E2ETest do
  use Todos.ExampleCase

  test "creates, toggles, and deletes todos", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_status(home, 200)
    assert_has_test_id(home.body, "todos-page")

    todo_text = "Ship E2E #{System.unique_integer([:positive])}"
    headers = HTTP.nex_headers(home.body, htmx: true, target: "#todo-list")

    {created, _jar} =
      HTTP.post(client, "/create_todo",
        form: %{"text" => todo_text},
        headers: headers
      )

    todo_id =
      created.body
      |> first_test_id_with_prefix("todo-item-")
      |> String.replace("todo-item-", "")

    assert_has_test_id(created.body, "todo-item-#{todo_id}")
    assert_test_id_text(created.body, "todo-text-#{todo_id}", todo_text)

    {toggled, _jar} =
      HTTP.post(client, "/toggle_todo",
        form: %{"id" => todo_id},
        headers: HTTP.nex_headers(home.body, htmx: true, target: "#todo-#{todo_id}")
      )

    assert attr_at(toggled.body, "todo-text-#{todo_id}", "class") =~ "line-through"

    {deleted, _jar} =
      HTTP.post(client, "/delete_todo",
        form: %{"id" => todo_id},
        headers: HTTP.nex_headers(home.body, htmx: true, target: "#todo-#{todo_id}")
      )

    assert_status(deleted, 200)
    assert deleted.body == ""

    {after_delete, _jar} = HTTP.get(client, "/")
    refute has_test_id?(after_delete.body, "todo-item-#{todo_id}")
  end
end
