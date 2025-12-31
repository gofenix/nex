defmodule AlpineShowcase.Partials.Users.FormModal do
  use Nex.Partial

  def user_form_modal(assigns) do
    ~H"""
    <!-- 模态框背景遮罩 -->
    <div class="modal" x-bind:class="{ 'modal-open': userModalOpen }">
      <div class="modal-box">
        <h3 class="font-bold text-lg">Add New User</h3>
        
        <!-- HTMX 表单 
             注意：Action URL "/create_user" 直接映射到 Page 模块中的 create_user/1 函数
        -->
        <form 
          id="create-user-form"
          hx-post="/create_user" 
          hx-target="#user-list" 
          hx-swap="beforeend"
          x-on:htmx:after-request="if($event.detail.successful) { userModalOpen = false; $el.reset(); }"
        >
          <div class="form-control w-full my-4">
            <label class="label"><span class="label-text">Name</span></label>
            <!-- x-ref: 注册引用，供外部通过 $refs.nameInput 访问 -->
            <input 
              x-ref="nameInput"
              type="text" name="name" required class="input input-bordered w-full" 
            />
          </div>

          <div class="form-control w-full my-4">
            <label class="label"><span class="label-text">Email</span></label>
            <input type="email" name="email" required class="input input-bordered w-full" />
          </div>

          <div class="modal-action">
            <button type="submit" class="btn btn-primary">Save</button>
            <!-- 取消按钮：纯 Alpine 关闭 -->
            <button type="button" class="btn" x-on:click="userModalOpen = false">Cancel</button>
          </div>
        </form>
      </div>
      <!-- 点击背景关闭 -->
      <form method="dialog" class="modal-backdrop">
        <button x-on:click="userModalOpen = false">close</button>
      </form>
    </div>
    """
  end
end
