defmodule E2E.GuestbookTest do
  use E2E.ExampleCase, example: "guestbook"

  test "creates and deletes guestbook messages", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_status(home, 200)
    assert_has_test_id(home.body, "guestbook-page")
    assert_has_test_id(home.body, "guestbook-empty")

    visitor = "Visitor #{System.unique_integer([:positive])}"
    content = "Guestbook message from ExUnit"
    create_headers = HTTP.nex_headers(home.body, htmx: true, target: "#message-list")

    {created, _jar} =
      HTTP.post(client, "/create_message",
        form: %{"name" => visitor, "content" => content},
        headers: create_headers
      )

    message_id =
      created.body
      |> first_test_id_with_prefix("guestbook-message-")
      |> String.replace("guestbook-message-", "")

    assert_has_test_id(created.body, "guestbook-message-#{message_id}")
    assert_test_id_text(created.body, "guestbook-author-#{message_id}", visitor)
    assert_test_id_text(created.body, "guestbook-message-content-#{message_id}", content)

    {deleted, _jar} =
      HTTP.delete(client, "/delete_message?id=#{message_id}",
        headers: HTTP.nex_headers(home.body, htmx: true, target: "#message-#{message_id}")
      )

    assert_status(deleted, 200)
    assert deleted.body == ""

    {after_delete, _jar} = HTTP.get(client, "/")
    assert_has_test_id(after_delete.body, "guestbook-empty")
  end
end
