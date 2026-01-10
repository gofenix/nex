defmodule NexAI.Result do
  @moduledoc """
  Standardized result structures for NexAI.
  Matches Vercel AI SDK Core return types precisely.
  """

  defmodule Usage do
    @derive Jason.Encoder
    defstruct [:promptTokens, :completionTokens, :totalTokens]
  end

  defmodule Response do
    @moduledoc "Metadata about the model response."
    @derive Jason.Encoder
    defstruct [:id, :modelId, :timestamp, :headers]
  end

  defmodule Step do
    @moduledoc "Represents a single step in a multi-step generation."
    @derive Jason.Encoder
    defstruct [
      :stepType, # :initial, :tool_result
      :text,
      :reasoning,
      :toolCalls,
      :toolResults,
      :finishReason,
      :usage,
      :warnings,
      :response # %NexAI.LanguageModel.V1.ResponseMetadata{}
    ]
  end

  defmodule GenerateTextResult do
    @derive Jason.Encoder
    defstruct [
      :text,
      :reasoning,
      :toolCalls,
      :toolResults,
      :finishReason,
      :usage,
      :warnings,
      :response,
      :steps,
      :object, # Set when in object mode
      :raw_call # %NexAI.LanguageModel.V1.CallMetadata{}
    ]
  end

  defmodule ToolCall do
    @derive Jason.Encoder
    defstruct [:toolCallId, :toolName, :args]
  end

  defmodule ToolResult do
    @derive Jason.Encoder
    defstruct [:toolCallId, :toolName, :args, :result]
  end
end
