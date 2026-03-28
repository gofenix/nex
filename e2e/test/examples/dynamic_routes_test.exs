defmodule E2E.DynamicRoutesTest do
  use E2E.ExampleCase, example: "dynamic_routes"

  test "renders representative dynamic routes and API responses", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_has_test_id(home.body, "dynamic-routes-page")

    {user_page, _jar} = HTTP.get(client, "/users/1")
    assert_has_test_id(user_page.body, "dynamic-user-page")
    assert_test_id_text(user_page.body, "dynamic-user-name", "Zhang San")

    {followed, _jar} =
      HTTP.post(client, "/users/1/follow",
        form: %{"id" => "1"},
        headers: HTTP.nex_headers(user_page.body, htmx: true, target: "#follow-button")
      )

    assert_test_id_contains(followed.body, "dynamic-follow-button", "Already Followed")

    {post_page, _jar} = HTTP.get(client, "/posts/hello-world")
    assert_has_test_id(post_page.body, "dynamic-post-page")
    assert_test_id_contains(post_page.body, "dynamic-post-title", "Hello World")

    {docs_page, _jar} = HTTP.get(client, "/docs/getting-started/install")
    assert_has_test_id(docs_page.body, "dynamic-docs-page")
    assert_test_id_contains(docs_page.body, "dynamic-docs-path", "/getting-started/install")
    assert_test_id_contains(docs_page.body, "dynamic-docs-content", "Content is being written")

    {api_response, _jar} = HTTP.get(client, "/api/users/1")
    assert_status(api_response, 200)

    payload = HTTP.json_body(api_response)
    assert payload["data"]["name"] == "Zhang San"
    assert payload["data"]["city"] == "Beijing"
  end
end
