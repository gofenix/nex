defmodule FileUpload.Pages.Index do
  use Nex
  import FileUpload.Components.File.Item

  def mount(_params) do
    %{
      title: "File Upload Demo",
      files: Nex.Store.get(:uploaded_files, [])
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6">
      <h1 class="text-4xl font-bold mb-2 text-gray-800">File Upload Demo</h1>
      <p class="text-gray-600 mb-8">Upload files and see them listed below. Nex supports multipart/form-data out of the box!</p>

      <!-- Upload Form -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 class="text-xl font-semibold mb-4 text-gray-700">Upload File</h2>
        <form hx-post="/upload"
              hx-target="#file-list"
              hx-swap="beforeend"
              hx-on::after-request="this.reset()"
              enctype="multipart/form-data"
              class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-600 mb-2">Select File</label>
            <input type="file"
                   name="file"
                   required
                   class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
            <p class="text-xs text-gray-500 mt-1">Max file size: 10MB. Supported: images, documents, archives</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-600 mb-2">Description (optional)</label>
            <input type="text"
                   name="description"
                   placeholder="What is this file for?"
                   class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500" />
          </div>

          <button type="submit"
                  class="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 font-semibold">
            Upload File
          </button>
        </form>
      </div>

      <!-- Uploaded Files List -->
      <div class="bg-white rounded-lg shadow-md p-6">
        <h2 class="text-xl font-semibold mb-4 text-gray-700">
          Uploaded Files
          <span class="text-sm font-normal text-gray-400">({length(@files)} files)</span>
        </h2>

        <div :if={length(@files) == 0} class="text-center py-8 text-gray-400">
          No files uploaded yet. Upload your first file!
        </div>

        <div id="file-list" class="space-y-3">
          <.file_item :for={file <- @files} file={file} />
        </div>

        <div :if={length(@files) > 0} class="mt-6 pt-6 border-t border-gray-200">
          <button hx-post="/clear_files"
                  hx-confirm="Delete all uploaded files?"
                  class="w-full bg-red-600 text-white py-2 rounded-lg hover:bg-red-700 font-semibold">
            Clear All Files
          </button>
        </div>
      </div>

      <!-- Info Section -->
      <div class="mt-8 bg-blue-50 border border-blue-200 rounded-lg p-6">
        <h3 class="font-semibold text-blue-900 mb-2">How Multipart Works in Nex</h3>
        <ul class="text-sm text-blue-800 space-y-2">
          <li>✅ <strong>Zero Configuration</strong> - Nex automatically handles multipart/form-data</li>
          <li>✅ <strong>Plug.Upload</strong> - Access uploaded files via Plug.Upload struct</li>
          <li>✅ <strong>File Handling</strong> - Move, copy, or process files as needed</li>
          <li>✅ <strong>HTMX Integration</strong> - Upload files without page refresh</li>
        </ul>
      </div>
    </div>
    """
  end

  def upload(%{"file" => %Plug.Upload{filename: filename, path: temp_path}, "description" => description}) do
    # Generate unique filename to avoid collisions
    file_id = System.unique_integer([:positive])
    ext = Path.extname(filename)
    safe_filename = "file_#{file_id}#{ext}"
    upload_dir = "uploads"
    final_path = Path.join(upload_dir, safe_filename)

    # Ensure upload directory exists
    File.mkdir_p!(upload_dir)

    # Copy uploaded file to permanent location
    File.cp!(temp_path, final_path)

    file_info = %{
      id: file_id,
      original_name: filename,
      safe_name: safe_filename,
      description: description,
      size: File.stat!(final_path).size,
      uploaded_at: format_time(),
      path: final_path
    }

    Nex.Store.update(:uploaded_files, [], &[file_info | &1])

    assigns = %{file: file_info}
    ~H"<.file_item file={@file} />"
  end

  def upload(%{"file" => %Plug.Upload{}}) do
    # File uploaded without description
    upload(%{"file" => elem(Enum.at(elem(__ENV__.function, 0), 0), 0), "description" => ""})
  end

  def delete_file(%{"id" => id}) do
    id = String.to_integer(id)

    Nex.Store.update(:uploaded_files, [], fn files ->
      Enum.reject(files, fn file ->
        if file.id == id do
          # Delete the actual file from disk
          File.rm(file.path)
          true
        else
          false
        end
      end)
    end)

    :empty
  end

  def clear_files(_params) do
    files = Nex.Store.get(:uploaded_files, [])

    # Delete all files from disk
    Enum.each(files, fn file ->
      File.rm(file.path)
    end)

    Nex.Store.put(:uploaded_files, [])
    {:refresh}
  end

  defp format_time do
    {{year, month, day}, {hour, minute, _}} = :erlang.localtime()
    "#{year}-#{pad(month)}-#{pad(day)} #{pad(hour)}:#{pad(minute)}"
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"

  defp format_size(bytes) do
    cond do
      bytes < 1024 -> "#{bytes} B"
      bytes < 1024 * 1024 -> "#{div(bytes, 1024)} KB"
      true -> "#{div(bytes, 1024 * 1024)} MB"
    end
  end
end
