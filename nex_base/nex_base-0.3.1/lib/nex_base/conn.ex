defmodule NexBase.Conn do
  @moduledoc """
  Represents a database connection configuration.

  Created by `NexBase.init/1` and piped through query chains:

      conn = NexBase.init(url: "postgres://localhost/mydb")
      conn |> NexBase.from("users") |> NexBase.run()
  """

  @type t :: %__MODULE__{
          name: atom(),
          adapter: :postgres | :sqlite,
          repo_module: module(),
          repo_config: keyword()
        }

  defstruct [:name, :adapter, :repo_module, :repo_config]
end
