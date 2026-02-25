defmodule Nex.ValidatorTest do
  use ExUnit.Case, async: true
  alias Nex.Validator

  describe "validate/2 - required" do
    test "passes when required field is present" do
      assert Validator.validate(%{"name" => "John"}, %{"name" => [:required]}) ==
               {:ok, %{"name" => "John"}}
    end

    test "passes when required field is empty string" do
      assert Validator.validate(%{"name" => ""}, %{"name" => [:required]}) ==
               {:error, [{"name", "is required"}]}
    end

    test "fails when required field is nil" do
      assert Validator.validate(%{"name" => nil}, %{"name" => [:required]}) ==
               {:error, [{"name", "is required"}]}
    end

    test "fails when required field is missing" do
      assert Validator.validate(%{}, %{"name" => [:required]}) ==
               {:error, [{"name", "is required"}]}
    end

    test "accepts {:required, _opts} format" do
      assert Validator.validate(%{"name" => "John"}, %{"name" => [{:required, true}]}) ==
               {:ok, %{"name" => "John"}}
    end
  end

  describe "validate/2 - types" do
    test ":string passes for string" do
      assert Validator.validate(%{"name" => "John"}, %{"name" => [:string]}) ==
               {:ok, %{"name" => "John"}}
    end

    test ":string fails for non-string" do
      assert Validator.validate(%{"name" => 123}, %{"name" => [:string]}) ==
               {:error, [{"name", "must be a string"}]}
    end

    test ":string passes nil" do
      assert Validator.validate(%{"name" => nil}, %{"name" => [:string]}) ==
               {:ok, %{"name" => nil}}
    end

    test ":number passes for integer" do
      assert Validator.validate(%{"age" => 25}, %{"age" => [:number]}) ==
               {:ok, %{"age" => 25}}
    end

    test ":number passes for float" do
      assert Validator.validate(%{"price" => 19.99}, %{"price" => [:number]}) ==
               {:ok, %{"price" => 19.99}}
    end

    test ":number fails for string" do
      assert Validator.validate(%{"age" => "25"}, %{"age" => [:number]}) ==
               {:error, [{"age", "must be a number"}]}
    end

    test ":boolean passes for true" do
      assert Validator.validate(%{"active" => true}, %{"active" => [:boolean]}) ==
               {:ok, %{"active" => true}}
    end

    test ":boolean passes for false" do
      assert Validator.validate(%{"active" => false}, %{"active" => [:boolean]}) ==
               {:ok, %{"active" => false}}
    end

    test ":boolean fails for non-boolean" do
      assert Validator.validate(%{"active" => "yes"}, %{"active" => [:boolean]}) ==
               {:error, [{"active", "must be a boolean"}]}
    end
  end

  describe "validate/2 - email" do
    test "passes valid email" do
      assert Validator.validate(%{"email" => "test@example.com"}, %{"email" => [:email]}) ==
               {:ok, %{"email" => "test@example.com"}}
    end

    test "fails invalid email" do
      assert Validator.validate(%{"email" => "invalid"}, %{"email" => [:email]}) ==
               {:error, [{"email", "must be a valid email"}]}
    end

    test "fails email without @" do
      assert Validator.validate(%{"email" => "testexample.com"}, %{"email" => [:email]}) ==
               {:error, [{"email", "must be a valid email"}]}
    end
  end

  describe "validate/2 - url" do
    test "passes valid URL with http" do
      assert Validator.validate(%{"url" => "http://example.com"}, %{"url" => [:url]}) ==
               {:ok, %{"url" => "http://example.com"}}
    end

    test "passes valid URL with https" do
      assert Validator.validate(%{"url" => "https://example.com"}, %{"url" => [:url]}) ==
               {:ok, %{"url" => "https://example.com"}}
    end

    test "fails invalid URL" do
      assert Validator.validate(%{"url" => "not-a-url"}, %{"url" => [:url]}) ==
               {:error, [{"url", "must be a valid URL"}]}
    end
  end

  describe "validate/2 - min/max for numbers" do
    test "min number passes when equal" do
      assert Validator.validate(%{"age" => 18}, %{"age" => [:number, {:min, 18}]}) ==
               {:ok, %{"age" => 18}}
    end

    test "min number passes when above" do
      assert Validator.validate(%{"age" => 25}, %{"age" => [:number, {:min, 18}]}) ==
               {:ok, %{"age" => 25}}
    end

    test "min number fails when below" do
      assert Validator.validate(%{"age" => 16}, %{"age" => [:number, {:min, 18}]}) ==
               {:error, [{"age", "must be at least 18"}]}
    end

    test "max number passes when equal" do
      assert Validator.validate(%{"age" => 100}, %{"age" => [:number, {:max, 100}]}) ==
               {:ok, %{"age" => 100}}
    end

    test "max number passes when below" do
      assert Validator.validate(%{"age" => 50}, %{"age" => [:number, {:max, 100}]}) ==
               {:ok, %{"age" => 50}}
    end

    test "max number fails when above" do
      assert Validator.validate(%{"age" => 150}, %{"age" => [:number, {:max, 100}]}) ==
               {:error, [{"age", "must be at most 100"}]}
    end
  end

  describe "validate/2 - format" do
    test "format passes when matches" do
      assert Validator.validate(%{"code" => "ABC123"}, %{"code" => [format: ~r/^[A-Z]+[0-9]+$/]}) ==
               {:ok, %{"code" => "ABC123"}}
    end

    test "format fails when no match" do
      assert Validator.validate(%{"code" => "123ABC"}, %{"code" => [format: ~r/^[A-Z]+[0-9]+$/]}) ==
               {:error, [{"code", "must match format"}]}
    end

    test "format with binary pattern" do
      assert Validator.validate(%{"code" => "ABC"}, %{"code" => [format: "^[A-Z]+$"]}) ==
               {:ok, %{"code" => "ABC"}}
    end
  end

  describe "validate/2 - in" do
    test "in passes when value is in list" do
      assert Validator.validate(%{"status" => "active"}, %{
               "status" => [in: ["active", "inactive"]]
             }) ==
               {:ok, %{"status" => "active"}}
    end

    test "in fails when value is not in list" do
      assert Validator.validate(%{"status" => "pending"}, %{
               "status" => [in: ["active", "inactive"]]
             }) ==
               {:error, [{"status", "must be one of: active, inactive"}]}
    end
  end

  describe "validate/2 - custom validator" do
    test "custom validator with 2-arity function passes with :ok" do
      custom = fn value, _opts -> :ok end

      assert Validator.validate(%{"code" => "test"}, %{"code" => [{custom, [arg: "value"]}]}) ==
               {:ok, %{"code" => "test"}}
    end

    test "custom validator with 2-arity function passes with {:ok, _}" do
      custom = fn value, _opts -> {:ok, "processed"} end

      assert Validator.validate(%{"code" => "test"}, %{"code" => [{custom, []}]}) ==
               {:ok, %{"code" => "test"}}
    end

    test "custom validator with 2-arity function fails with {:error, msg}" do
      custom = fn _value, _opts -> {:error, "custom error"} end

      assert Validator.validate(%{"code" => "test"}, %{"code" => [{custom, []}]}) ==
               {:error, [{"code", "custom error"}]}
    end

    test "custom validator with 2-arity function fails with string" do
      custom = fn _value, _opts -> "string error" end

      assert Validator.validate(%{"code" => "test"}, %{"code" => [{custom, []}]}) ==
               {:error, [{"code", "string error"}]}
    end
  end

  describe "validate/2 - multiple validations" do
    test "validates all rules" do
      assert Validator.validate(
               %{"email" => "test@example.com", "age" => 25},
               %{"email" => [:required, :email], "age" => [:required, :number]}
             ) == {:ok, %{"email" => "test@example.com", "age" => 25}}
    end
  end

  describe "validate!/2" do
    test "returns params when valid" do
      assert Validator.validate!(%{"name" => "John"}, %{"name" => [:required]}) ==
               %{"name" => "John"}
    end

    test "raises when invalid" do
      assert_raise ArgumentError, fn ->
        Validator.validate!(%{}, %{"name" => [:required]})
      end
    end
  end
end
