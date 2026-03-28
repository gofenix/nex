defmodule AiSaga.ExampleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use NexExamplesTestSupport.Case, port: 4215

      def example_env(example) do
        db_path = Path.join(example.cwd, "tmp/test_artifacts/ai_saga_test.db")

        [
          {"DATABASE_URL", "sqlite://#{db_path}"},
          {"OPENAI_API_KEY", "test-key"},
          {"OPENAI_BASE_URL", "https://api.openai.com/v1"},
          {"OPENAI_MODEL", "gpt-4.1-mini"}
        ]
      end

      def prepare_example(example) do
        File.rm_rf!(Path.join(example.cwd, "tmp/test_artifacts/ai_saga_test.db"))
        NexExamplesTestSupport.Commands.run!(
          example,
          "prepare_data",
          ["mix", "run", "test/support/prepare_data.exs"]
        )
      end
    end
  end
end
