defmodule E2E.AuthDemoTest do
  use E2E.ExampleCase, example: "auth_demo"

  test "protects the dashboard, logs in, and logs out", %{
    client: client,
    cookie_jar: jar
  } do
    {redirected, jar} = HTTP.get(client, "/dashboard", jar: jar)
    assert_redirect(redirected, "/login")

    {login_page, jar} = HTTP.get(client, "/login", jar: jar)
    assert_status(login_page, 200)
    assert_has_test_id(login_page.body, "auth-login-page")
    assert_test_id_contains(login_page.body, "auth-login-flash-error", "Please log in")

    login_headers =
      HTTP.nex_headers(login_page.body, htmx: true, target: "body", referer: "/login")

    {login_redirect, jar} =
      HTTP.post(client, "/login",
        form: %{"email" => "admin@example.com", "password" => "password"},
        headers: login_headers,
        jar: jar
      )

    assert_redirect(login_redirect, "/dashboard")

    {dashboard, jar} = HTTP.get(client, "/dashboard", jar: jar)
    assert_has_test_id(dashboard.body, "auth-dashboard-page")
    assert_test_id_text(dashboard.body, "auth-dashboard-user-name", "Admin User")
    assert_test_id_text(dashboard.body, "auth-dashboard-visit-count", "1")
    assert_test_id_contains(dashboard.body, "auth-dashboard-flash-success", "Welcome back")

    {dashboard_again, jar} = HTTP.get(client, "/dashboard", jar: jar)
    assert_test_id_text(dashboard_again.body, "auth-dashboard-visit-count", "2")

    {logged_in_home, jar} = HTTP.get(client, "/", jar: jar)
    assert_has_test_id(logged_in_home.body, "auth-home-page")
    assert_test_id_contains(logged_in_home.body, "auth-session-state", "Logged in as")

    logout_headers = HTTP.nex_headers(logged_in_home.body, htmx: true, target: "body")
    {logout_redirect, jar} = HTTP.post(client, "/logout", headers: logout_headers, jar: jar)
    assert_redirect(logout_redirect, "/")

    {logged_out_home, jar} = HTTP.get(client, "/", jar: jar)
    assert_has_test_id(logged_out_home.body, "auth-home-page")
    assert_test_id_contains(logged_out_home.body, "auth-session-state", "Not logged in")

    {redirected_again, _jar} = HTTP.get(client, "/dashboard", jar: jar)
    assert_redirect(redirected_again, "/login")
  end
end
