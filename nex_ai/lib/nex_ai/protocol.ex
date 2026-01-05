defmodule NexAI.Protocol do
  @moduledoc """
  Implements the Vercel AI SDK Data Stream Protocol (v6).
  
  Documentation: https://sdk.vercel.ai/docs/ai-sdk-ui/stream-protocol
  """

  @type part_type :: 
    :text | :data | :error | 
    :tool_call | :tool_result | 
    :tool_call_start | :tool_call_delta |
    :step_finish | :stream_finish | 
    :attachment | :metadata | :control |
    :diff

  @doc "Encodes to Data Stream Protocol (JSON over SSE) - AI SDK 6 Standard"
  def encode(type, payload)

  def encode(:text, text) when is_binary(text) do
    Jason.encode!(%{type: "text-delta", delta: text})
  end

  def encode(:tool_call_start, %{toolCallId: id, toolName: name}) do
    Jason.encode!(%{type: "tool-input-start", toolCallId: id, toolName: name})
  end

  def encode(:tool_call_delta, %{toolCallId: id, inputTextDelta: delta}) do
    Jason.encode!(%{type: "tool-input-delta", toolCallId: id, inputTextDelta: delta})
  end

  def encode(:tool_call, %{toolCallId: id, toolName: name, args: args}) do
    Jason.encode!(%{type: "tool-input-available", toolCallId: id, toolName: name, input: args})
  end

  def encode(:tool_result, %{toolCallId: id, result: result}) do
    Jason.encode!(%{type: "tool-output-available", toolCallId: id, output: result})
  end

  def encode(:error, error) when is_binary(error) do
    Jason.encode!(%{type: "error", errorText: error})
  end

  def encode(:stream_finish, _payload) do
    Jason.encode!(%{type: "finish"})
  end

  def encode(type, payload) when is_map(payload) do
    # Fallback for custom data parts
    Jason.encode!(payload |> Map.put_new(:type, "data-#{type}"))
  end
end
