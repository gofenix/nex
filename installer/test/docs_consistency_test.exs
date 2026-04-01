defmodule Nex.DocsConsistencyTest do
  use ExUnit.Case, async: true

  @repo_root Path.expand("../..", __DIR__)

  test "public docs do not mention the removed layouts.ex scaffold" do
    assert_public_docs_do_not_match(
      ~r/\bsrc\/layouts\.ex\b/,
      "Found stale src/layouts.ex references"
    )
  end

  test "public action examples do not use _params for action signatures" do
    assert_public_docs_do_not_match(
      ~r/def (?!mount)[a-z_]+\(_params\)/,
      "Found stale action examples using _params"
    )
  end

  test "public action examples do not pattern match flat maps by default" do
    assert_public_docs_do_not_match(
      ~r/def (?!mount)[a-z_]+\(%\{"id" => id\}\)/,
      "Found stale flat-map action examples"
    )
  end

  test "public docs do not describe action routing as referer-based" do
    assert_public_docs_do_not_match(
      ~r/referer-based|request source \(Referer\)/i,
      "Found stale referer-first action routing guidance"
    )
  end

  test "public docs do not describe req.body as always being a map" do
    assert_public_docs_do_not_match(
      ~r/always a Map(?:, never nil)?/i,
      "Found stale req.body documentation"
    )
  end

  defp assert_public_docs_do_not_match(pattern, message) do
    offenders =
      public_doc_files()
      |> Enum.filter(fn path ->
        path
        |> File.read!()
        |> String.match?(pattern)
      end)

    assert offenders == [], format_failure(message, offenders)
  end

  defp public_doc_files do
    [
      "README.md",
      "website/README.md",
      "website/src/pages/getting_started.ex",
      "website/priv/docs/**/*.md",
      "website/priv/code_examples/**/*.md",
      "examples/**/README.md",
      "installer/lib/nex/new/legacy.ex",
      "framework/lib/nex/cookie.ex",
      "framework/lib/nex/session.ex"
    ]
    |> Enum.flat_map(&Path.wildcard(Path.join(@repo_root, &1)))
    |> Enum.sort()
  end

  defp format_failure(message, offenders) do
    formatted =
      offenders
      |> Enum.map_join("\n", fn path -> "  - #{Path.relative_to(path, @repo_root)}" end)

    "#{message}:\n#{formatted}"
  end
end
