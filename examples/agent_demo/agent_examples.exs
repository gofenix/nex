Nex.Env.init()

api_key = Nex.Env.get(:openai_api_key)
base_url = Nex.Env.get(:openai_base_url, "https://api.gpt.ge/v1/")

IO.puts("=== Nex.Agent Examples ===\n")

IO.puts("--- Example 1: Basic Usage ---\n")

{:ok, agent} =
  Nex.Agent.start(
    provider: :openai,
    model: "gpt-4o",
    api_key: api_key,
    base_url: base_url
  )

{:ok, result, _} = Nex.Agent.prompt(agent, "Say 'hello' in 3 words")
IO.puts("Result: #{result}\n")

IO.puts("--- Example 2: With Custom Model ---\n")

{:ok, agent2} =
  Nex.Agent.start(
    provider: :openai,
    model: "gpt-4o-mini",
    api_key: api_key,
    base_url: base_url
  )

{:ok, result2, _} = Nex.Agent.prompt(agent2, "What is 2+2?")
IO.puts("Result: #{result2}\n")

IO.puts("--- Example 3: Session ID & Continue ---\n")

session_id = Nex.Agent.session_id(agent)
IO.puts("Session ID: #{session_id}\n")

{:ok, result3, _} = Nex.Agent.prompt(agent, "Now add 5 more")
IO.puts("Follow-up: #{result3}\n")

IO.puts("--- Example 4: Fork Session ---\n")

{:ok, forked} = Nex.Agent.fork(agent)
IO.puts("Forked session ID: #{Nex.Agent.session_id(forked)}\n")

IO.puts("--- Example 5: Project Context ---\n")

File.write!("AGENTS.md", """
# Project Guidelines
- Use Elixir conventions
- Write tests for all modules
""")

{:ok, agent4} =
  Nex.Agent.start(
    provider: :openai,
    model: "gpt-4o",
    api_key: api_key,
    base_url: base_url,
    project: "my-project"
  )

{:ok, result4, _} = Nex.Agent.prompt(agent4, "Create a simple module")
IO.puts("Result: #{result4}\n")

File.rm!("AGENTS.md")

IO.puts("=== Done ===")
