defmodule NexAI.Tool do
  @moduledoc "Defines a tool for AI models."
  defstruct [:name, :description, :parameters, :execute]

  def new(opts) do
    struct!(__MODULE__, opts)
  end
end
