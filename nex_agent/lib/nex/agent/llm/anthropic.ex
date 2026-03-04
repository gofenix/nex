defmodule Nex.Agent.LLM.Anthropic do
  @behaviour Nex.Agent.LLM.Behaviour

  @base_url "https://api.anthropic.com/v1"

  def chat(messages, options) do
    model = Keyword.get(options, :model, "claude-sonnet-4-20250514")
    api_key = Keyword.fetch!(options, :api_key)
    max_tokens = Keyword.get(options, :max_tokens, 4096)
    temperature = Keyword.get(options, :temperature, 1.0)
    http_client = Keyword.get(options, :http_client, &Req.post/2)
    tools = Keyword.get(options, :tools, [])

    body = %{
      model: model,
      max_tokens: max_tokens,
      temperature: temperature,
      messages: transform_messages(messages),
      system: extract_system(messages)
    }

    body =
      if tools != [] do
        Map.put(body, :tools, transform_tools(tools))
      else
        body
      end

    result =
      http_client.("#{@base_url}/messages",
        json: body,
        headers: [
          {"x-api-key", api_key},
          {"anthropic-version", "2023-06-01"},
          {"content-type", "application/json"}
        ],
        receive_timeout: 600_000,
        connect_options: [timeout: 30_000]
      )

    case result do
      {:ok, %{status: 200, body: response}} ->
        content = response["content"] |> Enum.find(fn c -> c["type"] == "text" end)
        tool_calls = response["content"] |> Enum.filter(fn c -> c["type"] == "tool_use" end)

        {:ok,
         %{
           content: content && content["text"],
           tool_calls:
             if tool_calls != [] do
               Enum.map(tool_calls, fn tc ->
                 %{
                   id: tc["id"],
                   name: tc["name"],
                   arguments: tc["input"]
                 }
               end)
             else
               nil
             end,
           model: response["model"],
           usage: response["usage"]
         }}

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, error: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def stream(messages, options, callback) do
    model = Keyword.get(options, :model, "claude-sonnet-4-20250514")
    api_key = Keyword.fetch!(options, :api_key)
    http_client = Keyword.get(options, :http_client, &Req.post/2)

    body = %{
      model: model,
      max_tokens: 4096,
      temperature: 1.0,
      messages: transform_messages(messages),
      system: extract_system(messages),
      stream: true
    }

    req =
      Req.new(
        url: "#{@base_url}/messages",
        headers: [
          {"x-api-key", api_key},
          {"anthropic-version", "2023-06-01"},
          {"content-type", "application/json"}
        ]
      )

    result = http_client.(req, json: body)

    case result do
      {:ok, %{status: 200, body: stream}} ->
        Stream.each(stream, fn chunk ->
          callback.(chunk)
        end)
        |> Stream.run()

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, error: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def tools, do: []

  # Public for testing
  def transform_messages(messages) do
    messages
    |> Enum.filter(fn m -> m["role"] != "system" end)
    |> Enum.map(fn m ->
      case m["role"] do
        "assistant" ->
          if Map.has_key?(m, "tool_calls") and m["tool_calls"] != [] do
            %{
              role: "assistant",
              content:
                Enum.map(m["tool_calls"], fn tc ->
                  %{
                    type: "tool_use",
                    id: tc["id"],
                    name: tc["function"]["name"],
                    input: Jason.decode!(tc["function"]["arguments"])
                  }
                end)
            }
          else
            %{role: "assistant", content: m["content"]}
          end

        "tool" ->
          %{
            role: "user",
            content: "Result for tool_call #{m["tool_call_id"]}:\n#{m["content"]}"
          }

        _ ->
          %{role: m["role"], content: m["content"]}
      end
    end)
  end

  # Public for testing
  def extract_system(messages) do
    messages
    |> Enum.find(fn m -> m["role"] == "system" end)
    |> case do
      nil -> nil
      m -> m["content"]
    end
  end

  defp transform_tools(tools) do
    Enum.map(tools, fn tool ->
      input_schema = Map.get(tool, "input_schema") || %{}

      %{
        name: tool["name"],
        description: tool["description"],
        input_schema: input_schema
      }
    end)
  end
end
