defmodule Nex.Agent.Security do
  @moduledoc """
  Security utilities for the agent.

  Provides path validation, command whitelisting, and other security checks.
  """

  @allowed_roots_default [
    # Project directory
    File.cwd!(),
    # Agent workspace
    Path.expand("~/.nex/agent"),
    # Temp directory (for tests and operations)
    "/tmp"
  ]

  # Base commands allowed in production
  @allowed_commands_prod [
    # Version control
    "git",
    "hg",
    # Build tools
    "mix",
    "elixir",
    "erlc",
    "rebar3",
    "make",
    "cmake",
    # File operations
    "ls",
    "dir",
    "cat",
    "head",
    "tail",
    "grep",
    "find",
    "wc",
    "sort",
    "uniq",
    "mkdir",
    "rmdir",
    "cp",
    "mv",
    "chmod",
    "chown",
    "pwd",
    # Text processing
    "awk",
    "sed",
    "sort",
    "cut",
    "tr",
    "tee",
    # Process
    "ps",
    "kill",
    "killall",
    "top",
    "htop",
    # Network (read-only)
    "curl",
    "wget",
    "ssh",
    "scp",
    "rsync",
    # Development
    "npm",
    "node",
    "yarn",
    "pnpm",
    "python",
    "python3",
    "pip",
    "cargo",
    "rustc",
    # Docker (read-only)
    "docker",
    "podman",
    # Misc
    "date",
    "echo",
    "printf",
    "true",
    "false",
    "which",
    "whoami",
    "id"
  ]

  # Commands allowed in test environment (includes extra testing utilities)
  @allowed_commands_test @allowed_commands_prod ++ ["seq", "exit", "test", "sleep"]

  @doc """
  Get the list of allowed root directories for file access.
  """
  @spec allowed_roots() :: [String.t()]
  def allowed_roots do
    # Can be configured via environment variable
    case System.get_env("NEX_ALLOWED_ROOTS") do
      nil -> @allowed_roots_default
      paths -> String.split(paths, ":") |> Enum.map(&Path.expand/1)
    end
  end

  @doc """
  Validate that a path is within allowed roots.

  Returns {:ok, expanded_path} if valid, {:error, reason} if not.
  """
  @spec validate_path(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def validate_path(path) do
    expanded = Path.expand(path)

    # Check for path traversal attempts
    if String.contains?(path, "..") and not safe_traversal?(path) do
      {:error, "Path traversal not allowed: #{path}"}
    else
      # Check if within allowed roots
      roots = allowed_roots()

      if Enum.any?(roots, fn root -> String.starts_with?(expanded, root) end) do
        {:ok, expanded}
      else
        {:error, "Path not within allowed roots. Allowed: #{Enum.join(roots, ", ")}"}
      end
    end
  end

  # Check if traversal is safe (doesn't escape allowed roots)
  defp safe_traversal?(path) do
    expanded = Path.expand(path)
    roots = allowed_roots()

    Enum.any?(roots, fn root ->
      String.starts_with?(expanded, root) && String.starts_with?(Path.expand(path), root)
    end)
  end

  @doc """
  Get the list of allowed commands.
  """
  @spec allowed_commands() :: [String.t()]
  def allowed_commands do
    if Application.get_env(:nex_agent, :env) == :test do
      @allowed_commands_test
    else
      @allowed_commands_prod
    end
  end

  @doc """
  Validate a command against the whitelist.

  Returns :ok if allowed, {:error, reason} if not.
  """
  @spec validate_command(String.t()) :: :ok | {:error, String.t()}
  def validate_command("") do
    # Empty command is allowed (will fail at execution)
    :ok
  end

  def validate_command(command) do
    # Extract the base command
    base_cmd = command |> String.trim() |> String.split() |> hd()

    # Check for dangerous patterns
    dangerous_patterns = [
      {~r/^rm\s+-rf\s+\//, "Recursive delete from root not allowed"},
      {~r/^\.\.\//, "Relative path traversal not allowed"},
      {~r/;\s*sh\s*-i/, "Interactive shell spawn not allowed"},
      {~r/\|.*sh$/, "Shell pipe to interactive shell not allowed"},
      {~r/curl.*\|.*sh/, "curl | sh pattern not allowed"},
      {~r/wget.*\|.*sh/, "wget | sh pattern not allowed"},
      {~r/>\s*\/dev\//, "Writing to /dev not allowed"},
      {~r/2>&1.*rm/, "Redirect stderr to rm not allowed"}
    ]

    # Check dangerous patterns first
    case Enum.find_value(dangerous_patterns, fn {pattern, reason} ->
           if Regex.match?(pattern, command), do: reason
         end) do
      nil ->
        # No dangerous pattern found, check whitelist
        allowed = allowed_commands()

        if base_cmd in allowed do
          :ok
        else
          {:error, "Command not allowed: #{base_cmd}. Allowed: #{Enum.join(allowed, ", ")}"}
        end

      reason ->
        {:error, reason}
    end
  end
end
