defmodule Guestbook.Partials.Guestbook.Message do
  use Nex.Partial

  @doc """
  Render a single guestbook message.

  ## Usage

      alias Guestbook.Partials.Guestbook.Message

      <Message.guestbook_message message={message} />
  """
  def guestbook_message(assigns) do
    ~H"""
    <div id={"message-#{@message.id}"}
         class="bg-white rounded-xl p-5 shadow-md hover:shadow-lg transition-shadow">
      <div class="flex justify-between items-start mb-2">
        <div>
          <span class="font-bold text-lg text-purple-700">{@message.name}</span>
          <span class="text-sm text-gray-400 ml-2">{@message.inserted_at}</span>
        </div>
        <button hx-delete="/delete_message"
                hx-vals={Jason.encode!(%{id: @message.id})}
                hx-target={"#message-#{@message.id}"}
                hx-swap="outerHTML"
                hx-confirm="确定要删除这条留言吗？"
                class="btn btn-ghost btn-xs text-red-400 hover:text-red-600">
          删除
        </button>
      </div>
      <p class="text-gray-700 whitespace-pre-wrap">{@message.content}</p>
    </div>
    """
  end
end
