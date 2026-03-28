defmodule Upload.ExampleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use NexExamplesTestSupport.Case, port: 4211
    end
  end
end
