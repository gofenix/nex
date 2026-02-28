ExUnit.start()

# Set test environment for security module
Application.put_env(:nex_agent, :env, :test)

# Clean up test sessions before tests
session_dir = Path.expand("~/.nex/agent/sessions")

if File.exists?(session_dir) do
  session_dir
  |> File.ls!()
  |> Enum.filter(&String.starts_with?(&1, "test_"))
  |> Enum.each(fn dir ->
    File.rm_rf!(Path.join(session_dir, dir))
  end)
end
