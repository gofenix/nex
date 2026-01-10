defmodule NexAI.Message do
  @moduledoc """
  Defines standardized message structures for NexAI.
  Matches Vercel AI SDK Core Messages.
  """

  defmodule System do
    @derive Jason.Encoder
    defstruct [:content, role: "system"]
  end

  defmodule User do
    @derive Jason.Encoder
    defstruct [:content, role: "user"]
  end

  defmodule Assistant do
    @derive Jason.Encoder
    defstruct [:content, :tool_calls, role: "assistant"]
  end

  defmodule Tool do
    @derive Jason.Encoder
    defstruct [:content, :tool_call_id, role: "tool"]
  end

  @doc "Normalizes any message-like input into a Core Message map with string keys."
  def normalize(messages) when is_list(messages) do
    Enum.map(messages, &normalize/1)
  end

  def normalize(%System{} = msg), do: msg
  def normalize(%User{} = msg), do: msg
  def normalize(%Assistant{} = msg), do: msg
  def normalize(%Tool{} = msg), do: msg

  # Handle maps with atom or string keys
  def normalize(msg) when is_map(msg) do
    role = to_string(msg[:role] || msg["role"])
    content = msg[:content] || msg["content"]

    case role do
      "system" -> %System{content: content}
      "user" -> %User{content: content}
      "assistant" ->
        %Assistant{content: content, tool_calls: msg[:tool_calls] || msg["tool_calls"]}
      "tool" ->
        %Tool{content: content, tool_call_id: msg[:tool_call_id] || msg["tool_call_id"]}
      _ ->
        # Fallback to map if role is unknown, but normalize keys
        %{"role" => role, "content" => content}
    end
  end

  defp purge_nils(map) do
    map |> Enum.reject(fn {_, v} -> is_nil(v) end) |> Map.new()
  end
end
