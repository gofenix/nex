defmodule NexAI.Middleware.RateLimit do
  @moduledoc """
  Rate limiting middleware for NexAI.
  Limits the number of requests per time window.
  """
  @behaviour NexAI.Middleware

  def wrap_generate(model, params, opts, next) do
    max_requests = opts[:max_requests] || 10
    window_ms = opts[:window_ms] || 60_000

    case check_rate_limit(model, max_requests, window_ms) do
      :ok ->
        next.(model, params)

      {:error, wait_ms} ->
        if opts[:wait] do
          Process.sleep(wait_ms)
          next.(model, params)
        else
          {:error, %NexAI.Error.RateLimitError{message: "Rate limit exceeded, retry after #{wait_ms}ms"}}
        end
    end
  end

  def wrap_stream(model, params, opts, next) do
    max_requests = opts[:max_requests] || 10
    window_ms = opts[:window_ms] || 60_000

    case check_rate_limit(model, max_requests, window_ms) do
      :ok ->
        next.(model, params)

      {:error, wait_ms} ->
        if opts[:wait] do
          Process.sleep(wait_ms)
          next.(model, params)
        else
          Stream.resource(
            fn -> :error end,
            fn :error ->
              {[%NexAI.LanguageModel.StreamPart{
                type: :error,
                error: %NexAI.Error.RateLimitError{message: "Rate limit exceeded, retry after #{wait_ms}ms"}
              }], :done}
              :done -> {:halt, :done}
            end,
            fn _ -> :ok end
          )
        end
    end
  end

  defp check_rate_limit(model, max_requests, window_ms) do
    key = rate_limit_key(model)
    now = System.system_time(:millisecond)

    case :ets.lookup(:nex_ai_rate_limits, key) do
      [{^key, timestamps}] ->
        recent = Enum.filter(timestamps, &(&1 > now - window_ms))

        if length(recent) >= max_requests do
          oldest = List.first(recent)
          wait_ms = oldest + window_ms - now
          {:error, wait_ms}
        else
          :ets.insert(:nex_ai_rate_limits, {key, [now | recent]})
          :ok
        end

      [] ->
        :ets.insert(:nex_ai_rate_limits, {key, [now]})
        :ok
    end
  end

  defp rate_limit_key(model) do
    provider = NexAI.LanguageModel.Protocol.provider(model)
    model_id = NexAI.LanguageModel.Protocol.model_id(model)
    "#{provider}:#{model_id}"
  end

  def init_table do
    :ets.new(:nex_ai_rate_limits, [:set, :public, :named_table])
  end
end
