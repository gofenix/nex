defmodule NexAI.Tool do
  @moduledoc """
  Defines an AI Tool (Function).
  """
  defstruct [:name, :description, :parameters, :execute]

  def new(opts) do
    struct!(__MODULE__, opts)
  end
end
