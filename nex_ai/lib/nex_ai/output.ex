defmodule NexAI.Output do
  @moduledoc "Defines output modes for NexAI."
  def object(schema), do: %{mode: :object, schema: schema}
  def array(schema), do: %{mode: :array, schema: schema}
end
