defmodule Nex.Response do
  @moduledoc """
  Standardized Response object.
  """
  defstruct status: 200, body: nil, headers: %{}, content_type: "application/json"
end
