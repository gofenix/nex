defmodule NexAI.ProviderRegistry do
  @moduledoc """
  Registry for managing multiple AI providers and models.
  Inspired by Vercel AI SDK's createProviderRegistry.
  """

  defstruct providers: %{}

  def new(providers \\ %{}) do
    %__MODULE__{providers: providers}
  end

  @doc """
  Registers a provider with a prefix.
  Example: registry |> register("openai", NexAI.openai("gpt-4o"))
  """
  def register(%__MODULE__{providers: p} = registry, prefix, provider_fn) when is_function(provider_fn, 1) do
    %{registry | providers: Map.put(p, prefix, provider_fn)}
  end

  @doc """
  Resolves a model string like "openai:gpt-4o" to a model instance.
  Supports provider factory functions and default settings.
  """
  def language_model(%__MODULE__{providers: p}, model_id, opts \\ []) do
    case String.split(model_id, ":", parts: 2) do
      [prefix, model] ->
        case p[prefix] do
          provider_fn when is_function(provider_fn, 1) ->
            provider_fn.(model)
          provider_fn when is_function(provider_fn, 2) ->
            provider_fn.(model, opts)
          nil ->
            {:error, "Provider not found: #{prefix}"}
        end
      _ ->
        # Fallback: check if any provider handles the full ID
        case p[model_id] do
          provider_fn when is_function(provider_fn, 1) -> provider_fn.(model_id)
          _ -> {:error, "Invalid model format. Expected 'provider:model', got: #{model_id}"}
        end
    end
  end
end
