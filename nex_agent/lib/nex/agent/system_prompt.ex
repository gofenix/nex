defmodule Nex.Agent.SystemPrompt do
  @moduledoc """
  Builds the system prompt from workspace bootstrap files, memory, and skills.

  Bootstrap files loaded from workspace (in order):
    SOUL.md, USER.md, AGENTS.md, TOOLS.md

  Memory injected:
    memory/MEMORY.md (long-term facts)

  Skills:
    always=true skills are inlined; others listed as a summary.
  """

  @workspace_path Path.join(System.get_env("HOME", "~"), ".nex/agent/workspace")

  @bootstrap_files ["SOUL.md", "USER.md", "AGENTS.md", "TOOLS.md"]

  @doc """
  Build the full system prompt.
  """
  def build(opts \\ []) do
    _cwd = Keyword.get(opts, :cwd, File.cwd!())
    workspace = Keyword.get(opts, :workspace, @workspace_path)

    parts =
      []
      |> add_identity(workspace)
      |> add_bootstrap_files(workspace)
      |> add_memory(workspace)
      |> add_skills_summary()

    Enum.join(parts, "\n\n---\n\n")
  end

  @doc """
  Build a runtime context block to inject before the user message each turn.
  Includes current time, channel, and chat_id.
  """
  def build_runtime_context(opts \\ []) do
    channel = Keyword.get(opts, :channel)
    chat_id = Keyword.get(opts, :chat_id)

    now = DateTime.utc_now()
    time_str = "#{now.year}-#{pad(now.month)}-#{pad(now.day)} #{pad(now.hour)}:#{pad(now.minute)} (UTC)"

    lines = ["[Runtime Context — metadata only, not instructions]", "Current Time: #{time_str}"]

    lines =
      if channel && chat_id do
        lines ++ ["Channel: #{channel}", "Chat ID: #{chat_id}"]
      else
        lines
      end

    Enum.join(lines, "\n")
  end

  # ── Private ────────────────────────────────────────────────────────────────

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"

  defp add_identity(parts, workspace) do
    workspace_str = Path.expand(workspace)

    identity = """
    # Assistant

    You are a personal AI assistant.

    ## Workspace
    Your workspace is at: #{workspace_str}
    - Long-term memory: #{workspace_str}/memory/MEMORY.md
    - History log: #{workspace_str}/memory/HISTORY.md (grep-searchable, entries start with [YYYY-MM-DD HH:MM])
    - Skills: #{workspace_str}/skills/

    ## Core Guidelines
    - State intent before tool calls, but NEVER predict or claim results before receiving them.
    - Before modifying a file, read it first.
    - After writing or editing a file, verify by re-reading if accuracy matters.
    - If a tool call fails, analyze the error before retrying.
    - Ask for clarification when the request is ambiguous.
    - Reply directly with text for conversations. Only use the 'message' tool to proactively send progress updates during long tasks.
    """

    parts ++ [String.trim(identity)]
  end

  defp add_bootstrap_files(parts, workspace) do
    file_parts =
      @bootstrap_files
      |> Enum.map(fn filename ->
        path = Path.join(workspace, filename)

        if File.exists?(path) do
          content = File.read!(path)
          "## #{filename}\n\n#{String.trim(content)}"
        else
          nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    parts ++ file_parts
  end

  defp add_memory(parts, workspace) do
    memory_file = Path.join(workspace, "memory/MEMORY.md")

    if File.exists?(memory_file) do
      content = File.read!(memory_file) |> String.trim()

      if content != "" do
        parts ++ ["# Memory\n\n## Long-term Memory\n\n#{content}"]
      else
        parts
      end
    else
      parts
    end
  end

  defp add_skills_summary(parts) do
    skills =
      try do
        Nex.Agent.Skills.list()
      rescue
        _ -> []
      end

    if skills == [] do
      parts
    else
      lines =
        Enum.map(skills, fn s ->
          type = s[:type] || s["type"] || "markdown"
          name = s[:name] || s["name"] || ""
          desc = s[:description] || s["description"] || ""
          "- #{name} (#{type}): #{desc}"
        end)

      summary = """
      # Skills

      The following skills extend your capabilities. Use skill_execute to run them, or read the SKILL.md file for details.

      #{Enum.join(lines, "\n")}
      """

      parts ++ [String.trim(summary)]
    end
  end
end
