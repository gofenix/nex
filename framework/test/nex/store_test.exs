defmodule Nex.StoreTest do
  use ExUnit.Case, async: false
  use ExUnit.Case, async: false
  use ExUnit.Case, async: true

  setup do
    # Ensure the Store GenServer is started (handle if already started)
    case Nex.Store.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    # Set up a test page ID
    page_id = "test_page_#{:rand.uniform(10000)}"
    Nex.Store.set_page_id(page_id)
    %{page_id: page_id}
  end

  describe "generate_page_id/0" do
    test "generates unique page IDs" do
      id1 = Nex.Store.generate_page_id()
      id2 = Nex.Store.generate_page_id()

      assert is_binary(id1)
      assert is_binary(id2)
      assert id1 != id2
      # Base64 encoded, should be around 16 chars
      assert byte_size(id1) > 10
    end
  end

  describe "set_page_id/1" do
    test "stores page ID in process dictionary" do
      Nex.Store.set_page_id("custom_page_id")
      assert Nex.Store.get_page_id() == "custom_page_id"
    end
  end

  describe "get_page_id/0" do
    test "returns default when no page ID set" do
      Process.delete(:nex_page_id)
      assert Nex.Store.get_page_id() == "unknown"
    end

    test "returns stored page ID" do
      assert Nex.Store.get_page_id() != "unknown"
    end
  end

  describe "clear_process_dictionary/0" do
    test "clears page ID from process dictionary" do
      assert Nex.Store.get_page_id() != "unknown"

      Nex.Store.clear_process_dictionary()

      assert Nex.Store.get_page_id() == "unknown"
    end
  end

  describe "get/2" do
    test "returns default when key does not exist" do
      assert Nex.Store.get(:nonexistent, "default") == "default"
      assert Nex.Store.get(:nonexistent) == nil
    end

    test "returns stored value" do
      Nex.Store.put(:name, "test")
      assert Nex.Store.get(:name) == "test"
    end

    test "values are isolated by page_id" do
      page1 = "page_1"
      page2 = "page_2"

      Nex.Store.set_page_id(page1)
      Nex.Store.put(:value, "from_page1")

      Nex.Store.set_page_id(page2)
      Nex.Store.put(:value, "from_page2")

      Nex.Store.set_page_id(page1)
      assert Nex.Store.get(:value) == "from_page1"

      Nex.Store.set_page_id(page2)
      assert Nex.Store.get(:value) == "from_page2"
    end
  end

  describe "put/2" do
    test "stores value in page store" do
      result = Nex.Store.put(:counter, 42)
      assert result == 42
      assert Nex.Store.get(:counter) == 42
    end

    test "overwrites existing value" do
      Nex.Store.put(:key, "first")
      Nex.Store.put(:key, "second")
      assert Nex.Store.get(:key) == "second"
    end
  end

  describe "update/3" do
    test "updates value using function" do
      Nex.Store.put(:count, 5)

      result = Nex.Store.update(:count, 0, &(&1 + 1))

      assert result == 6
      assert Nex.Store.get(:count) == 6
    end

    test "uses default when key does not exist" do
      result = Nex.Store.update(:new_key, 100, &(&1 * 2))

      assert result == 200
      assert Nex.Store.get(:new_key) == 200
    end

    test "works with complex data structures" do
      Nex.Store.put(:items, [1, 2])

      result = Nex.Store.update(:items, [], &[3 | &1])

      assert result == [3, 1, 2]
    end
  end

  describe "delete/1" do
    test "deletes key from page store" do
      Nex.Store.put(:temp, "value")
      assert Nex.Store.get(:temp) == "value"

      :ok = Nex.Store.delete(:temp)

      assert Nex.Store.get(:temp) == nil
    end

    test "handles deleting non-existent key gracefully" do
      assert :ok = Nex.Store.delete(:nonexistent)
    end
  end

  describe "clear_page/1" do
    test "clears all state for a specific page" do
      page_id = "page_to_clear"
      Nex.Store.set_page_id(page_id)

      Nex.Store.put(:key1, "value1")
      Nex.Store.put(:key2, "value2")

      Nex.Store.clear_page(page_id)

      # Switch back to this page and verify it's cleared
      Nex.Store.set_page_id(page_id)
      assert Nex.Store.get(:key1) == nil
      assert Nex.Store.get(:key2) == nil
    end
  end
end
