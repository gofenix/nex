defmodule NexAI.PartialJSON do
  @moduledoc """
  A simple partial JSON parser for Elixir.
  Handles streaming JSON chunks and attempts to close open structures.
  """

  def parse("" = _text), do: {:ok, nil}

  def parse(text) do
    text = String.trim(text)

    # 1. Try direct parse first
    case Jason.decode(text) do
      {:ok, val} -> {:ok, val}
      {:error, _} ->
        # 2. Try to fix the JSON by closing brackets/braces
        case fix_json(text) do
          {:ok, fixed} -> Jason.decode(fixed)
          error -> error
        end
    end
  end

  defp fix_json(text) do
    stack = find_open_structures(text)

    fixed = Enum.reduce(stack, text, fn
      :obj, acc -> acc <> "}"
      :arr, acc -> acc <> "]"
    end)

    {:ok, fixed}
  rescue
    _ -> {:error, :unfixable}
  end

  defp find_open_structures(text) do
    chars = String.to_charlist(text)
    do_find_open_structures(chars, [], false)
  end

  defp do_find_open_structures([], stack, _in_string), do: stack

  defp do_find_open_structures([?" | rest], stack, false) do
    do_find_open_structures(rest, stack, true)
  end

  defp do_find_open_structures([?" | rest], stack, true) do
    do_find_open_structures(rest, stack, false)
  end

  defp do_find_open_structures([?\\, _char | rest], stack, true) do
    # Handle escaped characters inside strings
    do_find_open_structures(rest, stack, true)
  end

  defp do_find_open_structures([_char | rest], stack, true) do
    # Skip everything inside strings
    do_find_open_structures(rest, stack, true)
  end

  defp do_find_open_structures([?{ | rest], stack, false) do
    do_find_open_structures(rest, [:obj | stack], false)
  end

  defp do_find_open_structures([?} | rest], [:obj | stack], false) do
    do_find_open_structures(rest, stack, false)
  end

  defp do_find_open_structures([?[ | rest], stack, false) do
    do_find_open_structures(rest, [:arr | stack], false)
  end

  defp do_find_open_structures([?] | rest], [:arr | stack], false) do
    do_find_open_structures(rest, stack, false)
  end

  defp do_find_open_structures([_ | rest], stack, false) do
    do_find_open_structures(rest, stack, false)
  end
end
