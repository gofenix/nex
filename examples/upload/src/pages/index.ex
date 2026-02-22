defmodule Upload.Pages.Index do
  use Nex

  def mount(_params) do
    %{uploaded_files: []}
  end

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-bold mb-8 text-gray-800">File Upload Demo</h1>

    <div class="bg-white rounded-lg shadow-md p-6 mb-6">
      <h2 class="text-xl font-semibold mb-4">Upload a File</h2>
      
      <form hx-post="/upload" hx-target="#result" hx-encoding="multipart/form-data" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-2">
            Choose an image
          </label>
          <input 
            type="file" 
            name="file" 
            accept="image/*"
            class="block w-full text-sm text-gray-500
              file:mr-4 file:py-2 file:px-4
              file:rounded-full file:border-0
              file:text-sm file:font-semibold
              file:bg-blue-50 file:text-blue-700
              hover:file:bg-blue-100"
          />
        </div>
        <button 
          type="submit"
          class="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700"
        >
          Upload
        </button>
      </form>

      <div id="result" class="mt-4"></div>
    </div>

    <div class="bg-white rounded-lg shadow-md p-6">
      <h2 class="text-xl font-semibold mb-4">How it works</h2>
      <p class="text-gray-600">See source code in <code class="bg-gray-100 px-2 py-1 rounded">src/pages/index.ex</code></p>
    </div>
    """
  end

  def upload(req) do
    upload = req.body["file"]

    case upload do
      nil ->
        Nex.html("""
        <div class="p-4 bg-red-100 border border-red-400 text-red-700 rounded">
          No file selected
        </div>
        """)

      _ ->
        case Nex.Upload.validate(upload, max_size: 5_000_000, types: ["image/jpeg", "image/png"]) do
          :ok ->
            case Nex.Upload.save(upload, "priv/static/uploads") do
              {:ok, _path} ->
                url = "/static/uploads/#{upload.filename}"

                content =
                  "<p class=\"text-sm\">Saved to: #{url}</p><img src=\"#{url}\" class=\"mt-2 max-w-xs rounded shadow\" />"

                Nex.html("""
                <div class="p-4 bg-green-100 border border-green-400 text-green-700 rounded">
                  <p class="font-semibold">Upload successful!</p>
                  #{content}
                </div>
                """)

              {:error, reason} ->
                Nex.html("""
                <div class="p-4 bg-red-100 border border-red-400 text-red-700 rounded">
                  Save failed: #{reason}
                </div>
                """)
            end

          {:error, reason} ->
            Nex.html("""
            <div class="p-4 bg-red-100 border border-red-400 text-red-700 rounded">
              Validation failed: #{reason}
            </div>
            """)
        end
    end
  end
end
