defmodule NexAI.StreamHelpers do
  @moduledoc """
  Helper functions for working with AI streams.
  Inspired by Vercel AI SDK's stream utilities.
  """

  @doc """
  Converts a stream to text by concatenating all text deltas.
  """
  def stream_to_text(stream) do
    stream
    |> Enum.reduce("", fn chunk, acc ->
      if chunk.type == :text_delta do
        acc <> chunk.content
      else
        acc
      end
    end)
  end

  @doc """
  Splits a stream into multiple consumers.
  Each consumer gets a copy of all chunks.
  """
  def tee_stream(stream, n \\ 2) do
    chunks = Enum.to_list(stream)
    List.duplicate(chunks, n) |> Enum.map(&Stream.into(&1, []))
  end

  @doc """
  Merges multiple streams into one.
  """
  def merge_streams(streams) do
    Stream.concat(streams)
  end

  @doc """
  Filters stream chunks by type.
  """
  def filter_by_type(stream, type) do
    Stream.filter(stream, &(&1.type == type))
  end

  @doc """
  Maps stream chunks to a different format.
  """
  def map_stream(stream, mapper) do
    Stream.map(stream, mapper)
  end

  @doc """
  Collects all chunks of a specific type.
  """
  def collect_type(stream, type) do
    stream
    |> filter_by_type(type)
    |> Enum.to_list()
  end

  @doc """
  Converts stream to async enumerable that can be consumed from multiple processes.
  """
  def to_async_stream(stream) do
    parent = self()

    Task.async(fn ->
      Enum.each(stream, fn chunk ->
        send(parent, {:chunk, chunk})
      end)
      send(parent, :done)
    end)

    Stream.resource(
      fn -> :waiting end,
      fn
        :done -> {:halt, :done}
        state ->
          receive do
            {:chunk, chunk} -> {[chunk], state}
            :done -> {:halt, :done}
          end
      end,
      fn _ -> :ok end
    )
  end

  @doc """
  Buffers stream chunks and emits them in batches.
  """
  def batch_stream(stream, size) do
    Stream.chunk_every(stream, size)
  end

  @doc """
  Throttles stream emission to a maximum rate.
  """
  def throttle_stream(stream, delay_ms) do
    Stream.map(stream, fn chunk ->
      Process.sleep(delay_ms)
      chunk
    end)
  end

  @doc """
  Adds timestamps to each chunk.
  """
  def timestamp_stream(stream) do
    Stream.map(stream, fn chunk ->
      Map.put(chunk, :timestamp, System.system_time(:millisecond))
    end)
  end

  @doc """
  Converts stream to Server-Sent Events format.
  """
  def to_sse(stream) do
    Stream.map(stream, fn chunk ->
      data = Jason.encode!(chunk)
      "data: #{data}\n\n"
    end)
  end

  @doc """
  Runs a callback for each chunk without modifying the stream.
  """
  def tap_stream(stream, callback) do
    Stream.map(stream, fn chunk ->
      callback.(chunk)
      chunk
    end)
  end

  @doc """
  Accumulates stream state and emits both chunk and accumulated state.
  """
  def scan_stream(stream, initial_acc, scanner) do
    Stream.transform(stream, initial_acc, fn chunk, acc ->
      {new_chunk, new_acc} = scanner.(chunk, acc)
      {[new_chunk], new_acc}
    end)
  end

  @doc """
  Takes only the first N chunks from the stream.
  """
  def take_stream(stream, n) do
    Stream.take(stream, n)
  end

  @doc """
  Drops the first N chunks from the stream.
  """
  def drop_stream(stream, n) do
    Stream.drop(stream, n)
  end

  @doc """
  Converts a stream result to a full response by consuming all chunks.
  """
  def consume_stream(%{full_stream: stream}) do
    chunks = Enum.to_list(stream)

    text = chunks
    |> Enum.filter(&(&1.type == :text_delta))
    |> Enum.map(&(&1.content))
    |> Enum.join("")

    usage = chunks
    |> Enum.find(&(&1.type == :usage))
    |> case do
      nil -> nil
      chunk -> chunk.usage
    end

    finish_reason = chunks
    |> Enum.find(&(&1.type == :finish))
    |> case do
      nil -> nil
      chunk -> chunk.finish_reason
    end

    %{
      text: text,
      usage: usage,
      finish_reason: finish_reason,
      chunks: chunks
    }
  end
end
