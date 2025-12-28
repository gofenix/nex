defmodule NexWebsite.CodeExamples do
  @moduledoc """
  Helper module for loading code examples from priv/code_examples/
  Reads Markdown files and extracts code blocks for display.
  """

  @examples_dir "priv/code_examples"

  def get(filename) do
    path = Path.join([@examples_dir, filename])
    content = File.read!(path)
    extract_code_block(content, filename)
  end

  def format_for_display({code, lang}, _prefix \\ ">") do
    escaped_code = escape_html(code)
    ~s(<pre><code class="language-#{lang}">#{escaped_code}</code></pre>)
  end

  defp extract_code_block(markdown, filename) do
    # Extract content between ```language and ```
    lang = detect_language(filename)
    case Regex.run(~r/```(\w*)\n(.*?)```/s, markdown) do
      [_, block_lang, code] ->
        code_lang = if block_lang == "", do: lang, else: block_lang
        {String.trim(code), code_lang}
      _ ->
        {String.trim(markdown), lang}
    end
  end

  defp detect_language(filename) do
    cond do
      String.contains?(filename, "routing") -> "bash"
      true -> "elixir"
    end
  end

  defp escape_html(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
end
