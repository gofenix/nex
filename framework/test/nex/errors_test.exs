defmodule Nex.ErrorsTest do
  use ExUnit.Case, async: false
  import Plug.Test

  alias Nex.Handler.Errors

  setup do
    original_app_module = Application.get_env(:nex_core, :app_module)

    on_exit(fn ->
      if original_app_module do
        Application.put_env(:nex_core, :app_module, original_app_module)
      else
        Application.delete_env(:nex_core, :app_module)
      end
    end)

    :ok
  end

  test "wraps convention error pages with app and document shells" do
    Application.put_env(:nex_core, :app_module, "WrappedErrorPages")

    response =
      conn(:get, "/missing")
      |> Errors.send_error_page(404, "Page Not Found", nil)

    assert response.status == 404
    assert response.resp_body =~ "<html>"
    assert response.resp_body =~ "error-shell"
    assert response.resp_body =~ "Page Not Found"
  end

  test "supports atom app_module configuration for convention error pages" do
    Application.put_env(:nex_core, :app_module, AtomErrorPages)

    response =
      conn(:get, "/missing")
      |> Errors.send_error_page(404, "Page Not Found", nil)

    assert response.status == 404
    assert response.resp_body =~ "atom-shell"
    assert response.resp_body =~ "Page Not Found"
  end

  test "layout/0 returning :none skips the shared app shell" do
    Application.put_env(:nex_core, :app_module, "NoLayoutErrorPages")

    response =
      conn(:get, "/missing")
      |> Errors.send_error_page(404, "Page Not Found", nil)

    assert response.status == 404
    assert response.resp_body =~ "<html>"
    refute response.resp_body =~ "no-layout-shell"
    assert response.resp_body =~ "no-layout-document"
  end

  test "falls back to the default error page when the convention error page crashes" do
    Application.put_env(:nex_core, :app_module, "BrokenErrorPages")

    response =
      conn(:get, "/missing")
      |> Errors.send_error_page(500, "Broken", RuntimeError.exception("boom"))

    assert response.status == 500
    assert response.resp_body =~ "<!DOCTYPE html>"
    assert response.resp_body =~ "Broken"
    refute response.resp_body =~ "broken-document"
  end
end

defmodule WrappedErrorPages.Pages.App do
  def render(assigns), do: "<section class=\"error-shell\">#{assigns.inner_content}</section>"
end

defmodule WrappedErrorPages.Pages.Document do
  def render(assigns), do: "<html><body>#{assigns.inner_content}</body></html>"
end

defmodule WrappedErrorPages.Pages.Error404 do
  def render(assigns), do: "<h1>#{assigns.status} #{assigns.message}</h1>"
end

defmodule AtomErrorPages.Pages.App do
  def render(assigns), do: "<section class=\"atom-shell\">#{assigns.inner_content}</section>"
end

defmodule AtomErrorPages.Pages.Document do
  def render(assigns), do: "<html><body>#{assigns.inner_content}</body></html>"
end

defmodule AtomErrorPages.Pages.Error404 do
  def render(assigns), do: "<h1>#{assigns.status} #{assigns.message}</h1>"
end

defmodule NoLayoutErrorPages.Pages.App do
  def render(assigns), do: "<section class=\"no-layout-shell\">#{assigns.inner_content}</section>"
end

defmodule NoLayoutErrorPages.Pages.Document do
  def render(assigns),
    do: "<html><body class=\"no-layout-document\">#{assigns.inner_content}</body></html>"
end

defmodule NoLayoutErrorPages.Pages.Error404 do
  def layout, do: :none
  def render(assigns), do: "<h1>#{assigns.status} #{assigns.message}</h1>"
end

defmodule BrokenErrorPages.Pages.Document do
  def render(assigns),
    do: "<html><body class=\"broken-document\">#{assigns.inner_content}</body></html>"
end

defmodule BrokenErrorPages.Pages.Error500 do
  def render(_assigns), do: raise("boom")
end
