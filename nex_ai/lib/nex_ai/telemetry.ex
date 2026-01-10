defmodule NexAI.Telemetry do
  @moduledoc """
  Telemetry instrumentation for NexAI.
  Provides observability for AI operations.
  """

  @doc """
  Attaches default telemetry handlers for logging.
  """
  def attach_default_handlers do
    events = [
      [:nex_ai, :generate, :start],
      [:nex_ai, :generate, :stop],
      [:nex_ai, :generate, :exception],
      [:nex_ai, :stream, :start],
      [:nex_ai, :stream, :stop],
      [:nex_ai, :provider, :request, :start],
      [:nex_ai, :provider, :request, :stop]
    ]

    :telemetry.attach_many(
      "nex-ai-default-handlers",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc """
  Default telemetry event handler.
  """
  def handle_event([:nex_ai, :generate, :start], _measurements, metadata, _config) do
    model = metadata[:opts][:model]
    provider = if model, do: NexAI.LanguageModel.Protocol.provider(model), else: "unknown"
    model_id = if model, do: NexAI.LanguageModel.Protocol.model_id(model), else: "unknown"

    IO.puts("[NexAI] Starting generation with #{provider}/#{model_id}")
  end

  def handle_event([:nex_ai, :generate, :stop], measurements, metadata, _config) do
    duration = measurements[:duration]
    result = metadata[:result]

    case result do
      {:ok, res} ->
        tokens = if res.usage, do: res.usage.totalTokens, else: 0
        IO.puts("[NexAI] Generation completed: #{tokens} tokens in #{duration}ms")

      {:error, _} ->
        IO.puts("[NexAI] Generation failed after #{duration}ms")
    end
  end

  def handle_event([:nex_ai, :stream, :start], _measurements, _metadata, _config) do
    IO.puts("[NexAI] Starting stream")
  end

  def handle_event([:nex_ai, :stream, :stop], _measurements, metadata, _config) do
    IO.puts("[NexAI] Stream stopped: #{metadata[:status]}")
  end

  def handle_event([:nex_ai, :provider, :request, :start], _measurements, metadata, _config) do
    IO.puts("[NexAI] Provider request: #{metadata[:provider]}/#{metadata[:model]}")
  end

  def handle_event([:nex_ai, :provider, :request, :stop], measurements, metadata, _config) do
    duration = measurements[:duration]

    case metadata[:result] do
      {:ok, _} ->
        IO.puts("[NexAI] Provider request succeeded in #{duration}ms")

      {:error, error} ->
        IO.puts("[NexAI] Provider request failed: #{inspect(error)}")
    end
  end

  def handle_event(_event, _measurements, _metadata, _config) do
    :ok
  end

  @doc """
  Creates a custom telemetry handler.
  """
  def attach_handler(handler_id, events, handler_function) do
    :telemetry.attach_many(handler_id, events, handler_function, nil)
  end

  @doc """
  Detaches a telemetry handler.
  """
  def detach_handler(handler_id) do
    :telemetry.detach(handler_id)
  end

  @doc """
  Lists all available telemetry events.
  """
  def list_events do
    [
      [:nex_ai, :generate, :start],
      [:nex_ai, :generate, :stop],
      [:nex_ai, :generate, :exception],
      [:nex_ai, :stream, :start],
      [:nex_ai, :stream, :stop],
      [:nex_ai, :provider, :request, :start],
      [:nex_ai, :provider, :request, :stop],
      [:nex_ai, :provider, :request, :exception],
      [:nex_ai, :tool, :execute, :start],
      [:nex_ai, :tool, :execute, :stop]
    ]
  end
end
