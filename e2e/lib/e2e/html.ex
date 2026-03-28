defmodule E2E.HTML do
  def parse!(html) do
    case Floki.parse_document(html) do
      {:ok, document} -> document
      _ -> Floki.parse_fragment!(html)
    end
  end

  def has_test_id?(html, test_id) do
    html
    |> parse!()
    |> find_by_test_id(test_id)
    |> Enum.any?()
  end

  def text_at(html, test_id) do
    html
    |> parse!()
    |> find_by_test_id(test_id)
    |> List.first()
    |> normalize_text()
  end

  def attr_at(html, test_id, attr) do
    html
    |> parse!()
    |> find_by_test_id(test_id)
    |> Floki.attribute(attr)
    |> List.first()
  end

  def first_attr(html, selector, attr) do
    html
    |> parse!()
    |> Floki.find(selector)
    |> Floki.attribute(attr)
    |> List.first()
  end

  def first_test_id_with_prefix(html, prefix) do
    html
    |> parse!()
    |> Floki.find("[data-testid]")
    |> Enum.find_value(fn node ->
      test_id =
        node
        |> Floki.attribute("data-testid")
        |> List.first()

      if is_binary(test_id) and String.starts_with?(test_id, prefix), do: test_id
    end)
  end

  defp find_by_test_id(document, test_id) do
    Floki.find(document, ~s([data-testid="#{test_id}"]))
  end

  defp normalize_text(nil), do: nil

  defp normalize_text(node) do
    node
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
