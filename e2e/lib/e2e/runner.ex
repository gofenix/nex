defmodule E2E.Runner do
  alias E2E.Examples

  @project_root Path.expand("../..", __DIR__)

  def run_example!(name) do
    example = Examples.fetch!(name)
    run_mix!(["test", example.test_file, "--seed", "0"], "E2E failed for #{name}")
  end

  def run_all! do
    failures =
      Examples.all()
      |> Enum.reduce([], fn example, acc ->
        Mix.shell().info("\n=== Running #{example.name} ===")

        case run_mix(["e2e.example", "--name", example.name]) do
          0 -> acc
          _ -> acc ++ [example.name]
        end
      end)

    if failures != [] do
      Mix.raise("E2E failures: #{Enum.join(failures, ", ")}")
    end
  end

  defp run_mix!(args, error_message) do
    case run_mix(args) do
      0 -> :ok
      _ -> Mix.raise(error_message)
    end
  end

  defp run_mix(args) do
    mix = System.find_executable("mix") || raise "could not find mix executable"

    {_output, exit_status} =
      System.cmd(mix, args,
        cd: @project_root,
        env: [{"MIX_ENV", "test"}],
        into: IO.stream(:stdio, :line),
        stderr_to_stdout: true
      )

    exit_status
  end
end
