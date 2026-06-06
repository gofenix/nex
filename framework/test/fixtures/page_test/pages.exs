defmodule PageTestApp.Pages.Index do
  use Nex

  def mount(_params), do: %{title: "Home"}
  def render(assigns), do: {:safe, "<h1>#{assigns.title}</h1>"}

  def increment(_req) do
    Nex.html("<p>incremented</p>")
  end

  def redirect_action(_req), do: {:redirect, "/home"}

  def refresh_action(_req), do: {:refresh, true}

  def empty_action(_req), do: :empty

  def json_action(_req), do: Nex.json(%{ok: true})
end

defmodule PageTestApp.Pages.RedirectTest do
  use Nex

  def mount(_params), do: {:redirect, "/login"}
  def render(assigns), do: "should not see this"
end

defmodule PageTestApp.Pages.RedirectStatus do
  use Nex

  def mount(_params), do: {:redirect, "/moved", 301}
  def render(assigns), do: "should not see this"
end

defmodule PageTestApp.Pages.NotFound do
  use Nex

  def mount(_params), do: :not_found
  def render(assigns), do: "should not see this"
end

defmodule PageTestApp.Pages.NoMount do
  use Nex
  # Intentionally no mount/1 — should default to %{}

  def render(assigns) do
    assigns = Map.put_new(assigns, :name, "world")
    {:safe, "<p>Hello #{assigns.name}</p>"}
  end
end

defmodule PageTestApp.Pages.Action do
  use Nex

  def mount(_params), do: %{count: 0}
  def render(assigns), do: "Count: #{assigns.count}"

  def increment(_req) do
    Nex.html("<p>incremented</p>")
  end

  def redirect_action(_req), do: {:redirect, "/home"}

  def refresh_action(_req), do: {:refresh, true}

  def empty_action(_req), do: :empty

  def json_action(_req), do: Nex.json(%{ok: true})
end

defmodule PageTestApp.Api.Health do
  use Nex

  def get(_req), do: Nex.json(%{status: "ok"})
  def post(_req), do: Nex.json(%{created: true}, status: 201)
end

defmodule PageTestApp.Pages.App do
  def render(assigns) do
    "<app>#{assigns.inner_content}</app>"
  end
end

defmodule PageTestApp.Pages.Document do
  def render(assigns) do
    "<!DOCTYPE custom><head><title>#{assigns.title}</title></head><body>#{assigns.inner_content}</body>"
  end
end
