defmodule NexAI.Provider.Mistral do
  @moduledoc """
  Mistral AI Provider for NexAI.
  Implements the LanguageModel protocol for Mistral's models.
  """
  alias NexAI.LanguageModel.Protocol, as: ModelProtocol
  alias NexAI.LanguageModel.{GenerateResult, StreamPart, ResponseMetadata}

  defstruct [:api_key, :base_url, model: "mistral-small-latest", config: %{}]

  @default_base_url "https://api.mistral.ai/v1"

  def chat(model_id, opts \\ []) do
    %__MODULE__{
      model: model_id,
      api_key: opts[:api_key] || Application.get_env(:nex_ai, :mistral_api_key) || System.get_env("MISTRAL_API_KEY"),
      base_url: opts[:base_url] || Application.get_env(:nex_ai, :mistral_base_url) || System.get_env("MISTRAL_BASE_URL") || @default_base_url,
      config: Map.new(opts)
    }
  end

  defimpl ModelProtocol do
    alias NexAI.Provider.OpenAI

    def provider(_model), do: "mistral"
    def model_id(model), do: model.model

    def do_generate(model, params) do
      url = model.base_url <> "/chat/completions"
      messages = params.prompt |> NexAI.Message.normalize() |> OpenAI.format_messages()

      body = %{
        model: model.model,
        messages: messages,
        stream: false
      }

      body = if params.tools && length(params.tools) > 0, do: Map.put(body, :tools, OpenAI.format_tools(params.tools)), else: body
      body = if tc = params.tool_choice, do: Map.put(body, :tool_choice, tc), else: body
      body = if rf = params.response_format, do: Map.put(body, :response_format, rf), else: body
      body = Map.merge(body, model.config)

      finch_name = model.config[:finch] || NexAI.Finch
      case Req.post(url, json: body, auth: {:bearer, model.api_key}, finch: finch_name) do
        {:ok, %{status: 200, body: body, headers: _headers}} ->
          message = get_in(body, ["choices", Access.at(0), "message"])

          {:ok, %GenerateResult{
            content: build_content(message),
            finish_reason: OpenAI.map_finish_reason(get_in(body, ["choices", Access.at(0), "finish_reason"])),
            usage: OpenAI.format_usage(body["usage"]),
            response: %ResponseMetadata{
              id: body["id"],
              model_id: body["model"],
              timestamp: body["created"],
              headers: %{}
            },
            raw_call: %{model_id: model.model, provider: "mistral", params: params},
            raw_response: body
          }}

        {:ok, %{status: 401, body: body}} ->
          {:error, %NexAI.Error.AuthenticationError{message: get_in(body, ["error", "message"]) || "Invalid API Key", status: 401, raw: body}}

        {:ok, %{status: 429, body: body}} ->
          {:error, %NexAI.Error.RateLimitError{message: get_in(body, ["error", "message"]) || "Rate limit reached"}}

        {:ok, %{status: 400, body: body}} ->
          {:error, %NexAI.Error.InvalidRequestError{message: get_in(body, ["error", "message"]), status: 400, raw: body}}

        {:ok, %{status: status, body: body}} ->
          {:error, %NexAI.Error.APIError{message: get_in(body, ["error", "message"]), status: status, type: get_in(body, ["error", "type"]), raw: body}}

        {:error, reason} ->
          {:error, reason}
      end
    end

    def do_stream(model, params) do
      url = model.base_url <> "/chat/completions"
      messages = params.prompt |> NexAI.Message.normalize() |> OpenAI.format_messages()

      body = %{
        model: model.model,
        messages: messages,
        stream: true
      }

      body = if params.tools && length(params.tools) > 0, do: Map.put(body, :tools, OpenAI.format_tools(params.tools)), else: body
      body = if tc = params.tool_choice, do: Map.put(body, :tool_choice, tc), else: body
      body = if rf = params.response_format, do: Map.put(body, :response_format, rf), else: body
      body = Map.merge(body, model.config)

      parent = self()
      receive_timeout = params.config[:receive_timeout] || 30_000

      Stream.resource(
        fn ->
          task = Task.Supervisor.async_nolink(NexAI.TaskSupervisor, fn ->
            finch_name = model.config[:finch] || NexAI.Finch
            Req.post(url,
              json: body,
              auth: {:bearer, model.api_key},
              finch: finch_name,
              into: fn {:data, data}, acc ->
                send(parent, {:stream_data, self(), data})
                receive do
                  :ack -> {:cont, acc}
                after
                  receive_timeout -> {:halt, acc}
                end
              end
            )
            send(parent, :stream_done)
          end)
          %{task: task, buffer: "", done: false, response_sent: false}
        end,
        fn
          %{done: true} = state -> {:halt, state}
          state ->
            receive do
              {:stream_data, pid, data} ->
                {lines, new_buffer} = OpenAI.process_line_buffer(state.buffer <> data)
                raw_chunks = OpenAI.parse_lines(lines)
                send(pid, :ack)
                {parts, state} = OpenAI.map_to_stream_parts(raw_chunks, state)
                {parts, %{state | buffer: new_buffer}}

              :stream_done ->
                {lines, _} = OpenAI.process_line_buffer(state.buffer, true)
                raw_chunks = OpenAI.parse_lines(lines)
                {parts, state} = OpenAI.map_to_stream_parts(raw_chunks, state)
                {parts, %{state | done: true, buffer: ""}}

            after
              receive_timeout ->
                Task.shutdown(state.task)
                err = %NexAI.Error.TimeoutError{message: "NexAI Streaming Timeout after #{receive_timeout}ms", timeout_ms: receive_timeout}
                {[%StreamPart{type: :error, error: err}], %{state | done: true}}
            end
        end,
        fn state -> Task.shutdown(state.task) end
      )
    end

    defp build_content(message) do
      content = message["content"] || ""
      tool_calls = OpenAI.extract_tool_calls(message["tool_calls"])

      result = [%{type: "text", text: content}]

      result = if length(tool_calls) > 0 do
        result ++ Enum.map(tool_calls, fn tc ->
          %{
            type: "tool-call",
            toolCallId: tc.toolCallId,
            toolName: tc.toolName,
            args: tc.args
          }
        end)
      else
        result
      end

      result
    end
  end
end
