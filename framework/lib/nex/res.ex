defmodule Nex.Res do
  @moduledoc """
  Pipeline-style response builder for API routes.

  An alternative to `Nex.json/2`, `Nex.html/2`, etc. that uses
  Elixir pipe syntax to build responses incrementally.

  ## Examples

      def get(req) do
        Nex.Res.new()
        |> Nex.Res.json(%{users: list_users()})
      end

      def post(req) do
        Nex.Res.new()
        |> Nex.Res.status(201)
        |> Nex.Res.json(%{created: true})
      end

      def delete(req) do
        Nex.Res.new()
        |> Nex.Res.status(204)
        |> Nex.Res.send("")
      end

      def get(req) do
        Nex.Res.new()
        |> Nex.Res.redirect("/login")
      end

      def get(req) do
        Nex.Res.new()
        |> Nex.Res.set_header("x-request-id", "abc123")
        |> Nex.Res.status(200)
        |> Nex.Res.json(%{ok: true})
      end
  """

  alias Nex.Response

  @doc "Creates a new response with default values (200 OK, empty body)."
  @spec new() :: Response.t()
  def new, do: %Response{}

  @doc "Sets the HTTP status code."
  @spec status(Response.t(), non_neg_integer()) :: Response.t()
  def status(%Response{} = res, code) when is_integer(code), do: %{res | status: code}

  @doc "Sets a JSON response body and content type."
  @spec json(Response.t(), term()) :: Response.t()
  def json(%Response{} = res, data), do: %{res | body: data, content_type: "application/json"}

  @doc "Sets an HTML response body and content type."
  @spec html(Response.t(), String.t()) :: Response.t()
  def html(%Response{} = res, content), do: %{res | body: content, content_type: "text/html"}

  @doc "Sets a plain text response body and content type."
  @spec text(Response.t(), String.t()) :: Response.t()
  def text(%Response{} = res, content), do: %{res | body: content, content_type: "text/plain"}

  @doc "Sets the response body without changing content type."
  @spec send(Response.t(), term()) :: Response.t()
  def send(%Response{} = res, body), do: %{res | body: body}

  @doc "Sets a redirect response with Location header."
  @spec redirect(Response.t(), String.t(), non_neg_integer()) :: Response.t()
  def redirect(%Response{} = res, url, status \\ 302) do
    %{res | status: status, body: "", headers: Map.put(res.headers, "location", url), content_type: "text/html"}
  end

  @doc "Sets a response header."
  @spec set_header(Response.t(), String.t(), String.t()) :: Response.t()
  def set_header(%Response{} = res, key, value) do
    %{res | headers: Map.put(res.headers, key, value)}
  end
end
