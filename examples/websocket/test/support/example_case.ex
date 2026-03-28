defmodule NexWebsocketExample.ExampleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use NexExamplesTestSupport.Case, port: 4213
    end
  end
end
