defmodule ErrorPagesExample.ExampleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use NexExamplesTestSupport.Case, port: 4206
    end
  end
end
