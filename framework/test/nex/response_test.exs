defmodule Nex.ResponseTest do
  use ExUnit.Case, async: true
  alias Nex.Response

  describe "struct" do
    test "has default values" do
      response = %Response{}

      assert response.status == 200
      assert response.body == nil
      assert response.headers == %{}
      assert response.content_type == "application/json"
    end

    test "allows setting all fields" do
      response = %Response{
        status: 201,
        body: %{message: "created"},
        headers: %{"x-custom" => "value"},
        content_type: "application/json"
      }

      assert response.status == 201
      assert response.body == %{message: "created"}
      assert response.headers == %{"x-custom" => "value"}
      assert response.content_type == "application/json"
    end
  end
end
