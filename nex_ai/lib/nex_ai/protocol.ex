defmodule NexAI.Protocol do
  @moduledoc """
  Implements the Vercel AI SDK Data Stream Protocol (v1 / AI SDK 6).
  Uses prefix-based encoding for maximum compatibility and performance.
  
  Format: <prefix>:<JSON stringified payload>\n
  """

  @doc "Encodes to Data Stream Protocol"
  def encode(type, payload)
  
  # 0: Text delta
  def encode(:text, text) when is_binary(text), do: "0:#{Jason.encode!(text)}\n"
  
  # 1: Data part
  def encode(:data, data), do: "1:#{Jason.encode!(data)}\n"
  
  # 2: Error part
  def encode(:error, error), do: "2:#{Jason.encode!(error)}\n"
  
  # 3: Control part (e.g. finish reason)
  def encode(:control, control), do: "3:#{Jason.encode!(control)}\n"
  
  # 8: Message metadata
  def encode(:metadata, meta), do: "8:#{Jason.encode!(meta)}\n"
  
  # 9: Tool call start/input
  def encode(:tool_call, %{toolCallId: id, toolName: name, args: args}) do
    "9:#{Jason.encode!(%{toolCallId: id, toolName: name, args: args})}\n"
  end

  # a: Tool result
  def encode(:tool_result, %{toolCallId: id, result: result}) do
    "a:#{Jason.encode!(%{toolCallId: id, result: result})}\n"
  end

  # b: Tool call start (AI SDK 4+ / v1 Data Stream)
  def encode(:tool_call_start, %{toolCallId: id, toolName: name}) do
    "b:#{Jason.encode!(%{toolCallId: id, toolName: name})}\n"
  end

  # c: Tool call delta
  def encode(:tool_call_delta, %{toolCallId: id, inputTextDelta: delta}) do
    "c:#{Jason.encode!(%{toolCallId: id, inputTextDelta: delta})}\n"
  end

  # d: Finish part
  def encode(:stream_finish, payload) do
    "d:#{Jason.encode!(payload)}\n"
  end

  # e: Object delta (Experimental)
  def encode(:object_delta, delta) when is_binary(delta) do
    "e:#{Jason.encode!(delta)}\n"
  end

  def encode(type, payload) do
    # Fallback for unknown parts
    "x-#{type}:#{Jason.encode!(payload)}\n"
  end
end
