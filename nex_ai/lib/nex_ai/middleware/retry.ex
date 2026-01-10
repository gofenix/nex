defmodule NexAI.Middleware.Retry do
  @moduledoc """
  Retry middleware for NexAI.
  Automatically retries failed requests with exponential backoff.
  Equivalent to Vercel AI SDK's wrapLanguageModel with retry logic.
  """
  @behaviour NexAI.Middleware

  def wrap_generate(model, params, opts, next) do
    max_retries = opts[:max_retries] || 3
    initial_delay = opts[:initial_delay] || 1000
    max_delay = opts[:max_delay] || 10_000

    do_retry(fn -> next.(model, params) end, max_retries, initial_delay, max_delay, 0)
  end

  def wrap_stream(model, params, opts, next) do
    max_retries = opts[:max_retries] || 3
    initial_delay = opts[:initial_delay] || 1000
    max_delay = opts[:max_delay] || 10_000

    Stream.resource(
      fn -> {0, nil} end,
      fn {attempt, stream} ->
        if attempt >= max_retries do
          {:halt, {attempt, stream}}
        else
          try do
            stream = next.(model, params)
            case Enumerable.reduce(stream, {:cont, nil}, fn x, _ -> {:suspend, x} end) do
              {:suspended, chunk, continuation} ->
                {[chunk], {attempt, continuation}}
              _ ->
                {:halt, {attempt, nil}}
            end
          rescue
            e ->
              delay = calculate_delay(attempt, initial_delay, max_delay)
              Process.sleep(delay)
              {[], {attempt + 1, nil}}
          end
        end
      end,
      fn _ -> :ok end
    )
  end

  defp do_retry(fun, max_retries, initial_delay, max_delay, attempt) do
    case fun.() do
      {:ok, result} ->
        {:ok, result}

      {:error, %{__struct__: error_type} = error} when error_type in [
        NexAI.Error.RateLimitError,
        NexAI.Error.TimeoutError,
        NexAI.Error.APIError
      ] ->
        if attempt < max_retries do
          delay = calculate_delay(attempt, initial_delay, max_delay)
          Process.sleep(delay)
          do_retry(fun, max_retries, initial_delay, max_delay, attempt + 1)
        else
          {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp calculate_delay(attempt, initial_delay, max_delay) do
    delay = initial_delay * :math.pow(2, attempt)
    min(trunc(delay), max_delay)
  end
end
