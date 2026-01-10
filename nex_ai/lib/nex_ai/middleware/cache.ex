defmodule NexAI.Middleware.Cache do
  @moduledoc """
  Cache middleware for NexAI.
  Caches generate results based on prompt hash.
  """
  @behaviour NexAI.Middleware

  def wrap_generate(model, params, opts, next) do
    cache_key = generate_cache_key(model, params)
    cache_module = opts[:cache] || NexAI.Cache.ETS
    ttl = opts[:ttl] || 3600

    case cache_module.get(cache_key) do
      {:ok, cached_result} ->
        {:ok, cached_result}

      _ ->
        case next.(model, params) do
          {:ok, result} = success ->
            cache_module.put(cache_key, result, ttl)
            success

          error ->
            error
        end
    end
  end

  def wrap_stream(model, params, _opts, next) do
    next.(model, params)
  end

  defp generate_cache_key(model, params) do
    provider = NexAI.LanguageModel.Protocol.provider(model)
    model_id = NexAI.LanguageModel.Protocol.model_id(model)
    prompt_hash = :crypto.hash(:sha256, :erlang.term_to_binary(params.prompt)) |> Base.encode16()
    "#{provider}:#{model_id}:#{prompt_hash}"
  end
end

defmodule NexAI.Cache.ETS do
  @moduledoc """
  Simple ETS-based cache implementation.
  """
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    table = :ets.new(:nex_ai_cache, [:set, :public, :named_table])
    {:ok, %{table: table}}
  end

  def get(key) do
    case :ets.lookup(:nex_ai_cache, key) do
      [{^key, value, expires_at}] ->
        if System.system_time(:second) < expires_at do
          {:ok, value}
        else
          :ets.delete(:nex_ai_cache, key)
          {:error, :expired}
        end

      [] ->
        {:error, :not_found}
    end
  end

  def put(key, value, ttl) do
    expires_at = System.system_time(:second) + ttl
    :ets.insert(:nex_ai_cache, {key, value, expires_at})
    :ok
  end

  def delete(key) do
    :ets.delete(:nex_ai_cache, key)
    :ok
  end

  def clear do
    :ets.delete_all_objects(:nex_ai_cache)
    :ok
  end
end
