defmodule ShoppingCart.Pages.Index do
  use Nex
  import ShoppingCart.Components.Cart.Item

  def mount(_params) do
    %{
      title: "Shopping Cart",
      items: Nex.Store.get(:cart_items, []),
      total_price: calculate_total(Nex.Store.get(:cart_items, []))
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6">
      <h1 class="text-4xl font-bold mb-8 text-gray-800">Shopping Cart</h1>

      <!-- Add Product Section -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 class="text-xl font-semibold mb-4 text-gray-700">Add Product</h2>
        <form hx-post="/add_item"
              hx-target="#cart-items"
              hx-swap="beforeend"
              hx-on::after-request="this.reset()"
              class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-600 mb-2">Product Name</label>
              <input type="text"
                     name="name"
                     placeholder="e.g., Laptop"
                     required
                     class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-600 mb-2">Price ($)</label>
              <input type="number"
                     name="price"
                     placeholder="99.99"
                     step="0.01"
                     required
                     class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-600 mb-2">Quantity</label>
              <input type="number"
                     name="quantity"
                     value="1"
                     min="1"
                     required
                     class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-600 mb-2">Category</label>
              <select name="category"
                      class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="electronics">Electronics</option>
                <option value="clothing">Clothing</option>
                <option value="books">Books</option>
                <option value="other">Other</option>
              </select>
            </div>
          </div>
          <button type="submit"
                  class="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 font-semibold">
            Add to Cart
          </button>
        </form>
      </div>

      <!-- Cart Items -->
      <div class="bg-white rounded-lg shadow-md p-6">
        <h2 class="text-xl font-semibold mb-4 text-gray-700">
          Cart Items
          <span class="text-sm font-normal text-gray-400">({length(@items)} items)</span>
        </h2>

        <div :if={length(@items) == 0} class="text-center py-8 text-gray-400">
          Your cart is empty. Add some products!
        </div>

        <div id="cart-items" class="space-y-3">
          <.cart_item :for={item <- @items} item={item} />
        </div>

        <div :if={length(@items) > 0} class="mt-6 pt-6 border-t border-gray-200">
          <div class="flex justify-between items-center mb-4">
            <span class="text-lg font-semibold text-gray-700">Total:</span>
            <span class="text-2xl font-bold text-blue-600">${format_price(@total_price)}</span>
          </div>
          <button hx-post="/clear_cart"
                  hx-confirm="Are you sure you want to clear the cart?"
                  class="w-full bg-red-600 text-white py-2 rounded-lg hover:bg-red-700 font-semibold">
            Clear Cart
          </button>
        </div>
      </div>
    </div>
    """
  end

  def add_item(%{"name" => name, "price" => price_str, "quantity" => qty_str, "category" => category}) do
    price = parse_float(price_str)
    quantity = String.to_integer(qty_str)

    item = %{
      id: System.unique_integer([:positive]),
      name: name,
      price: price,
      quantity: quantity,
      category: category,
      subtotal: price * quantity
    }

    Nex.Store.update(:cart_items, [], &[item | &1])

    assigns = %{item: item}
    ~H"<.cart_item item={@item} />"
  end

  def update_quantity(%{"id" => id, "quantity" => qty_str}) do
    id = String.to_integer(id)
    quantity = String.to_integer(qty_str)

    Nex.Store.update(:cart_items, [], fn items ->
      Enum.map(items, fn item ->
        if item.id == id do
          %{item | quantity: quantity, subtotal: item.price * quantity}
        else
          item
        end
      end)
    end)

    item = Nex.Store.get(:cart_items, []) |> Enum.find(&(&1.id == id))

    assigns = %{item: item}
    ~H"<.cart_item item={@item} />"
  end

  def remove_item(%{"id" => id}) do
    id = String.to_integer(id)

    Nex.Store.update(:cart_items, [], fn items ->
      Enum.reject(items, &(&1.id == id))
    end)

    :empty
  end

  def clear_cart(_params) do
    Nex.Store.put(:cart_items, [])
    {:refresh}
  end

  defp calculate_total(items) do
    Enum.reduce(items, 0, &(&1.subtotal + &2))
  end

  defp format_price(price) do
    :erlang.float_to_binary(price, [decimals: 2])
  end

  defp parse_float(str) do
    case Float.parse(str) do
      {float, _} -> float
      :error -> 0.0
    end
  end
end
