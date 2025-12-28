defmodule DynamicRoutes.Api.Users.Id do
  use Nex.Api

  def get(%{"id" => id}) do
    user = find_user(id)

    if user do
      %{
        status: :ok,
        data: user
      }
    else
      %{
        status: :error,
        message: "User not found"
      }
    end
  end

  def post(%{"id" => id, "action" => action}) do
    case action do
      "follow" ->
        # Simulate follow operation
        {:ok, %{"message" => "Successfully followed user #{id}"}}

      "unfollow" ->
        # Simulate unfollow
        {:ok, %{"message" => "Successfully unfollowed user #{id}"}}

      _ ->
        {:error, %{"message" => "Invalid action"}}
    end
  end

  # Mock user data
  defp find_user(id) do
    users = %{
      "1" => %{
        id: "1",
        name: "Zhang San",
        email: "zhangsan@example.com",
        age: 28,
        city: "Beijing",
        bio: "Elixir developer who loves programming",
        followers: 156,
        following: 89
      },
      "2" => %{
        id: "2",
        name: "Li Si",
        email: "lisi@example.com",
        age: 32,
        city: "Shanghai",
        bio: "Full-stack engineer focused on web development",
        followers: 234,
        following: 123
      },
      "3" => %{
        id: "3",
        name: "Wang Wu",
        email: "wangwu@example.com",
        age: 25,
        city: "Shenzhen",
        bio: "Frontend developer, HTMX enthusiast",
        followers: 89,
        following: 67
      }
    }

    Map.get(users, id)
  end
end
