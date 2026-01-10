defmodule NexAI.LanguageModel do
  @moduledoc """
  The LanguageModel definitions for NexAI.
  Inspired by Vercel AI SDK LanguageModelV3.
  """

  @type message :: %{role: String.t(), content: any()}

  @type params :: %{
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
  Aligned with Vercel AI SDK v6 LanguageModelV1 specification.
  """

  @doc "The provider name (e.g. 'openai')"
  def provider(model)

  @doc "The model name (e.g. 'gpt-4o')"
  def model_id(model)

  @doc """
  Generates a complete response.
  Returns {:ok, %NexAI.LanguageModel.V1.GenerateResult{}}
  """
  def do_generate(model, params)

  @doc """
  Generates a streaming response.
  Returns {:ok, Enumerable.t(%NexAI.LanguageModel.V1.StreamChunk{})}
  """
  def do_stream(model, params)
end

defprotocol NexAI.LanguageModel.V3.Protocol do
  @moduledoc """
  The LanguageModelV3 protocol defines the interface for all AI providers.
  Aligned with Vercel AI SDK v6 LanguageModelV3 specification.
  """

  @doc "The provider name (e.g. 'openai')"
  def provider(model)

  @doc "The model name (e.g. 'gpt-4o')"
  def model_id(model)

  @doc """
  Generates a language model output (non-streaming).
  Returns {:ok, %NexAI.LanguageModel.V3.GenerateResult{}}
  """
  def do_generate(model, options)

  @doc """
  Generates a language model output (streaming).
  Returns {:ok, Enumerable.t(%NexAI.LanguageModel.V3.StreamPart{})}
  """
  def do_stream(model, options)
end

defmodule NexAI.LanguageModel.V1.CallMetadata do
  defstruct [:model_id, :provider, :params, :raw_request]
end

defmodule NexAI.LanguageModel.V1.ResponseMetadata do
  defstruct [:id, :timestamp, :model_id, :headers]
end

defmodule NexAI.LanguageModel.V1.GenerateResult do
  defstruct [
    :text,
    :reasoning,
    :tool_calls,
    :finish_reason,
    :usage,
    :response, # %NexAI.LanguageModel.V1.ResponseMetadata{}
    :raw_call, # %NexAI.LanguageModel.V1.CallMetadata{}
    :warnings
  ]
end

defmodule NexAI.LanguageModel.V1.StreamChunk do
  @type chunk_type ::
    :text_delta |
    :reasoning_delta |
    :tool_call_start |
    :tool_call_delta |
    :tool_call_finish |
    :response_metadata |
    :finish |
    :error |
    :usage

  defstruct [:type, :content, :tool_call_id, :tool_name, :args_delta, :finish_reason, :usage, :response]
end

defmodule NexAI.LanguageModel.V3 do
  @moduledoc "Standardized structures for LanguageModelV3 compatibility."

  defmodule ResponseMetadata do
    defstruct [:id, :timestamp, :model_id, :headers]
  end

  defmodule GenerateResult do
    defstruct [:content, :finish_reason, :usage, :raw_call, :raw_response, :warnings, :provider_metadata]
  end

  defmodule StreamPart do
    @type part_type ::
      :text_delta |
      :reasoning_delta |
      :tool_call_start |
      :tool_call_delta |
      :tool_call |
      :tool_result |
      :response_metadata |
      :finish |
      :error |
      :usage

    defstruct [:type, :content, :text, :tool_call_id, :tool_name, :args_delta, :finish_reason, :usage, :response, :error]
  end
end

defmodule NexAI.LanguageModel.V1 do
  @moduledoc "Standardized structures for LanguageModelV1 compatibility (Vercel AI SDK v6)."
  alias NexAI.LanguageModel.V1.{CallMetadata, ResponseMetadata, GenerateResult, StreamChunk}
end
