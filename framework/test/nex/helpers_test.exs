defmodule Nex.HelpersTest do
  use ExUnit.Case, async: true
  alias Nex.Helpers

  describe "format_number/1" do
    test "returns 0 for nil" do
      assert Helpers.format_number(nil) == "0"
    end

    test "formats numbers below 1000" do
      assert Helpers.format_number(0) == "0"
      assert Helpers.format_number(1) == "1"
      assert Helpers.format_number(999) == "999"
    end

    test "formats thousands with k" do
      assert Helpers.format_number(1000) == "1.0k"
      assert Helpers.format_number(1200) == "1.2k"
      assert Helpers.format_number(45000) == "45.0k"
    end

    test "formats millions with M" do
      assert Helpers.format_number(1_000_000) == "1.0M"
      assert Helpers.format_number(1_500_000) == "1.5M"
    end
  end

  describe "format_date/1" do
    test "returns empty for nil" do
      assert Helpers.format_date(nil) == ""
    end

    test "formats Date" do
      assert Helpers.format_date(~D[2026-02-19]) == "Feb 19, 2026"
    end

    test "formats DateTime" do
      assert Helpers.format_date(~U[2026-02-19T10:30:00Z]) == "Feb 19, 2026"
    end

    test "parses ISO string" do
      assert Helpers.format_date("2026-02-19") == "Feb 19, 2026"
    end
  end

  describe "truncate/3" do
    test "returns empty for nil" do
      assert Helpers.truncate(nil, 10) == ""
    end

    test "returns as-is if shorter" do
      assert Helpers.truncate("Hello", 10) == "Hello"
    end

    test "truncates with ellipsis" do
      assert Helpers.truncate("Hello, world!", 8) == "Hello..."
    end
  end

  describe "pluralize/3" do
    test "singular for 1" do
      assert Helpers.pluralize(1, "item", "items") == "1 item"
    end

    test "plural for 0" do
      assert Helpers.pluralize(0, "item", "items") == "0 items"
    end

    test "plural for > 1" do
      assert Helpers.pluralize(5, "item", "items") == "5 items"
    end
  end

  describe "clsx/1" do
    test "empty for empty list" do
      assert Helpers.clsx([]) == ""
    end

    test "joins strings" do
      assert Helpers.clsx(["a", "b"]) == "a b"
    end

    test "filters falsy" do
      assert Helpers.clsx(["a", nil, false, "b"]) == "a b"
    end
  end

  describe "time_ago/1" do
    test "empty for nil" do
      assert Helpers.time_ago(nil) == ""
    end

    test "just now for recent" do
      dt = DateTime.add(DateTime.utc_now(), -30, :second)
      assert Helpers.time_ago(dt) == "just now"
    end
  end
end
