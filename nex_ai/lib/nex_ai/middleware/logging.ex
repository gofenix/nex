defmodule NexAI.Middleware.Logging do
  @moduledoc """
  Logging middleware for NexAI.
  Logs all requests and responses for debugging.
  """
  @behaviour NexAI.Middleware
  require Logger

  def wrap_generate(model, params, opts, next) do
    level = opts[:level] || :info
    provider = NexAI.LanguageModel.Protocol.provider(model)
    model_id = NexAI.LanguageModel.Protocol.model_id(model)

    Logger.log(level, "[NexAI] Generating with #{provider}/#{model_id}")

    start_time = System.monotonic_time(:millisecond)
    result = next.(model, params)
    duration = System.monotonic_time(:millisecond) - start_time

    case result do
      {:ok, res} ->
        Logger.log(level, "[NexAI] Generated #{res.usage.totalTokens || 0} tokens in #{duration}ms")

      {:error, error} ->
        Logger.log(:error, "[NexAI] Generation failed: #{inspect(error)}")
    end

    result
  end

  def wrap_stream(model, params, opts, next) do
    level = opts[:level] || :info
    provider = NexAI.LanguageModel.Protocol.provider(model)
    model_id = NexAI.LanguageModel.Protocol.model_id(model)

    Logger.log(level, "[NexAI] Streaming with #{provider}/#{model_id}")

    next.(model, params)
    |> Stream.map(fn chunk ->
      if opts[:log_chunks] do
        Logger.log(level, "[NexAI] Chunk: #{inspect(chunk.type)}")
      end
      chunk
    end)
  end
end
