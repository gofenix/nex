defmodule Nex.Agent.Runner do
  require Logger

  alias Nex.Agent.{
    Session,
    ContextBuilder,
    Skills,
    Memory
  }

  @default_max_iterations 10
  @memory_window 50

  @doc """
  Run agent loop with session and prompt.
  """
  def run(session, prompt, opts \\ []) do
    max_iterations = Keyword.get(opts, :max_iterations, @default_max_iterations)
    provider = Keyword.get(opts, :provider, :anthropic)
    model = Keyword.get(opts, :model, "claude-sonnet-4-20250514")
    api_key = Keyword.get(opts, :api_key)
    base_url = Keyword.get(opts, :base_url)
    cwd = Keyword.get(opts, :cwd, File.cwd!())
    channel = Keyword.get(opts, :channel, "telegram")
    chat_id = Keyword.get(opts, :chat_id, "default")

    Logger.info("[Runner] Starting provider=#{provider} model=#{model} channel=#{channel}")

    session = maybe_consolidate_memory(session, provider, model, api_key, base_url)

    history = Session.get_history(session, @memory_window)

    messages =
      ContextBuilder.build_messages(
        history,
        prompt,
        channel,
        chat_id
      )

    session = Session.add_message(session, "user", prompt)

    Logger.info("[Runner] LLM request: history=#{length(history)} messages=#{length(messages)}")

    run_loop(session, messages, 0, max_iterations, opts)
  end

  defp session_history(session) do
    Session.get_history(session, @memory_window)
  end

  defp maybe_consolidate_memory(session, provider, model, api_key, base_url) do
    messages = session.messages
    unconsolidated = length(messages) - session.last_consolidated

    if unconsolidated >= @memory_window do
      Logger.info("[Runner] Triggering memory consolidation: #{unconsolidated} messages")

      case Memory.consolidate(session, provider, model,
             api_key: api_key,
             base_url: base_url,
             memory_window: @memory_window
           ) do
        {:ok, updated_session} ->
          updated_session

        {:error, reason} ->
          Logger.warning("[Runner] Memory consolidation failed: #{inspect(reason)}")
          session
      end
    else
      session
    end
  end

  defp run_loop(session, messages, iteration, max_iterations, opts) do
    Logger.debug("[Runner] Loop iteration=#{iteration + 1}/#{max_iterations}")

    if iteration >= max_iterations do
      Logger.warning("[Runner] Max iterations reached (#{max_iterations})")
      {:error, :max_iterations_exceeded, session}
    else
      case call_llm(messages, opts) do
        {:ok, response} ->
          content = response.content
          tool_calls = Map.get(response, :tool_calls) || Map.get(response, "tool_calls")

          if tool_calls && tool_calls != [] do
            Logger.info("[Runner] LLM requests #{length(tool_calls)} tool call(s)")

            tool_call_dicts =
              Enum.map(tool_calls, fn tc ->
                %{
                  "id" => Map.get(tc, :id) || Map.get(tc, "id"),
                  "type" => "function",
                  "function" => %{
                    "name" => Map.get(tc, :name) || Map.get(tc, "name"),
                    "arguments" =>
                      Jason.encode!(Map.get(tc, :arguments) || Map.get(tc, "arguments") || %{})
                  }
                }
              end)

            messages = ContextBuilder.add_assistant_message(messages, content, tool_call_dicts)

            session =
              Session.add_message(session, "assistant", content, tool_calls: tool_call_dicts)

            {new_messages, results} = execute_tools(session, messages, tool_calls, opts)

            run_loop(session, new_messages, iteration + 1, max_iterations, opts)
          else
            Logger.info("[Runner] LLM finished: #{String.slice(content || "", 0, 100)}")
            session = Session.add_message(session, "assistant", content || "")
            {:ok, content || "", session}
          end

        {:error, reason} ->
          Logger.error("[Runner] LLM call failed: #{inspect(reason)}")
          {:error, reason, session}
      end
    end
  end

  defp call_llm(messages, opts) do
    tools = all_tools()

    opts =
      opts
      |> Keyword.put(:tools, tools)

    if opts[:llm_client] do
      opts[:llm_client].(messages, opts)
    else
      call_llm_real(messages, opts)
    end
  end

  defp call_llm_real(messages, opts) do
    provider = Keyword.get(opts, :provider, :anthropic)
    model = Keyword.get(opts, :model)
    api_key = Keyword.get(opts, :api_key)
    base_url = Keyword.get(opts, :base_url)
    tools = Keyword.get(opts, :tools, [])

    case provider do
      :anthropic ->
        Nex.Agent.LLM.Anthropic.chat(messages,
          model: model,
          api_key: api_key,
          tools: tools
        )

      :openai ->
        Nex.Agent.LLM.OpenAI.chat(messages,
          model: model,
          api_key: api_key,
          base_url: base_url,
          tools: tools
        )

      _ ->
        {:error, "Unsupported provider: #{provider}"}
    end
  end

  defp all_tools do
    tools = [
      %{
        "name" => "read",
        "description" => "Read a file from the filesystem",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "path" => %{"type" => "string", "description" => "Path to file"}
          },
          "required" => ["path"]
        }
      },
      %{
        "name" => "write",
        "description" => "Write content to a file",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "path" => %{"type" => "string", "description" => "Path to file"},
            "content" => %{"type" => "string", "description" => "Content to write"}
          },
          "required" => ["path", "content"]
        }
      },
      %{
        "name" => "bash",
        "description" => "Execute a shell command",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "command" => %{"type" => "string", "description" => "Command to execute"}
          },
          "required" => ["command"]
        }
      }
    ]

    skills = Skills.for_llm()

    skill_tools =
      Enum.map(skills, fn skill ->
        name = Map.get(skill, "name") || Map.get(skill, :name)
        desc = Map.get(skill, "description") || Map.get(skill, :description)

        %{
          "name" => name,
          "description" => desc,
          "input_schema" => %{
            "type" => "object",
            "properties" => %{
              "input" => %{"type" => "string", "description" => "Input to skill"}
            },
            "required" => ["input"]
          }
        }
      end)

    tools ++ skill_tools
  end

  defp execute_tools(session, messages, tool_calls, opts) do
    results =
      Enum.map(tool_calls, fn tc ->
        tool_name = Map.get(tc, :name) || Map.get(tc, "name")
        tool_call_id = Map.get(tc, :id) || Map.get(tc, "id")
        args = Map.get(tc, :arguments) || Map.get(tc, "arguments") || %{}

        args =
          if is_binary(args) do
            case Jason.decode(args) do
              {:ok, map} -> map
              _ -> %{}
            end
          else
            args
          end

        Logger.info("[Runner] Executing tool: #{tool_name}(#{inspect(args)})")

        result = execute_tool(tool_name, args, opts)

        {tool_call_id, tool_name, result}
      end)

    tool_messages =
      Enum.map(results, fn {tool_call_id, tool_name, result} ->
        ContextBuilder.add_tool_result(messages, tool_call_id, tool_name, result)
      end)

    {messages ++ List.flatten(tool_messages), results}
  end

  defp execute_tool("read", args, _opts) do
    path = args["path"] || args[:path]

    if path do
      case File.read(path) do
        {:ok, content} -> content
        {:error, reason} -> "Error reading file: #{inspect(reason)}"
      end
    else
      "Error: path is required"
    end
  end

  defp execute_tool("write", args, _opts) do
    path = args["path"] || args[:path]
    content = args["content"] || args[:content]

    if path && content do
      case File.write(path, content) do
        :ok -> "File written successfully"
        {:error, reason} -> "Error writing file: #{inspect(reason)}"
      end
    else
      "Error: path and content are required"
    end
  end

  defp execute_tool("bash", args, _opts) do
    command = args["command"] || args[:command]

    if command do
      {output, exit_code} = System.cmd("sh", ["-c", command])

      if exit_code == 0 do
        output
      else
        "Error: command exited with code #{exit_code}\n#{output}"
      end
    else
      "Error: command is required"
    end
  end

  defp execute_tool(name, args, _opts) do
    skill_name =
      if String.starts_with?(name, "skill_") do
        String.replace_prefix(name, "skill_", "")
      else
        name
      end

    case Skills.execute(skill_name, args["input"] || args[:input] || "") do
      {:ok, result} -> result
      {:error, reason} -> "Error executing skill #{skill_name}: #{inspect(reason)}"
    end
  end

  @doc """
  Call LLM for memory consolidation - exposes for Memory module.
  """
  def call_llm_for_consolidation(messages, opts) do
    provider = Keyword.get(opts, :provider, :anthropic)
    model = Keyword.get(opts, :model)
    api_key = Keyword.get(opts, :api_key)
    base_url = Keyword.get(opts, :base_url)
    tools = Keyword.get(opts, :tools, [])

    case provider do
      :anthropic ->
        case Nex.Agent.LLM.Anthropic.chat(messages,
               model: model,
               api_key: api_key,
               tools: tools
             ) do
          {:ok, response} ->
            tool_calls = Map.get(response, :tool_calls) || Map.get(response, "tool_calls")

            if tool_calls && length(tool_calls) > 0 do
              tc = List.first(tool_calls)
              args = Map.get(tc, :arguments) || Map.get(tc, "arguments") || %{}

              args =
                if is_binary(args) do
                  case Jason.decode(args) do
                    {:ok, map} -> map
                    _ -> %{}
                  end
                else
                  args
                end

              {:ok, args}
            else
              {:error, "No tool call in response"}
            end

          error ->
            error
        end

      _ ->
        {:error, "Unsupported provider for consolidation: #{provider}"}
    end
  end
end
