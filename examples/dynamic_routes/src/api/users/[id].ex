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
        # 模拟关注操作
        {:ok, %{"message" => "Successfully followed user #{id}"}}

      "unfollow" ->
        # 模拟取消关注
        {:ok, %{"message" => "Successfully unfollowed user #{id}"}}

      _ ->
        {:error, %{"message" => "Invalid action"}}
    end
  end

  # 模拟用户数据
  defp find_user(id) do
    users = %{
      "1" => %{
        id: "1",
        name: "张三",
        email: "zhangsan@example.com",
        age: 28,
        city: "北京",
        bio: "热爱编程的 Elixir 开发者",
        followers: 156,
        following: 89
      },
      "2" => %{
        id: "2",
        name: "李四",
        email: "lisi@example.com",
        age: 32,
        city: "上海",
        bio: "全栈工程师，专注于 Web 开发",
        followers: 234,
        following: 123
      },
      "3" => %{
        id: "3",
        name: "王五",
        email: "wangwu@example.com",
        age: 25,
        city: "深圳",
        bio: "前端开发者，HTMX 爱好者",
        followers: 89,
        following: 67
      }
    }

    Map.get(users, id)
  end
end
