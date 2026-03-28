defmodule NexValidatorExample.E2ETest do
  use NexValidatorExample.ExampleCase

  test "shows field-level validation feedback and accepts a valid form", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_has_test_id(home.body, "validator-page")

    {invalid_email, _jar} =
      HTTP.post(client, "/validate",
        form: %{"email" => "not-an-email"},
        headers: HTTP.nex_headers(home.body, htmx: true, target: "#error-email")
      )

    assert_test_id_contains(invalid_email.body, "validator-error-email", "must be a valid email")

    {valid_email, _jar} =
      HTTP.post(client, "/validate",
        form: %{"email" => "exunit@example.com"},
        headers: HTTP.nex_headers(home.body, htmx: true, target: "#error-email")
      )

    assert_test_id_text(valid_email.body, "validator-error-email", "")

    {valid_form, _jar} =
      HTTP.post(client, "/validate",
        form: %{
          "name" => "ExUnit User",
          "email" => "exunit@example.com",
          "age" => "24",
          "password" => "secret123",
          "website" => "https://nex.example"
        },
        headers: HTTP.nex_headers(home.body, htmx: true, target: "#form-status")
      )

    assert_test_id_contains(valid_form.body, "validator-form-status", "Registration looks good")
  end
end
