defmodule TodosApi.ExampleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use NexExamplesTestSupport.Case, port: 4210
    end
  end
end
