defmodule ShoppingCart.Components.Cart.Item do
  use Nex

  def cart_item(assigns) do
    ~H"""
    <div id={"item-#{@item.id}"} class="flex items-center justify-between bg-gray-50 p-4 rounded-lg border border-gray-200">
      <div class="flex-1">
        <h3 class="font-semibold text-gray-800">{@item.name}</h3>
        <p class="text-sm text-gray-500">
          Category: <span class="font-medium">{@item.category}</span>
        </p>
        <p class="text-sm text-gray-600 mt-1">
          Price: <span class="font-semibold text-blue-600">${format_price(@item.price)}</span>
        </p>
      </div>

      <div class="flex items-center gap-4">
        <div class="flex items-center gap-2">
          <label class="text-sm text-gray-600">Qty:</label>
          <input type="number"
                 value={@item.quantity}
                 min="1"
                 hx-post={"/update_quantity"}
                 hx-vals={"json:{id: #{@item.id}, quantity: this.value}"}
                 hx-target={"#item-#{@item.id}"}
                 hx-swap="outerHTML"
                 class="w-16 px-2 py-1 border border-gray-300 rounded text-center focus:outline-none focus:ring-2 focus:ring-blue-500" />
        </div>

        <div class="text-right">
          <p class="text-sm text-gray-600">Subtotal:</p>
          <p class="text-lg font-bold text-blue-600">${format_price(@item.subtotal)}</p>
        </div>

        <button hx-delete={"/remove_item"}
                hx-vals={"json:{id: #{@item.id}}"}
                hx-target={"#item-#{@item.id}"}
                hx-swap="outerHTML swap:1s"
                class="px-3 py-1 bg-red-500 text-white rounded hover:bg-red-600 text-sm font-medium">
          Remove
        </button>
      </div>
    </div>
    """
  end

  defp format_price(price) do
    :erlang.float_to_binary(price, [decimals: 2])
  end
end
