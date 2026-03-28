defmodule BestofEx.ExampleCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use NexExamplesTestSupport.Case, port: 4216

      def example_env(example) do
        db_path = Path.join(example.cwd, "tmp/test_artifacts/bestof_ex_test.db")
        [{"DATABASE_URL", "sqlite://#{db_path}"}]
      end

      def prepare_example(example) do
        File.rm_rf!(Path.join(example.cwd, "tmp/test_artifacts/bestof_ex_test.db"))
        NexExamplesTestSupport.Commands.run!(
          example,
          "prepare_data",
          ["mix", "run", "test/support/prepare_data.exs"]
        )
      end
    end
  end
end
