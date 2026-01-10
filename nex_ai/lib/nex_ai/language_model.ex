defmodule NexAI.LanguageModel do
  @moduledoc """
  The LanguageModel definitions for NexAI.
  Aligned with Vercel AI SDK v6 LanguageModelV3 specification.
  """

  @type message :: %{role: String.t(), content: any()}

  @type call_options :: %{
    prompt: [message()],
    mode: :text | :object | :tool_use,
    tools: [map()] | nil,
    tool_choice: any(),
    response_format: map() | nil,
    config: map()
  }
end

defprotocol NexAI.LanguageModel.Protocol do
  @moduledoc """
  The LanguageModel protocol defines the interface for all AI providers.
  Aligned with Vercel AI SDK v6 LanguageModelV3 specification.
  """

  @doc "The provider name (e.g. 'openai')"
  def provider(model)

  @doc "The model name (e.g. 'gpt-4o')"
  def model_id(model)

  @doc """
  Generates a language model output (non-streaming).
  Returns {:ok, %NexAI.LanguageModel.GenerateResult{}}
  """
  def do_generate(model, options)

  @doc """
  Generates a language model output (streaming).
  Returns {:ok, %NexAI.LanguageModel.StreamResult{}}
  """
  def do_stream(model, options)
end

defmodule NexAI.LanguageModel.ResponseMetadata do
  @moduledoc "Response metadata for a language model call."
  @type t :: %__MODULE__{
    id: String.t() | nil,
    timestamp: integer() | nil,
    model_id: String.t() | nil,
    headers: map() | nil
  }

  defstruct [:id, :timestamp, :model_id, :headers]
end

defmodule NexAI.LanguageModel.GenerateResult do
  @moduledoc "Result of a non-streaming language model call."
  @type t :: %__MODULE__{
    content: [map()],
    finish_reason: String.t(),
    usage: NexAI.Result.Usage.t() | nil,
    raw_call: map() | nil,
    raw_response: map() | nil,
    warnings: [map()] | nil,
    provider_metadata: map() | nil,
    response: NexAI.LanguageModel.ResponseMetadata.t() | nil
  }

  defstruct [
    :content,
    :finish_reason,
    :usage,
    :raw_call,
    :raw_response,
    :warnings,
    :provider_metadata,
    :response
  ]
end

defmodule NexAI.LanguageModel.StreamResult do
  @moduledoc "Result of a streaming language model call."
  @type t :: %__MODULE__{
    stream: Enumerable.t(map()),
    raw_call: map() | nil,
    warnings: [map()] | nil
  }

  defstruct [:stream, :raw_call, :warnings]
end

defmodule NexAI.LanguageModel.StreamPart do
  @moduledoc "A single part in a language model stream."

  @type part_type ::
    :text_delta |
    :reasoning_delta |
    :tool_call |
    :tool_result |
    :tool_call_start |
    :tool_call_delta |
    :tool_call_finish |
    :response_metadata |
    :finish |
    :error |
    :usage |
    :file |
    :source

  @type t :: %__MODULE__{
    type: part_type(),
    content: String.t() | nil,
    text: String.t() | nil,
    tool_call_id: String.t() | nil,
    tool_name: String.t() | nil,
    args_delta: String.t() | nil,
    finish_reason: String.t() | nil,
    usage: NexAI.Result.Usage.t() | nil,
    response: NexAI.LanguageModel.ResponseMetadata.t() | nil,
    error: Exception.t() | nil
  }

  defstruct [
    :type,
    :content,
    :text,
    :tool_call_id,
    :tool_name,
    :args_delta,
    :finish_reason,
    :usage,
    :response,
    :error
  ]
end

defmodule NexAI.LanguageModel.Content do
  @moduledoc "Content types for language model output."

  @type t ::
    %{type: "text", text: String.t()} |
    %{type: "reasoning", reasoning: String.t()} |
    %{type: "tool-call", toolCallId: String.t(), toolName: String.t(), args: map()} |
    %{type: "tool-result", toolCallId: String.t(), toolName: String.t(), result: map()} |
    %{type: "file", data: String.t(), mimeType: String.t()} |
    %{type: "source", source: map()}
end

defmodule NexAI.LanguageModel.Usage do
  @moduledoc "Token usage information."
  @type t :: %__MODULE__{
    prompt_tokens: non_neg_integer(),
    completion_tokens: non_neg_integer(),
    total_tokens: non_neg_integer()
  }

  defstruct [:prompt_tokens, :completion_tokens, :total_tokens]
end

defmodule NexAI.LanguageModel.FinishReason do
  @moduledoc "Reason why a language model finished generating."

  @type t :: "stop" | "length" | "content-filter" | "tool-calls" | "error" | "other"
end
