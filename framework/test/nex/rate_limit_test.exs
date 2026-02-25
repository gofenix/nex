defmodule Nex.RateLimitTest do
  # Rate limit uses ETS, needs to be async: false
  use ExUnit.Case, async: false
  alias Nex.RateLimit

  setup do
    # Clean up before each test
    RateLimit.ensure_table()
    :ets.delete_all_objects(:nex_rate_limit)
    :ok
  end

  describe "check/2" do
    test "allows requests within limit" do
      assert RateLimit.check("test-key", max: 10, window: 60) == :ok
    end

    test "increments count on subsequent calls" do
      RateLimit.check("test-key", max: 10, window: 60)
      RateLimit.check("test-key", max: 10, window: 60)
      assert RateLimit.count("test-key", max: 10, window: 60) == 2
    end

    test "blocks when limit exceeded" do
      # First 5 should pass
      for _ <- 1..5 do
        assert RateLimit.check("test-key", max: 5, window: 60) == :ok
      end

      # 6th should be blocked
      assert RateLimit.check("test-key", max: 5, window: 60) == {:error, :rate_limited}
    end

    test "different keys have separate limits" do
      for _ <- 1..5 do
        assert RateLimit.check("key-1", max: 5, window: 60) == :ok
      end

      # key-1 should be blocked
      assert RateLimit.check("key-1", max: 5, window: 60) == {:error, :rate_limited}

      # key-2 should still be allowed
      assert RateLimit.check("key-2", max: 5, window: 60) == :ok
    end

    test "uses default options from application env" do
      # Just verify it doesn't crash with defaults
      assert RateLimit.check("test-key") == :ok
    end
  end

  describe "count/2" do
    test "returns 0 for unknown key" do
      assert RateLimit.count("unknown-key", max: 10, window: 60) == 0
    end

    test "returns current count" do
      RateLimit.check("test-key", max: 10, window: 60)
      RateLimit.check("test-key", max: 10, window: 60)
      RateLimit.check("test-key", max: 10, window: 60)

      assert RateLimit.count("test-key", max: 10, window: 60) == 3
    end
  end

  describe "reset/2" do
    test "clears the counter for a key" do
      for _ <- 1..5 do
        RateLimit.check("test-key", max: 5, window: 60)
      end

      RateLimit.reset("test-key", max: 10, window: 60)

      assert RateLimit.count("test-key", max: 10, window: 60) == 0
      assert RateLimit.check("test-key", max: 10, window: 60) == :ok
    end
  end

  describe "ensure_table/0" do
    test "creates table if not exists" do
      # Table should exist from setup
      assert :ets.whereis(:nex_rate_limit) != :undefined
    end
  end
end
