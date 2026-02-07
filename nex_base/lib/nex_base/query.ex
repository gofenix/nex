defmodule NexBase.Query do
  @moduledoc """
  Struct to hold the intermediate state of a NexBase query.
  """
  defstruct [
    :table,
    select: [],
    filters: [],
    order_by: [],
    limit: nil,
    offset: nil,
    data: nil,
    type: :select
  ]
end
