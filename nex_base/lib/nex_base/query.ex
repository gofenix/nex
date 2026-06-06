defmodule NexBase.Query do
  @moduledoc """
  Struct representing the intermediate state of a NexBase query.
  """

  @type filter :: {atom(), atom(), term()}

  @type order_clause :: {:asc | :desc, atom()} | {:asc | :desc, atom(), keyword()}

  @type upsert_opts :: [
          on_conflict: atom() | [atom()],
          ignore_duplicates: boolean(),
          default_to_null: boolean()
        ]

  @type explain_opts :: [
          analyze: boolean(),
          verbose: boolean(),
          settings: boolean(),
          buffers: boolean(),
          wal: boolean(),
          format: :text | :json
        ]

  @type t :: %__MODULE__{
          table: String.t() | nil,
          conn: NexBase.Conn.t() | nil,
          schema: String.t() | nil,
          select: [atom() | String.t()],
          filters: [filter()],
          or_filters: [[filter()] | {[filter()], referenced_table: String.t()}],
          not_filters: [filter()],
          order_by: [order_clause() | {order_clause(), referenced_table: String.t()}],
          limit: non_neg_integer() | nil,
          limit_referenced_table: String.t() | nil,
          offset: non_neg_integer() | nil,
          offset_referenced_table: String.t() | nil,
          count: nil | :exact | :planned | :estimated,
          single: boolean(),
          maybe_single: boolean(),
          data: map() | [map()] | nil,
          type: :select | :insert | :update | :delete | :upsert,
          returning: boolean(),
          upsert_opts: upsert_opts(),
          default_to_null: boolean(),
          explain_opts: explain_opts() | nil,
          csv: boolean(),
          geojson: boolean(),
          rollback: boolean(),
          head: boolean(),
          max_affected: non_neg_integer() | nil,
          throw_on_error: boolean()
        }

  defstruct [
    :table,
    :conn,
    :schema,
    select: [],
    filters: [],
    or_filters: [],
    not_filters: [],
    order_by: [],
    limit: nil,
    limit_referenced_table: nil,
    offset: nil,
    offset_referenced_table: nil,
    count: nil,
    single: false,
    maybe_single: false,
    data: nil,
    type: :select,
    returning: false,
    upsert_opts: [],
    default_to_null: true,
    explain_opts: nil,
    csv: false,
    geojson: false,
    rollback: false,
    head: false,
    max_affected: nil,
    throw_on_error: false
  ]
end
