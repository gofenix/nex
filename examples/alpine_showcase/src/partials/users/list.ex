defmodule AlpineShowcase.Partials.Users.List do
  use Nex.Partial

  # 渲染整个列表容器
  def user_list(assigns) do
    ~H"""
    <div class="overflow-x-auto bg-base-100 rounded-box shadow-md">
      <table class="table table-zebra">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Email</th>
          </tr>
        </thead>
        <!-- 
           ID 必须匹配 form_modal 中的 hx-target="#user-list"
           hx-swap="beforeend" 会把新行插入到这个 tbody 内部的最末尾
        -->
        <tbody id="user-list">
          <.user_row :for={user <- @users} user={user} />
        </tbody>
      </table>
    </div>
    """
  end

  # 渲染单行 (Action create_user 也会调用此函数返回新行)
  def render_user_row(assigns) do
    # 如果 assigns 中没有 :user 只有 :id, :name 等，需要适配一下
    # 但通常 controller 会构造好 user map
    ~H"""
    <.user_row user={@user} />
    """
  end

  # 私有组件：行结构
  def user_row(assigns) do
    ~H"""
    <tr class="hover">
      <td>{@user.id}</td>
      <td>{@user.name}</td>
      <td>{@user.email}</td>
    </tr>
    """
  end
end
