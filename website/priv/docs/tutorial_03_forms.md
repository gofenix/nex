# Form Handling

Nex makes form handling exceptionally simple. Thanks to the declarative interaction design, you can easily implement asynchronous form submissions without manually writing complex AJAX logic. Additionally, Nex includes native support for file uploads.

## 1. Basic Form Submission

In Nex, you just need to add the `hx-post` attribute to your `<form>` tag.

### Example: Guestbook

Create `src/pages/guestbook.ex`:

```elixir
defmodule MyApp.Pages.Guestbook do
  use Nex

  def mount(_params) do
    %{messages: Nex.Store.get(:messages, [])}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto p-6">
      <h1 class="text-2xl font-bold mb-4">Guestbook</h1>
      
      <!-- Asynchronous submission to save_message Action -->
      <form hx-post="/save_message" hx-target="#message-list" hx-swap="afterbegin" class="mb-8">
        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700">Name</label>
          <input type="text" name="name" required class="mt-1 block w-full border rounded-md p-2">
        </div>
        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-700">Content</label>
          <textarea name="content" required class="mt-1 block w-full border rounded-md p-2"></textarea>
        </div>
        <button type="submit" class="w-full bg-black text-white py-2 rounded-md">Submit</button>
      </form>

      <div id="message-list" class="space-y-4">
        <.message_item :for={msg <- @messages} name={msg.name} content={msg.content} />
      </div>
    </div>
    """
  end

  # Action receives form parameters as a Map
  def save_message(%{"name" => name, "content" => content}) do
    new_msg = %{name: name, content: content}
    
    # Save to state
    Nex.Store.update(:messages, [], &[new_msg | &1])
    
    # Return HTML fragment to insert into list
    assigns = %{name: name, content: content}
    ~H"<.message_item name={@name} content={@content} />"
  end

  # Define a local component
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

## 2. Getting Parameters

Action functions receive a Map where keys correspond to the `name` attribute of form controls.
*   If a form contains multiple inputs with the same name, Nex wraps them in a list.
*   For empty inputs, the key usually still exists, but the value may be an empty string.

## 3. File Upload (Multipart)

Nex natively supports `multipart/form-data`. When you include `<input type="file">` in a form, Nex automatically handles the upload.

### Example: Avatar Upload

```elixir
def upload_avatar(%{"avatar" => %Plug.Upload{path: path, filename: name}}) do
  # Nex automatically wraps the uploaded file in a Plug.Upload struct
  # path: Temporary file path
  # filename: Original filename
  
  # You can move the file to persistent storage
  File.cp!(path, "priv/static/uploads/#{name}")
  
  "Upload successful: #{name}"
end
```

## Exercise: Todo List

Try combining the knowledge from the first two chapters to write a Todo List:
1.  Form to input Todo content.
2.  Action `add_todo` to handle submission and return a new Todo item HTML fragment.
3.  Each Todo item has a "Delete" button using `hx-delete` to call `delete_todo`.
