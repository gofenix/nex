defmodule NexBaseDemo.Api.Db.Verify do
  use Nex

  @client NexBase.client(repo: NexBaseDemo.Repo)

  def get(_req) do
    try do
      {:ok, result} = @client |> NexBase.query("SELECT version()", [])
      [[version]] = result.rows
      Nex.html("<span class='text-success'>✓ 连接成功</span><br/><code class='text-xs'>#{version}</code>")
    rescue
      e ->
        Nex.html("<span class='text-error'>✗ 失败: #{inspect(e)}</span>")
    end
  end
end
