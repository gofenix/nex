# test_stream.exs
alias NexAI.Provider.OpenAI

# Load .env
if File.exists?(".env") do
  File.read!(".env")
  |> String.split("\n")
  |> Enum.each(fn line ->
    case String.split(line, "=", parts: 2) do
      [key, value] -> System.put_env(key, value)
      _ -> :ok
    end
  end)
end

key = System.get_env("OPENAI_API_KEY")
base_url = System.get_env("OPENAI_BASE_URL") || "https://api.openai.com/v1"

IO.puts "Testing Stream with:"
IO.puts "Base URL: #{base_url}"
IO.puts "Key: #{String.slice(key, 0, 5)}...#{String.slice(key, -5, 5)}"

model = NexAI.openai("gpt-4o")

res = NexAI.stream_text(
  model: model,
  messages: [%{role: "user", content: "Say hello short"}],
  max_steps: 1
)

IO.inspect(res, label: "Stream Result")

Enum.each(res.full_stream, fn event ->
  IO.inspect(event, label: "EVENT")
end)
