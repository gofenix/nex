defmodule Nex.Response do
  @moduledoc """
  Standardized Response object.
  """

  @type status :: non_neg_integer()
  @type headers :: %{optional(String.t()) => String.t()}
  @type content_type :: String.t()

  @type t :: %__MODULE__{
          status: status(),
          body: term(),
          headers: headers(),
          content_type: content_type()
        }

  defstruct status: 200, body: nil, headers: %{}, content_type: "application/json"
end
