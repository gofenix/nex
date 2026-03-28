defmodule AlpineDemo.E2ETest do
  use AlpineDemo.ExampleCase

  test "renders Alpine contracts and persists added users", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_status(home, 200)
    assert_has_test_id(home.body, "alpine-page")
    assert_has_test_id(home.body, "alpine-users-panel")
    assert_has_test_id(home.body, "alpine-profile-panel")
    assert_has_test_id(home.body, "alpine-user-modal")
    assert_has_test_id(home.body, "alpine-profile-settings")
    assert attr_at(home.body, "alpine-page", "x-data") =~ "currentTab"

    name = "ExUnit User #{System.unique_integer([:positive])}"
    email = "exunit-#{System.unique_integer([:positive])}@example.com"
    create_headers = HTTP.nex_headers(home.body, htmx: true, target: "#user-list")

    {created, _jar} =
      HTTP.post(client, "/create_user",
        form: %{"name" => name, "email" => email},
        headers: create_headers
      )

    user_id =
      created.body
      |> first_test_id_with_prefix("alpine-user-row-")
      |> String.replace("alpine-user-row-", "")

    assert_has_test_id(created.body, "alpine-user-row-#{user_id}")
    assert_test_id_text(created.body, "alpine-user-name-#{user_id}", name)
    assert_test_id_text(created.body, "alpine-user-email-#{user_id}", email)

    {after_reload, _jar} = HTTP.get(client, "/")
    assert_has_test_id(after_reload.body, "alpine-user-row-#{user_id}")
    assert_test_id_text(after_reload.body, "alpine-user-name-#{user_id}", name)

    {updated, _jar} =
      HTTP.put(client, "/update_settings",
        form: %{"bio" => "Updated bio"},
        headers: HTTP.nex_headers(home.body)
      )

    assert_status(updated, 200)
    assert updated.body == ""
  end
end
