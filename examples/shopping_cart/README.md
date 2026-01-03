# Shopping Cart Example

完整的购物车应用，展示 Nex.Store 的核心功能。

## 功能特性

- ✅ **添加商品** - 支持名称、价格、数量、分类
- ✅ **修改数量** - 实时更新小计
- ✅ **删除商品** - 单个删除或清空购物车
- ✅ **状态管理** - 使用 `Nex.Store` 管理购物车数据
- ✅ **Page-scoped State** - 刷新页面时状态清空（设计意图）
- ✅ **HTMX 交互** - 无刷新添加、修改、删除

## 学习要点

### 1. Nex.Store 基础操作

```elixir
# 读取状态
items = Nex.Store.get(:cart_items, [])

# 更新状态（追加）
Nex.Store.update(:cart_items, [], &[new_item | &1])

# 更新状态（修改）
Nex.Store.update(:cart_items, [], fn items ->
  Enum.map(items, fn item ->
    if item.id == id do
      %{item | quantity: new_qty}
    else
      item
    end
  end)
end)

# 清空状态
Nex.Store.put(:cart_items, [])
```

### 2. Page-scoped State 设计

购物车数据绑定到 `page_id`。刷新页面时：
- 新的 `page_id` 生成
- 旧的购物车数据清空
- **这是设计意图，不是 bug**

```elixir
# 每次页面加载都会获得新的 page_id
def mount(_params) do
  %{
    items: Nex.Store.get(:cart_items, [])  # 新页面 = 新 page_id = 空购物车
  }
end
```

### 3. Action 返回值类型

```elixir
# 返回 HTML 片段（HTMX 替换 DOM）
def add_item(params) do
  # ... 添加逻辑
  ~H"<.cart_item item={@item} />"
end

# 返回空响应（不更新 DOM）
def remove_item(params) do
  # ... 删除逻辑
  :empty
end

# 返回刷新信号（整个页面刷新）
def clear_cart(_params) do
  Nex.Store.put(:cart_items, [])
  {:refresh}
end
```

### 4. HTMX 单路径 Action

所有 Action 都使用单路径模式，通过 Referer 自动路由：

```html
<!-- POST /add_item + Referer: / → ShoppingCart.Pages.Index.add_item -->
<form hx-post="/add_item" hx-target="#cart-items" hx-swap="beforeend">
  ...
</form>

<!-- POST /update_quantity + Referer: / → ShoppingCart.Pages.Index.update_quantity -->
<input hx-post="/update_quantity" hx-vals="json:{id: ..., quantity: ...}" />

<!-- DELETE /remove_item + Referer: / → ShoppingCart.Pages.Index.remove_item -->
<button hx-delete="/remove_item" hx-vals="json:{id: ...}">Remove</button>
```

## 运行

```bash
cd examples/shopping_cart
mix deps.get
mix phx.server
```

访问 http://localhost:4000

## 关键概念

| 概念 | 说明 |
|-----|-----|
| **Page-scoped State** | 状态绑定到 page_id，刷新页面 = 状态清空 |
| **TTL 机制** | 默认 1 小时过期，自动清理 |
| **单路径 Action** | POST /action_name 通过 Referer 自动路由 |
| **HTMX 集成** | 无需手动添加 CSRF token，框架自动处理 |

## 扩展思考

1. **持久化存储**：如何将购物车保存到数据库？
2. **多用户场景**：如何在多个浏览器标签页间同步购物车？
3. **性能优化**：购物车数据很多时，如何避免全量扫描？

---

**这个示例展示了 Nex.Store 的完整使用，是教程 04 的最佳实践。**
