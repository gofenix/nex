defmodule Chatbot.Application do
  @moduledoc """
  The Chatbot application.

  This module defines the application supervision tree.
  Currently supervises:
  - Finch HTTP client (used by Req for OpenAI API calls)
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Finch HTTP client for making API requests
      {Finch, name: MyFinch}
    ]

    opts = [strategy: :one_for_one, name: Chatbot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
