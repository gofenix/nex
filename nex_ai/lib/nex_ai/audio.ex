defmodule NexAI.Audio do
  @moduledoc "Audio processing for NexAI (Speech & Transcription)."
  alias NexAI.Provider.OpenAI

  def transcribe(opts) do
    model = opts[:model] || OpenAI
    model.transcribe(opts[:file], opts)
  end

  def generate_speech(opts) do
    model = opts[:model] || OpenAI
    model.generate_speech(opts[:input] || opts[:text], opts)
  end
end
