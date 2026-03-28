defmodule NexValidatorExample.ExampleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use NexExamplesTestSupport.Case, port: 4212
    end
  end
end
