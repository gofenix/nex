defmodule RatelimitExample.ExampleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use NexExamplesTestSupport.Case, port: 4208
    end
  end
end
