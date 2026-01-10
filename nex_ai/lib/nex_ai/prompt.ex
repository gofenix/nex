defmodule NexAI.Prompt do
  @moduledoc """
  Prompt engineering utilities for NexAI.
  Provides helpers for building and formatting prompts.
  """

  @doc """
  Creates a system message.
  """
  def system(content) do
    %NexAI.Message.System{content: content}
  end

  @doc """
  Creates a user message.
  """
  def user(content) do
    %NexAI.Message.User{content: content}
  end

  @doc """
  Creates an assistant message.
  """
  def assistant(content, opts \\ []) do
    %NexAI.Message.Assistant{
      content: content,
      tool_calls: opts[:tool_calls]
    }
  end

  @doc """
  Creates a tool message.
  """
  def tool(content, tool_call_id) do
    %NexAI.Message.Tool{
      content: content,
      tool_call_id: tool_call_id
    }
  end

  @doc """
  Creates a multi-modal user message with text and images.
  """
  def user_with_images(text, images) when is_list(images) do
    content = [%{type: "text", text: text}] ++
      Enum.map(images, fn
        %{url: url} -> %{type: "image", image: url, mime_type: "image/jpeg"}
        %{data: data, mime_type: mime} -> %{type: "image", image: data, mime_type: mime}
        url when is_binary(url) -> %{type: "image", image: url, mime_type: "image/jpeg"}
      end)

    %NexAI.Message.User{content: content}
  end

  @doc """
  Builds a conversation from a list of alternating user/assistant messages.
  """
  def conversation(messages) when is_list(messages) do
    Enum.map(messages, fn
      {:system, content} -> system(content)
      {:user, content} -> user(content)
      {:assistant, content} -> assistant(content)
      msg -> msg
    end)
  end

  @doc """
  Creates a few-shot prompt with examples.
  """
  def few_shot(system_prompt, examples, user_query) do
    system_msg = system(system_prompt)

    example_msgs = Enum.flat_map(examples, fn {user_ex, assistant_ex} ->
      [user(user_ex), assistant(assistant_ex)]
    end)

    [system_msg] ++ example_msgs ++ [user(user_query)]
  end

  @doc """
  Creates a chain-of-thought prompt.
  """
  def chain_of_thought(question) do
    system_prompt = """
    You are a helpful assistant that thinks step by step.
    For each question, break down your reasoning process before providing the final answer.
    """

    [
      system(system_prompt),
      user("#{question}\n\nLet's think step by step:")
    ]
  end

  @doc """
  Creates a structured output prompt.
  """
  def structured_output(instruction, schema) do
    schema_str = Jason.encode!(schema, pretty: true)

    system_prompt = """
    #{instruction}

    You must respond with valid JSON matching this schema:
    #{schema_str}
    """

    system(system_prompt)
  end

  @doc """
  Formats a prompt template with variables.
  """
  def format(template, vars) when is_map(vars) do
    Enum.reduce(vars, template, fn {key, value}, acc ->
      String.replace(acc, "{{#{key}}}", to_string(value))
    end)
  end

  @doc """
  Creates a role-playing prompt.
  """
  def role_play(role, context, task) do
    system_prompt = """
    You are #{role}.

    Context: #{context}

    Your task: #{task}
    """

    system(system_prompt)
  end

  @doc """
  Truncates messages to fit within a token limit.
  Simple character-based approximation (1 token ≈ 4 chars).
  """
  def truncate_messages(messages, max_tokens) do
    max_chars = max_tokens * 4

    messages
    |> Enum.reverse()
    |> Enum.reduce_while({[], 0}, fn msg, {acc, total_chars} ->
      content = if is_struct(msg), do: msg.content, else: msg["content"] || msg[:content]
      content_str = to_string(content)
      content_len = String.length(content_str)

      if total_chars + content_len <= max_chars do
        {:cont, {[msg | acc], total_chars + content_len}}
      else
        {:halt, {acc, total_chars}}
      end
    end)
    |> elem(0)
  end

  @doc """
  Combines multiple system prompts into one.
  """
  def merge_system_prompts(prompts) do
    combined = Enum.join(prompts, "\n\n---\n\n")
    system(combined)
  end

  @doc """
  Creates a summarization prompt.
  """
  def summarize(text, opts \\ []) do
    length = opts[:length] || "concise"
    style = opts[:style] || "neutral"

    [
      system("You are a helpful assistant that creates #{length} summaries in a #{style} style."),
      user("Please summarize the following text:\n\n#{text}")
    ]
  end

  @doc """
  Creates a translation prompt.
  """
  def translate(text, from_lang, to_lang) do
    [
      system("You are a professional translator."),
      user("Translate the following text from #{from_lang} to #{to_lang}:\n\n#{text}")
    ]
  end

  @doc """
  Creates a code generation prompt.
  """
  def generate_code(description, language) do
    [
      system("You are an expert #{language} programmer. Generate clean, efficient, and well-documented code."),
      user("Write #{language} code for the following:\n\n#{description}")
    ]
  end
end
