# 表单处理

Nex 使得表单处理变得异常简单。得益于 HTMX 的集成，你可以轻松实现异步表单提交，并且 Nex 内置了对文件上传的原生支持。

## 1. 基础表单提交

在 Nex 中，你只需要给 `<form>` 标签添加 `hx-post` 属性。

### 示例：留言板

创建 `src/pages/guestbook.ex`：

```elixir
defmodule MyApp.Pages.Guestbook do
  use Nex

  def mount(_params) do
    %{messages: Nex.Store.get(:messages, [])}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto p-6">
      <h1 class="text-2xl font-bold mb-4">留言板</h1>
      
      <!-- 异步提交到 save_message Action -->
      <form hx-post="/save_message" hx-target="#message-list" hx-swap="afterbegin" class="mb-8">
        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700">姓名</label>
          <input type="text" name="name" required class="mt-1 block w-full border rounded-md p-2">
        </div>
        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700">内容</label>
          <textarea name="content" required class="mt-1 block w-full border rounded-md p-2"></textarea>
        </div>
        <button type="submit" class="w-full bg-black text-white py-2 rounded-md">提交留言</button>
      </form>

      <div id="message-list" class="space-y-4">
        <%= for msg <- @messages do %>
          <.message_item name={msg.name} content={msg.content} />
        <% end %>
      </div>
    </div>
    """
  end

  # Action 接收表单参数 Map
  def save_message(%{"name" => name, "content" => content}) do
    new_msg = %{name: name, content: content}
    
    # 保存到状态
    Nex.Store.update(:messages, [], &[new_msg | &1])
    
    # 返回一个 HTML 片段用于插入列表
    assigns = %{name: name, content: content}
    ~H"<.message_item name={@name} content={@content} />"
  end

  # 定义一个局部组件
  defp message_item(assigns) do
    ~H"""
    <div class="p-4 bg-gray-50 rounded-lg border">
      <div class="font-bold text-sm">{@name}</div>
      <div class="text-gray-600 mt-1">{@content}</div>
    </div>
    """
  end
end
```

## 2. 获取参数

Action 函数接收一个 Map，其中的键对应表单控件的 `name` 属性。
*   如果表单包含多个同名的 input，Nex 会将其封装为列表。
*   对于空输入，键通常依然存在，但值可能为空字符串。

## 3. 文件上传 (Multipart)

Nex 原生支持 `multipart/form-data`。当你在表单中包含 `<input type="file">` 时，Nex 会自动处理上传。

### 示例：头像上传

```elixir
def upload_avatar(%{"avatar" => %Plug.Upload{path: path, filename: name}}) do
  # Nex 自动将上传文件封装为 Plug.Upload 结构
  # path: 临时文件路径
  # filename: 原始文件名
  
  # 你可以将文件移动到持久存储
  File.cp!(path, "priv/static/uploads/#{name}")
  
  "上传成功：#{name}"
end
```

## 练习：Todo List

尝试结合前两章的知识，写一个 Todo List：
1.  表单输入 Todo 内容。
2.  Action `add_todo` 处理提交，并返回一个新的 Todo 条目 HTML。
3.  每个 Todo 条目带有一个“删除”按钮，使用 `hx-delete` 调用 `delete_todo`。
