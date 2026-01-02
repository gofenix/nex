defmodule DynamicRoutes.Api.Users.Id do
  use Nex

  def get(req) do
    id = req.query["id"]
    user = find_user(id)

    if user do
      Nex.json(%{
        status: :ok,
        data: user
      })
    else
      Nex.json(%{
        status: :error,
        message: "User not found"
      })
    end
  end

  def post(req) do
    id = req.query["id"]
    action = req.body["action"]

    case action do
      "follow" ->
        # Simulate follow operation
        Nex.json(%{"message" => "Successfully followed user #{id}"})

      "unfollow" ->
        # Simulate unfollow
        Nex.json(%{"message" => "Successfully unfollowed user #{id}"})

      _ ->
        Nex.json(%{"message" => "Invalid action"}, status: 400)
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
