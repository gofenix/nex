defmodule Nex.Supervisor do
  @moduledoc """
  框架层监督树，负责管理 Nex 框架的核心进程。

  监督的进程：
  - `Phoenix.PubSub` - 用于 WebSocket 热重载广播
  - `Nex.Store` - 页面级状态存储
  - `Nex.Reloader` - 热重载文件监视器

  这些进程对用户完全透明，由框架自动管理。
  如果任何进程崩溃，会自动重启，不影响用户应用。
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # PubSub 用于热重载 WebSocket 通信
      {Phoenix.PubSub, name: Nex.PubSub},
      # 页面级状态存储
      Nex.Store,
      # 热重载器（开发环境）
      Nex.Reloader
    ]

    # one_for_one: 一个进程崩溃只重启该进程，不影响其他
    Supervisor.init(children, strategy: :one_for_one)
  end
end
