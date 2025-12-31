defmodule AlpineShowcase.Pages.Index do
  use Nex.Page
  import AlpineShowcase.Partials.Users.List
  import AlpineShowcase.Partials.Users.FormModal
  import AlpineShowcase.Partials.Profile.Settings

  def mount(_params) do
    # 初始化服务器端数据
    # 在真实应用中，这会来自数据库
    users = Nex.Store.get(:users, [
      %{id: 1, name: "Alice", email: "alice@example.com"},
      %{id: 2, name: "Bob", email: "bob@example.com"}
    ])
    %{title: "Alpine Integration Demo", users: users}
  end

  # 定义 Alpine 的数据结构
  # tab: 当前激活的选项卡
  # userModalOpen: 控制用户创建模态框
  def render(assigns) do
    ~H"""
    <div x-data="{ currentTab: 'users', userModalOpen: false }" class="container mx-auto max-w-4xl">
      
      <div class="text-center mb-8">
        <h1 class="text-4xl font-bold mb-2">Nex + Alpine.js Showcase</h1>
        <p class="text-base-content/70">A comprehensive example of "The STACK"</p>
      </div>

      <!-- Tabs 导航 (纯客户端切换) -->
      <div role="tablist" class="tabs tabs-boxed mb-8 bg-base-100 p-2 shadow-sm">
        <a role="tab" class="tab tab-lg" 
           x-bind:class="{ 'tab-active': currentTab === 'users' }" 
           x-on:click="currentTab = 'users'">User Management</a>
        <a role="tab" class="tab tab-lg" 
           x-bind:class="{ 'tab-active': currentTab === 'profile' }" 
           x-on:click="currentTab = 'profile'">Profile Settings</a>
      </div>

      <!-- Tab 内容区 1: Users -->
      <div x-show="currentTab === 'users'" x-transition:enter.duration.300ms>
        <div class="flex justify-between items-center mb-6">
          <h2 class="text-2xl font-bold">User Directory</h2>
          <!-- 点击按钮打开模态框，并自动聚焦输入框 ($nextTick 确保 DOM 更新后执行) -->
          <button 
            class="btn btn-primary" 
            x-on:click="userModalOpen = true; $nextTick(() => $refs.nameInput.focus())"
          >Add User</button>
        </div>
        
        <!-- 用户列表组件 -->
        <.user_list users={@users} />
        
        <!-- 用户表单模态框组件 (传入 users 列表用于更新) -->
        <.user_form_modal />
      </div>

      <!-- Tab 内容区 2: Profile -->
      <div x-show="currentTab === 'profile'" style="display: none;" x-transition:enter.duration.300ms>
        <.profile_settings />
      </div>

    </div>
    """
  end

  # 处理添加用户: 对应 POST /create_user
  def create_user(params) do
    new_user = %{
      id: System.unique_integer([:positive]),
      name: params["name"],
      email: params["email"]
    }
    
    # 1. 更新数据库/Store
    users = Nex.Store.get(:users, [
      %{id: 1, name: "Alice", email: "alice@example.com"},
      %{id: 2, name: "Bob", email: "bob@example.com"}
    ]) ++ [new_user]
    Nex.Store.put(:users, users)
    
    # 2. 返回 HTML 片段用于追加到列表
    # 注意：这里调用的是 Partial 模块的渲染函数
    render_user_row(%{user: new_user})
  end

  # 处理更新配置: 对应 PUT /update_settings
  def update_settings(_params) do
    # 模拟保存耗时
    Process.sleep(500) 
    
    # 返回空内容 (前端不进行 DOM 替换，仅监听事件)
    :empty
  end
end
