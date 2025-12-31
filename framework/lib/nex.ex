defmodule Nex do
  @moduledoc """
  Nex - A minimalist Elixir web framework powered by HTMX.
  
  ## Quick Start
  
      # src/pages/index.ex
      defmodule MyApp.Pages.Index do
        use Nex.Page
        
        def render(assigns) do
          ~H\"\"\"
          <h1>Hello, Nex!</h1>
          \"\"\"
        end
      end
  """

  alias Nex.Response

  @doc """
  Constructs a JSON response.
  
  ## Options
    * `:status` - HTTP status code (default: 200)
    * `:headers` - Additional headers (default: %{})
  """
  def json(data, opts \\ []) do
    status = Keyword.get(opts, :status, 200)
    headers = Keyword.get(opts, :headers, %{})
    
    %Response{
      status: status,
      body: data,
      headers: headers,
      content_type: "application/json"
    }
  end

  @doc """
  Constructs a text response.
  """
  def text(text, opts \\ []) do
    status = Keyword.get(opts, :status, 200)
    %Response{
      status: status, 
      body: text,
      content_type: "text/plain"
    }
  end

  @doc """
  Constructs a redirect response.
  """
  def redirect(to, opts \\ []) do
    status = Keyword.get(opts, :status, 302)
    %Response{
      status: status,
      body: "",
      headers: %{"location" => to},
      content_type: "text/html"
    }
  end
  
  @doc """
  Constructs a response with only a status code.
  """
  def status(code) do
    %Response{status: code, body: ""}
  end
end
