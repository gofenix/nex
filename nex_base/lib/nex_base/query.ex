defmodule NexBase.Query do
  @moduledoc """
  Struct representing the intermediate state of a NexBase query.

  This is an internal data structure used by `NexBase` to accumulate
  query parameters before execution via `NexBase.run/1`.
  """

  @type filter :: {atom(), atom(), term()}

  @type t :: %__MODULE__{
          table: String.t() | nil,
          select: [atom() | String.t()],
          filters: [filter()],
          order_by: [{:asc | :desc, atom()}],
          limit: non_neg_integer() | nil,
          offset: non_neg_integer() | nil,
          data: map() | [map()] | nil,
          type: :select | :insert | :update | :delete | :upsert
        }

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
