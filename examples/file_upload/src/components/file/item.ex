defmodule FileUpload.Components.File.Item do
  use Nex

  def file_item(assigns) do
    ~H"""
    <div id={"file-#{@file.id}"} class="flex items-center justify-between bg-gray-50 p-4 rounded-lg border border-gray-200">
      <div class="flex-1">
        <div class="flex items-center gap-2">
          <span class="text-2xl">{get_file_icon(@file.original_name)}</span>
          <div>
            <h3 class="font-semibold text-gray-800 break-all">{@file.original_name}</h3>
            <p class="text-xs text-gray-500">
              {format_size(@file.size)} • {@file.uploaded_at}
            </p>
            <p :if={@file.description != ""} class="text-sm text-gray-600 mt-1">
              {@file.description}
            </p>
          </div>
        </div>
      </div>

      <button hx-post={"/delete_file"}
              hx-vals={"json:{id: #{@file.id}}"}
              hx-target={"#file-#{@file.id}"}
              hx-swap="outerHTML swap:1s"
              class="px-3 py-1 bg-red-500 text-white rounded hover:bg-red-600 text-sm font-medium ml-4">
        Delete
      </button>
    </div>
    """
  end

  defp get_file_icon(filename) do
    ext = Path.extname(filename) |> String.downcase()

    case ext do
      ".pdf" -> "📄"
      ".doc" -> "📝"
      ".docx" -> "📝"
      ".xls" -> "📊"
      ".xlsx" -> "📊"
      ".jpg" -> "🖼️"
      ".jpeg" -> "🖼️"
      ".png" -> "🖼️"
      ".gif" -> "🖼️"
      ".zip" -> "📦"
      ".rar" -> "📦"
      ".7z" -> "📦"
      ".txt" -> "📄"
      ".csv" -> "📊"
      _ -> "📎"
    end
  end

  defp format_size(bytes) do
    cond do
      bytes < 1024 -> "#{bytes} B"
      bytes < 1024 * 1024 -> "#{div(bytes, 1024)} KB"
      true -> "#{Float.round(bytes / (1024 * 1024), 2)} MB"
    end
  end
end
