defmodule Nex.Req do
  @moduledoc """
  Standardized Request object mimicking Web Standards.
  """
  defstruct [
    :params,      # Merged path, query, and body params (Plug behavior)
    :query,       # Merged path and query params (Next.js req.query behavior)
    :body,        # Body params (Next.js req.body behavior)
    :path_params, # Only path params (Map)
    :query_params,# Only query params (Map)
    :body_params, # Only body params (Map) - Same as :body
    :headers,     # Request headers (Map, lowercase keys)
    :cookies,     # Request cookies (Map)
    :method,      # HTTP method (String, uppercase)
    :path,        # Request path (String)
    :private      # Framework internal data (Map)
  ]

  @doc """
  Constructs a Nex.Req from a Plug.Conn.
  """
  def from_plug_conn(%Plug.Conn{} = conn, path_params \\ %{}) do
    # Ensure params and cookies are fetched
    conn = conn
      |> Plug.Conn.fetch_query_params()
      |> Plug.Conn.fetch_cookies()
    
    # Standardize headers to a Map with lowercase keys
    headers = Map.new(conn.req_headers)

    # Next.js style req.query: path params + query string
    query = Map.merge(conn.query_params, path_params)

    %__MODULE__{
      # Convenience: merge everything into params for easy access (Plug style)
      params: Map.merge(conn.params, path_params),
      
      # Next.js style
      query: query,
      body: conn.body_params,

      # Explicit parts
      path_params: path_params,
      query_params: conn.query_params,
      body_params: conn.body_params,
      
      headers: headers,
      cookies: conn.cookies, 
      method: conn.method,
      path: conn.request_path,
      private: conn.private
    }
  end
end
