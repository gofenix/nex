defmodule NexBase.Client do
  @moduledoc """
  NexBase client - similar to Supabase client initialization.

  Usage:
    client = NexBase.Client.new(repo: MyApp.Repo)

    client
    |> NexBase.from("users")
    |> NexBase.select(["id", "name"])
    |> NexBase.eq("active", true)
    |> NexBase.run()
  """

  defstruct [:repo]

  @doc """
  Initialize a NexBase client with a repository.
  """
  def new(opts) do
    repo = Keyword.fetch!(opts, :repo)
    %__MODULE__{repo: repo}
  end
end
