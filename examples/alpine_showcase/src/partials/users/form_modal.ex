defmodule AlpineShowcase.Partials.Users.FormModal do
  use Nex

  def user_form_modal(assigns) do
    ~H"""
    <!-- Modal Backdrop -->
    <div class="modal" x-bind:class="{ 'modal-open': userModalOpen }">
      <div class="modal-box">
        <h3 class="font-bold text-lg">Add New User</h3>

        <!-- HTMX Form
             Note: Action URL "/create_user" maps directly to the create_user/1 function in the Page module
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
            <!-- x-ref: Registers reference for programmatic access via $refs.nameInput -->
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
            <!-- Cancel Button: Pure Alpine Logic -->
            <button type="button" class="btn" x-on:click="userModalOpen = false">Cancel</button>
          </div>
        </form>
      </div>
      <!-- Click backdrop to close -->
      <form method="dialog" class="modal-backdrop">
        <button x-on:click="userModalOpen = false">close</button>
      </form>
    </div>
    """
  end
end
