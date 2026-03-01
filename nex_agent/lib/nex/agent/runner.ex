defmodule Nex.Agent.Runner do
  require Logger

  alias Nex.Agent.{
    Session,
    Entry,
    Tool.Read,
    Tool.Write,
    Tool.Edit,
    Tool.Bash,
    Skills,
    Memory,
    Evolution
  }

  @default_max_iterations 10

  @doc """
  Run an agent session with the given prompt.

  Options:
    - :max_iterations - Maximum number of iterations (default: 10)
    - :provider - LLM provider (:anthropic, :openai, :ollama)
    - :model - Model name
    - :api_key - API key for the provider
    - :base_url - Custom base URL for the provider
    - :cwd - Current working directory
    - :llm_client - For testing: a function that mocks LLM responses
  """
  @memory_window 50

  def run(session, prompt, opts \\ []) do
    max_iterations = Keyword.get(opts, :max_iterations, @default_max_iterations)
    provider = Keyword.get(opts, :provider, :anthropic)
    model = Keyword.get(opts, :model, "claude-sonnet-4-20250514")
    api_key = Keyword.get(opts, :api_key)
    base_url = Keyword.get(opts, :base_url)
    cwd = Keyword.get(opts, :cwd, File.cwd!())
    channel = Keyword.get(opts, :channel, "telegram")
    chat_id = Keyword.get(opts, :chat_id, "")
    llm_client = Keyword.get(opts, :llm_client)

    Logger.info(
      "[Runner] Starting session=#{session.id} provider=#{provider} model=#{model} cwd=#{cwd}"
    )

    session = maybe_consolidate_memory(session, provider, model, api_key, base_url)

    system_prompt = Nex.Agent.SystemPrompt.build(cwd: cwd)

    runtime_ctx = Nex.Agent.SystemPrompt.build_runtime_context(channel: channel, chat_id: chat_id)

    history = session_history(session)

    messages =
      [%{"role" => "system", "content" => system_prompt}] ++
        history ++
        [%{"role" => "user", "content" => runtime_ctx}]

    user_message = %{"role" => "user", "content" => prompt}
    session = add_message(session, user_message)
    messages = messages ++ [user_message]

    run_loop(session, messages, 0, max_iterations,
      provider: provider,
      model: model,
      api_key: api_key,
      base_url: base_url,
      cwd: cwd,
      channel: channel,
      chat_id: chat_id,
      llm_client: llm_client
    )
  end

  defp session_history(session) do
    all_messages = Session.current_messages(session)
    unconsolidated_count = length(all_messages) - session.last_consolidated
    window = max(unconsolidated_count, div(@memory_window, 2))

    all_messages
    |> Enum.drop(max(0, length(all_messages) - window))
    |> Enum.drop_while(fn m -> Map.get(m, "role") != "user" end)
  end

  defp maybe_consolidate_memory(session, provider, model, api_key, base_url) do
    messages = Session.current_messages(session)
    unconsolidated = length(messages) - session.last_consolidated

    if unconsolidated >= @memory_window do
      Logger.info("[Runner] Triggering memory consolidation: #{unconsolidated} unconsolidated messages")

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

  defp run_loop(session, messages, iteration, max_iterations, opts, ever_sent_message \\ false) do
    Logger.debug("[Runner] Loop iteration=#{iteration + 1}/#{max_iterations}")

    if iteration >= max_iterations do
      Logger.warning("[Runner] Max iterations exceeded (#{max_iterations})")
      {:error, :max_iterations_exceeded, session}
    else
      case call_llm(messages, opts) do
        {:ok, response} ->
          content = response.content
          tool_calls = Map.get(response, :tool_calls) || Map.get(response, "tool_calls")

          if tool_calls && tool_calls != [] do
            Logger.info(
              "[Runner] LLM requests #{length(tool_calls)} tool call(s) (iteration #{iteration + 1})"
            )

            session =
              add_message(session, %{
                "role" => "assistant",
                "content" => content,
                "tool_calls" => tool_calls
              })

            messages =
              messages ++
                [%{"role" => "assistant", "content" => content, "tool_calls" => tool_calls}]

            {new_messages, _results, message_sent?} =
              execute_tools(session, messages, tool_calls, opts)

            run_loop(session, new_messages, iteration + 1, max_iterations, opts, ever_sent_message || message_sent?)
          else
            Logger.info("[Runner] LLM finished reasoning (iteration #{iteration + 1})")
            session = add_message(session, %{"role" => "assistant", "content" => content})

            if ever_sent_message do
              Logger.info("[Runner] Final reply suppressed (message tool was used)")
              {:ok, :message_sent, session}
            else
              {:ok, content, session}
            end
          end

        {:error, reason} ->
          Logger.error("[Runner] LLM call failed: #{inspect(reason)}")
          {:error, reason, session}
      end
    end
  end

  defp call_llm(messages, opts) do
    opts = Keyword.put(opts, :tools, all_tools())

    # Check if a test client is provided
    if opts[:llm_client] do
      opts[:llm_client].(messages, opts)
    else
      call_llm_real(messages, opts)
    end
  end

  defp all_tools do
    # Built-in tools
    tools = [
      %{
        "name" => "read",
        "description" => "Read a file from the filesystem",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "path" => %{"type" => "string", "description" => "Path to the file to read"}
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
            "path" => %{"type" => "string", "description" => "Path to write to"},
            "content" => %{"type" => "string", "description" => "Content to write"}
          },
          "required" => ["path", "content"]
        }
      },
      %{
        "name" => "edit",
        "description" => "Edit a file by replacing specific text",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "path" => %{"type" => "string", "description" => "Path to the file"},
            "search" => %{"type" => "string", "description" => "Text to find"},
            "replace" => %{"type" => "string", "description" => "Text to replace with"}
          },
          "required" => ["path", "search", "replace"]
        }
      },
      %{
        "name" => "bash",
        "description" => "Execute a bash command",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "command" => %{"type" => "string", "description" => "Command to execute"}
          },
          "required" => ["command"]
        }
      },
      %{
        "name" => "web_search",
        "description" => "Search the web using Brave Search API",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "query" => %{"type" => "string", "description" => "Search query"},
            "count" => %{
              "type" => "integer",
              "description" => "Number of results (1-10)",
              "minimum" => 1,
              "maximum" => 10
            }
          },
          "required" => ["query"]
        }
      },
      %{
        "name" => "web_fetch",
        "description" => "Fetch and extract content from a URL",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "url" => %{"type" => "string", "description" => "URL to fetch"}
          },
          "required" => ["url"]
        }
      }
    ]

    # Add Skills
    skills = Skills.for_llm()

    skill_tools =
      Enum.map(skills, fn skill ->
        skill_name = Map.get(skill, "name") || Map.get(skill, :name)
        skill_description = Map.get(skill, "description") || Map.get(skill, :description)

        %{
          "name" => skill_name,
          "description" => skill_description,
          "input_schema" => %{
            "type" => "object",
            "properties" => %{
              "arguments" => %{
                "type" => "string",
                "description" =>
                  Map.get(skill, "argument_hint") || Map.get(skill, :argument_hint) ||
                    "Arguments for the skill"
              }
            }
          }
        }
      end)

    # Add skills_list tool
    skills_list_tool = %{
      "name" => "skills_list",
      "description" => "List all available skills",
      "input_schema" => %{"type" => "object", "properties" => %{}}
    }

    # Add skill_create tool
    skill_create_tool = %{
      "name" => "skill_create",
      "description" => "Create a new skill for automating repetitive tasks",
      "input_schema" => %{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string", "description" => "Skill name (snake_case)"},
          "description" => %{"type" => "string", "description" => "What this skill does"},
          "type" => %{
            "type" => "string",
            "description" => "Skill type: elixir, script, mcp, or markdown"
          },
          "code" => %{"type" => "string", "description" => "The actual code/script/content"},
          "parameters" => %{"type" => "object", "description" => "JSON Schema for parameters"}
        },
        "required" => ["name", "description"]
      }
    }

    # Add skill_execute tool
    skill_execute_tool = %{
      "name" => "skill_execute",
      "description" => "Execute a skill with arguments",
      "input_schema" => %{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string", "description" => "Skill name to execute"},
          "arguments" => %{"type" => "object", "description" => "Arguments for the skill"}
        },
        "required" => ["name", "arguments"]
      }
    }

    # Add skill_delete tool
    skill_delete_tool = %{
      "name" => "skill_delete",
      "description" => "Delete a skill by name",
      "input_schema" => %{
        "type" => "object",
        "properties" => %{
          "name" => %{"type" => "string", "description" => "Skill name to delete"}
        },
        "required" => ["name"]
      }
    }

    # Add Memory search
    memory_tools = [
      %{
        "name" => "memory_search",
        "description" => "Search agent memory for past experiences",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "query" => %{"type" => "string", "description" => "Search query"}
          },
          "required" => ["query"]
        }
      },
      %{
        "name" => "memory_append",
        "description" => "Save important information to memory",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "task" => %{"type" => "string", "description" => "Task description"},
            "result" => %{"type" => "string", "description" => "Result (SUCCESS/FAILURE)"}
          },
          "required" => ["task", "result"]
        }
      }
    ]

    # Add message tool for sending messages during agent loop
    message_tool = %{
      "name" => "message",
      "description" =>
        "Send a message to the user. Use this when you want to communicate something immediately.",
      "input_schema" => %{
        "type" => "object",
        "properties" => %{
          "content" => %{"type" => "string", "description" => "The message content to send"},
          "channel" => %{
            "type" => "string",
            "description" =>
              "Target channel (telegram, discord, http). Defaults to current channel."
          },
          "chat_id" => %{
            "type" => "string",
            "description" => "Target chat/user ID. Defaults to current chat."
          }
        },
        "required" => ["content"]
      }
    }

    tools ++
      [message_tool] ++
      skill_tools ++
      [skills_list_tool, skill_create_tool, skill_execute_tool, skill_delete_tool] ++
      memory_tools ++ evolution_tools() ++ mcp_tools()
  end

  defp mcp_tools do
    [
      %{
        "name" => "mcp_discover",
        "description" => "Discover available MCP servers from PATH",
        "input_schema" => %{"type" => "object", "properties" => %{}}
      },
      %{
        "name" => "mcp_start",
        "description" => "Start an MCP server",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "name" => %{"type" => "string", "description" => "Server name"},
            "command" => %{"type" => "string", "description" => "Command to run"},
            "args" => %{"type" => "array", "description" => "Arguments"}
          },
          "required" => ["name", "command"]
        }
      },
      %{
        "name" => "mcp_stop",
        "description" => "Stop an MCP server",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "server_id" => %{"type" => "string", "description" => "Server ID to stop"}
          },
          "required" => ["server_id"]
        }
      },
      %{
        "name" => "mcp_list",
        "description" => "List running MCP servers",
        "input_schema" => %{"type" => "object", "properties" => %{}}
      },
      %{
        "name" => "mcp_call",
        "description" => "Call a tool on an MCP server",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "server_id" => %{"type" => "string", "description" => "Server ID"},
            "tool" => %{"type" => "string", "description" => "Tool name"},
            "arguments" => %{"type" => "object", "description" => "Tool arguments"}
          },
          "required" => ["server_id", "tool"]
        }
      }
    ]
  end

  defp evolution_tools do
    [
      %{
        "name" => "evolve_code",
        "description" => "Modify and reload agent code at runtime",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "module" => %{
              "type" => "string",
              "description" => "Module name to modify (e.g., Nex.Agent.Runner)"
            },
            "code" => %{"type" => "string", "description" => "New Elixir code for the module"}
          },
          "required" => ["module", "code"]
        }
      },
      %{
        "name" => "evolve_rollback",
        "description" => "Rollback to previous version of a module",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "module" => %{"type" => "string", "description" => "Module name to rollback"}
          },
          "required" => ["module"]
        }
      },
      %{
        "name" => "evolve_versions",
        "description" => "List all versions of a module",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "module" => %{"type" => "string", "description" => "Module name"}
          },
          "required" => ["module"]
        }
      },
      %{
        "name" => "reflect",
        "description" => "Analyze recent execution results and generate insights",
        "input_schema" => %{
          "type" => "object",
          "properties" => %{
            "auto_apply" => %{
              "type" => "boolean",
              "description" => "Automatically apply suggestions"
            }
          }
        }
      }
    ]
  end

  defp call_llm_real(messages, opts) do
    provider = Keyword.get(opts, :provider, :anthropic)
    model = Keyword.get(opts, :model)
    api_key = Keyword.get(opts, :api_key)
    base_url = Keyword.get(opts, :base_url)
    tools = Keyword.get(opts, :tools, [])

    provider_opts =
      [
        model: model,
        api_key: api_key,
        base_url: base_url,
        tools: tools
      ]
      |> Enum.reject(fn {_, v} -> is_nil(v) end)

    case provider do
      :anthropic ->
        Nex.Agent.LLM.Anthropic.chat(messages, provider_opts)

      :openai ->
        Nex.Agent.LLM.OpenAI.chat(messages, provider_opts)

      :openrouter ->
        Nex.Agent.LLM.OpenRouter.chat(messages, provider_opts)

      :ollama ->
        Nex.Agent.LLM.Ollama.chat(messages, provider_opts)

      _ ->
        {:error, "Unknown provider: #{provider}"}
    end
  end

  @doc """
  Call LLM for memory consolidation. Returns {:ok, args_map} where args_map has
  "history_entry" and "memory_update" keys, or {:error, reason}.
  """
  def call_llm_for_consolidation(messages, opts) do
    case call_llm_real(messages, opts) do
      {:ok, response} ->
        tool_calls = Map.get(response, :tool_calls) || []

        save_call =
          Enum.find(tool_calls, fn tc ->
            name = get_in(tc, [:function, :name]) || get_in(tc, ["function", "name"])
            name == "save_memory"
          end)

        if save_call do
          raw_args =
            get_in(save_call, [:function, :arguments]) ||
              get_in(save_call, ["function", "arguments"])

          case normalize_tool_arguments(raw_args) do
            {:error, reason} -> {:error, reason}
            args -> {:ok, args}
          end
        else
          {:error, :no_save_memory_call}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp execute_tools(_session, messages, tool_calls, opts) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())
    channel = Keyword.get(opts, :channel, "telegram")
    chat_id = Keyword.get(opts, :chat_id, "")
    ctx = %{cwd: cwd, channel: channel, chat_id: chat_id}

    message_sent? = false

    {results, message_sent} =
      Enum.map_reduce(tool_calls, message_sent?, fn tc, acc ->
        tool_name = get_in(tc, ["function", "name"]) || get_in(tc, [:function, :name])
        raw_args = get_in(tc, ["function", "arguments"]) || get_in(tc, [:function, :arguments])
        args = normalize_tool_arguments(raw_args)

        Logger.info("[Runner] Executing tool: #{tool_name} with args: #{inspect(args)}")
        start_time = System.monotonic_time(:millisecond)

        result =
          case args do
            {:error, reason} -> {:error, reason}
            parsed_args -> execute_tool(tool_name, parsed_args, ctx)
          end

        elapsed_ms = System.monotonic_time(:millisecond) - start_time

        # Track if message tool successfully sent a message
        sent_via_tool =
          case {tool_name, result} do
            {"message", {:ok, _}} -> true
            _ -> acc
          end

        case result do
          {:ok, _val} ->
            Logger.debug("[Runner] Tool '#{tool_name}' succeeded in #{elapsed_ms}ms")

          {:error, err} ->
            Logger.warning(
              "[Runner] Tool '#{tool_name}' failed in #{elapsed_ms}ms: #{inspect(err)}"
            )
        end

        tool_result = %{
          "role" => "tool",
          "tool_call_id" => tc["id"],
          "content" => format_result(result)
        }

        {{tc["id"], tool_result}, sent_via_tool}
      end)

    tool_messages = Enum.map(results, fn {_, msg} -> msg end)
    {messages ++ tool_messages, results, message_sent}
  end

  defp execute_tool("read", args, ctx) do
    Read.execute(args, %{cwd: ctx[:cwd] || File.cwd!()})
  end

  defp execute_tool("write", args, ctx) do
    Write.execute(args, %{cwd: ctx[:cwd] || File.cwd!()})
  end

  defp execute_tool("edit", args, ctx) do
    Edit.execute(args, %{cwd: ctx[:cwd] || File.cwd!()})
  end

  defp execute_tool("bash", args, ctx) do
    Bash.execute(args, %{cwd: ctx[:cwd] || File.cwd!()})
  end

  defp execute_tool("web_search", args, _opts) do
    Nex.Agent.Tool.WebSearch.execute(args, %{})
  end

  defp execute_tool("web_fetch", args, _opts) do
    Nex.Agent.Tool.WebFetch.execute(args, %{})
  end

  defp execute_tool("message", args, ctx) do
    Nex.Agent.Tool.Message.execute(args, ctx)
  end

  defp execute_tool("memory_search", args, _opts) do
    query = args["query"] || ""
    results = Memory.search(query)

    if results == [] do
      {:ok, %{result: "No memories found for: #{query}"}}
    else
      formatted =
        Enum.map(results, fn r ->
          "#{r.entry.task} - #{r.entry.result}\n#{r.entry.body}\n---\n"
        end)
        |> Enum.join()

      {:ok, %{result: formatted}}
    end
  end

  defp execute_tool("memory_append", args, _opts) do
    task = args["task"] || ""
    result = args["result"] || "UNKNOWN"
    metadata = Map.get(args, "metadata", %{})

    case Memory.append(task, result, metadata) do
      :ok -> {:ok, %{result: "Memory saved: #{task}"}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp execute_tool("skill_" <> skill_name, args, _opts) do
    # Skills are called as skill_<name>
    arguments = args["arguments"] || ""

    case Skills.execute(skill_name, arguments, invoked_by: :model) do
      {:ok, content} -> {:ok, %{result: content}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp execute_tool("skills_list", _args, _opts) do
    skills = Skills.list()

    formatted =
      Enum.map_join(skills, "\n", fn s ->
        type = s.type || "markdown"
        "- #{s.name} (#{type}): #{s.description}"
      end)

    {:ok, %{result: "Available skills:\n#{formatted}"}}
  end

  defp execute_tool("skill_create", args, _opts) do
    name = args["name"]
    description = args["description"]
    type = args["type"] || "markdown"
    code = args["code"] || ""
    parameters = args["parameters"] || %{}

    if is_nil(name) do
      {:error, "Skill name is required"}
    else
      case Skills.create(%{
             name: name,
             description: description,
             type: type,
             code: code,
             parameters: parameters
           }) do
        {:ok, skill} ->
          Memory.append(
            "Created skill: #{name}",
            "SUCCESS",
            %{type: :skill_create, skill_type: type}
          )

          {:ok, %{result: "Successfully created skill '#{name}' (type: #{type})"}}

        {:error, reason} ->
          Memory.append(
            "Failed to create skill: #{name}",
            "FAILURE",
            %{type: :skill_create, error: reason}
          )

          {:error, reason}
      end
    end
  end

  defp execute_tool("skill_execute", args, _opts) do
    name = args["name"]
    arguments = args["arguments"] || %{}

    if is_nil(name) do
      {:error, "Skill name is required"}
    else
      case Skills.execute(name, arguments, invoked_by: :user) do
        {:ok, result} ->
          formatted =
            if is_map(result) do
              Map.get(result, :result) || Map.get(result, :content) || Jason.encode!(result)
            else
              result
            end

          Memory.append(
            "Executed skill: #{name}",
            "SUCCESS",
            %{type: :skill_execute, args: arguments}
          )

          {:ok, %{result: formatted}}

        {:error, reason} ->
          Memory.append(
            "Failed to execute skill: #{name}",
            "FAILURE",
            %{type: :skill_execute, error: reason}
          )

          {:error, reason}
      end
    end
  end

  defp execute_tool("skill_delete", args, _opts) do
    name = args["name"]

    if is_nil(name) do
      {:error, "Skill name is required"}
    else
      case Skills.delete(name) do
        :ok ->
          Memory.append(
            "Deleted skill: #{name}",
            "SUCCESS",
            %{type: :skill_delete}
          )

          {:ok, %{result: "Successfully deleted skill '#{name}'"}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Evolution tools
  defp execute_tool("evolve_code", args, _opts) do
    module_arg = args["module"]
    code = args["code"]

    if is_nil(module_arg) || is_nil(code) do
      {:error, "Both module and code are required"}
    else
      case normalize_module_arg(module_arg) do
        {:ok, module, module_label} ->
          case Evolution.upgrade_module(module, code, validate: false, backup: false) do
            {:ok, version} ->
              {:ok,
               %{
                 result: "Successfully evolved #{module_label} to version #{version.id}",
                 version: version.id
               }}

            {:error, reason} ->
              {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp execute_tool("evolve_rollback", args, _opts) do
    module_arg = args["module"]

    if is_nil(module_arg) do
      {:error, "module is required"}
    else
      case normalize_module_arg(module_arg) do
        {:ok, module, module_label} ->
          case Evolution.rollback(module) do
            :ok ->
              Memory.append(
                "Rolled back: #{module_label}",
                "SUCCESS",
                %{type: :rollback}
              )

              {:ok, %{result: "Successfully rolled back #{module_label}"}}

            {:error, reason} ->
              {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp execute_tool("evolve_versions", args, _opts) do
    module_arg = args["module"]

    if is_nil(module_arg) do
      {:error, "module is required"}
    else
      case normalize_module_arg(module_arg) do
        {:ok, module, module_label} ->
          versions = Evolution.list_versions(module)

          if versions == [] do
            {:ok, %{result: "No versions found for #{module_label}"}}
          else
            formatted =
              Enum.map_join(versions, "\n", fn v ->
                "#{v.id} - #{v.timestamp}"
              end)

            {:ok, %{result: "Versions of #{module_label}:\n#{formatted}"}}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Reflection tools
  defp execute_tool("reflect", args, _opts) do
    # This would need to track execution results - for now just show recent memories
    _auto_apply = args["auto_apply"] == true

    # Get recent memories for reflection context
    recent = Memory.search("", limit: 20)

    formatted =
      Enum.map_join(recent, "\n\n", fn r ->
        "#{r.entry.task} - #{r.entry.result}\n#{r.entry.body}"
      end)

    {:ok,
     %{
       result: "Recent experiences:\n#{formatted}\n\nUse memory_search to find specific patterns."
     }}
  end

  # MCP tools
  defp execute_tool("mcp_discover", _args, _opts) do
    servers = Nex.Agent.MCP.Discovery.scan()

    if servers == [] do
      {:ok, %{result: "No MCP servers found in PATH"}}
    else
      formatted =
        Enum.map_join(servers, "\n", fn s ->
          "- #{s.name}: #{s.command}"
        end)

      {:ok, %{result: "Available MCP servers:\n#{formatted}"}}
    end
  end

  defp execute_tool("mcp_start", args, _opts) do
    name = args["name"]
    command = args["command"]
    args_list = args["args"] || []

    if is_nil(name) || is_nil(command) do
      {:error, "name and command are required"}
    else
      case Nex.Agent.MCP.ServerManager.start(name, command: command, args: args_list) do
        {:ok, server_id} ->
          {:ok, %{result: "Started MCP server #{name} with ID: #{server_id}"}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp execute_tool("mcp_stop", args, _opts) do
    server_id = args["server_id"]

    if is_nil(server_id) do
      {:error, "server_id is required"}
    else
      case Nex.Agent.MCP.ServerManager.stop(server_id) do
        :ok ->
          {:ok, %{result: "Stopped MCP server #{server_id}"}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp execute_tool("mcp_list", _args, _opts) do
    servers = Nex.Agent.MCP.ServerManager.list()

    if servers == [] do
      {:ok, %{result: "No MCP servers running"}}
    else
      formatted =
        Enum.map_join(servers, "\n", fn s ->
          "- #{s.id} (#{s.name}): #{s.config[:command]}"
        end)

      {:ok, %{result: "Running MCP servers:\n#{formatted}"}}
    end
  end

  defp execute_tool("mcp_call", args, _opts) do
    server_id = args["server_id"]
    tool = args["tool"]
    tool_args = args["arguments"] || %{}

    if is_nil(server_id) || is_nil(tool) do
      {:error, "server_id and tool are required"}
    else
      case Nex.Agent.MCP.ServerManager.call_tool(server_id, tool, tool_args) do
        {:ok, result} ->
          {:ok, %{result: Jason.encode!(result)}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp execute_tool(name, _args, _opts) do
    {:error, "Unknown tool: #{name}"}
  end

  defp normalize_tool_arguments(args) when is_map(args), do: args

  defp normalize_module_arg(module) when is_atom(module) do
    {:ok, module, inspect(module)}
  end

  defp normalize_module_arg(module) when is_binary(module) do
    trimmed = String.trim(module)

    cond do
      trimmed == "" ->
        {:error, "module is required"}

      String.starts_with?(trimmed, "Elixir.") ->
        atom = String.to_atom(trimmed)
        {:ok, atom, String.trim_leading(trimmed, "Elixir.")}

      true ->
        atom = String.to_atom("Elixir." <> trimmed)
        {:ok, atom, trimmed}
    end
  end

  defp normalize_module_arg(_), do: {:error, "module must be a module atom or string"}

  defp normalize_tool_arguments(args) when is_binary(args) do
    trimmed = String.trim(args)

    cond do
      trimmed == "" ->
        %{}

      true ->
        case Jason.decode(trimmed) do
          {:ok, decoded} when is_map(decoded) -> decoded
          {:ok, _decoded} -> {:error, "Tool arguments must decode to an object"}
          {:error, reason} -> {:error, "Invalid tool arguments JSON: #{inspect(reason)}"}
        end
    end
  end

  defp normalize_tool_arguments(_),
    do: {:error, "Tool arguments must be a map or JSON object string"}

  @tool_result_max_chars 500

  defp format_result({:ok, result}) when is_map(result) do
    result
    |> Map.values()
    |> Enum.join("\n")
    |> truncate_result(@tool_result_max_chars)
  end

  defp format_result({:error, error}) do
    "Error: #{error}"
  end

  defp format_result(result) when is_binary(result) do
    truncate_result(result, @tool_result_max_chars)
  end

  defp truncate_result(result, max_chars) do
    if String.length(result) > max_chars do
      String.slice(result, 0, max_chars) <> "\n\n... [truncated]"
    else
      result
    end
  end

  defp add_message(session, message) do
    entry = Entry.new_message(session.current_entry_id, message)
    Session.add_entry(session, entry)
  end
end
