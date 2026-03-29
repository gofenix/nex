defmodule DatastarDemo.ExampleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use NexExamplesTestSupport.Case, port: 4217
    end
  end
end
