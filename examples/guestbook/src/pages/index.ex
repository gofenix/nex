defmodule Guestbook.Pages.Index do
  use Nex
  import Guestbook.Partials.Guestbook.Message

  def mount(_params) do
    %{
      title: "Guestbook",
      messages: Nex.Store.get(:messages, [])
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h1 class="text-4xl font-bold text-center text-purple-800">Guestbook</h1>

      <div class="bg-white rounded-xl p-6 shadow-lg">
        <h2 class="text-xl font-semibold mb-4 text-gray-700">Write Message</h2>
        <form hx-post="/create_message"
              hx-target="#message-list"
              hx-swap="afterbegin"
              hx-on::after-request="this.reset()"
              class="space-y-4">
          <div class="form-control">
            <label class="label">
              <span class="label-text font-medium">Your Name</span>
            </label>
            <input type="text"
                   name="name"
                   placeholder="Enter your name"
                   required
                   class="input input-bordered w-full focus:input-primary" />
          </div>
          <div class="form-control">
            <label class="label">
              <span class="label-text font-medium">Message Content</span>
            </label>
            <textarea name="content"
                      placeholder="Write what you want to say..."
                      required
                      rows="3"
                      class="textarea textarea-bordered w-full focus:textarea-primary"></textarea>
          </div>
          <button type="submit" class="btn btn-primary w-full">
            Submit Message
          </button>
        </form>
      </div>

      <div id="message-list" class="space-y-4">
        <h2 class="text-xl font-semibold text-gray-700">
          All Messages <span class="text-sm font-normal text-gray-400">({length(@messages)})</span>
        </h2>
        <div :if={length(@messages) == 0} class="text-center py-10 text-gray-400">
          No messages yet. Be the first to leave a message!
        </div>
        <.guestbook_message :for={message <- @messages} message={message} />
      </div>
    </div>
    """
  end

  def create_message(%{"name" => name, "content" => content}) do
    message = %{
      id: System.unique_integer([:positive]),
      name: name,
      content: content,
      inserted_at: format_time()
    }

    Nex.Store.update(:messages, [], &[message | &1])

    assigns = %{message: message}
    ~H"<.guestbook_message message={@message} />"
  end

  def delete_message(%{"id" => id}) do
    id = String.to_integer(id)

    Nex.Store.update(:messages, [], fn messages ->
      Enum.reject(messages, &(&1.id == id))
    end)

    :empty
  end

  defp format_time do
    {{year, month, day}, {hour, minute, _}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
