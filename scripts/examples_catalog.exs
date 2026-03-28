catalog_path = Path.expand("../examples/catalog.exs", __DIR__)
catalog = catalog_path |> Code.eval_file() |> elem(0)

mode =
  System.argv()
  |> List.first()
  |> Kernel.||("all")

filter_entries = fn key ->
  Enum.filter(catalog, &Map.get(&1, key, false))
end

render_matrix = fn entries ->
  entries
  |> Enum.map(fn entry ->
    slug = entry.slug
    ~s({"name":"#{slug}","cwd":"examples/#{slug}"})
  end)
  |> Enum.join(",")
  |> then(&~s({"include":[#{&1}]}))
end

case mode do
  "all" ->
    Enum.each(catalog, &IO.puts(&1.slug))

  "featured" ->
    Enum.each(filter_entries.(:featured), &IO.puts(&1.slug))

  "test" ->
    Enum.each(filter_entries.(:test), &IO.puts(&1.slug))

  "verify" ->
    Enum.each(filter_entries.(:verify), &IO.puts(&1.slug))

  "matrix" ->
    IO.puts("matrix=#{render_matrix.(filter_entries.(:test))}")

  other ->
    IO.puts(:stderr, "Unknown mode: #{other}")
    System.halt(1)
end
