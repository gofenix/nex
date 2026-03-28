defmodule AgentConsole.ExampleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use NexExamplesTestSupport.Case, port: 4214

      def example_env(_example) do
        [
          {"OPENAI_API_KEY", "test-key"},
          {"OPENAI_BASE_URL", "https://api.openai.com/v1"},
          {"OPENAI_MODEL", "gpt-4.1-mini"}
        ]
      end
    end
  end
end
