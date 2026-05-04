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

  test "public docs do not describe AGENTS.md as the single source of truth" do
    assert_public_docs_do_not_match(
      ~r/AGENTS\.md.*single source of truth|single source of truth.*AGENTS\.md/i,
      "Found stale AGENTS.md single-source guidance"
    )
  end

  test "key AI onboarding docs mention the project-local skill path" do
    assert_files_match(
      [
        "README.md",
        "installer/README.md",
        "website/priv/docs/vibe_coding_guide.md",
        "installer/lib/nex/new/legacy.ex"
      ],
      ~r/\.agents\/skills\/nex-project\/SKILL\.md/,
      "Expected AI onboarding docs to mention the project-local skill path"
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

  defp assert_files_match(files, pattern, message) do
    offenders =
      files
      |> Enum.map(&Path.join(@repo_root, &1))
      |> Enum.reject(fn path ->
        path
        |> File.read!()
        |> String.match?(pattern)
      end)

    assert offenders == [], format_failure(message, offenders)
  end

  defp public_doc_files do
    [
      "README.md",
      "installer/README.md",
      "website/README.md",
      "website/src/pages/features.ex",
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
