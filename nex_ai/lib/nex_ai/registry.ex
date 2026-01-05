defmodule NexAI.Registry do
  @moduledoc """
  A registry for managing multiple AI model providers.
  Maps to `createProviderRegistry` in Vercel AI SDK.
  """
  
  defstruct [:providers]

  @doc """
  Creates a new provider registry.
  
  ## Example
      registry = NexAI.Registry.new(%{
        openai: NexAI.openai("gpt-4o"),
        anthropic: NexAI.anthropic("claude-3-5-sonnet")
      })
  """
  def new(providers \\ %{}) do
    %__MODULE__{providers: providers}
  end

  @doc """
  Retrieves a model from the registry by ID.
  """
  def language_model(registry, id) do
    case Map.get(registry.providers, String.to_atom(id) || id) do
      nil -> {:error, :provider_not_found}
      model -> model
    end
  end
end
