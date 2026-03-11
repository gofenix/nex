# File Uploads (Nex.Upload)

Handling file uploads in Nex is designed to be straightforward and secure. The `Nex.Upload` module provides utilities for validating and saving files uploaded via multipart forms.

## Basic HTML Form

To upload files, ensure your form has `enctype="multipart/form-data"`:

```html
<form method="post" action="/upload" enctype="multipart/form-data">
  <input type="file" name="avatar" accept="image/png, image/jpeg" />
  <button type="submit">Upload</button>
</form>
```

*(Note: If you use HTMX, `hx-encoding="multipart/form-data"` should be added to the form).*

## Processing the Upload

When a file is uploaded, it appears in `req.body` as a `%Plug.Upload{}` struct under the specified input name.

```elixir
defmodule MyApp.Pages.Profile do
  use Nex

  def upload_avatar(req) do
    # req.body["avatar"] is a %Plug.Upload{} struct
    upload = req.body["avatar"]

    if upload do
      # 1. Validate the upload
      rules = [
        max_size: 5 * 1024 * 1024, # 5MB
        allowed_types: ["image/jpeg", "image/png"],
        allowed_extensions: [".jpg", ".jpeg", ".png"]
      ]

      case Nex.Upload.validate(upload, rules) do
        :ok ->
          # 2. Save the file
          dest_dir = "priv/static/uploads"
          File.mkdir_p!(dest_dir)
          
          # Generates a unique name to prevent collisions
          unique_filename = "\#{System.unique_integer([:positive])}_\#{upload.filename}"
          
          case Nex.Upload.save(upload, dest_dir, unique_filename) do
            {:ok, path} ->
              Nex.Flash.put(:success, "File uploaded successfully!")
              {:redirect, "/profile"}
              
            {:error, reason} ->
              Nex.Flash.put(:error, "Failed to save file: \#{inspect(reason)}")
              {:redirect, "/profile"}
          end

        {:error, reason} ->
          Nex.Flash.put(:error, "Invalid file: \#{reason}")
          {:redirect, "/profile"}
      end
    else
      Nex.Flash.put(:error, "No file selected.")
      {:redirect, "/profile"}
    end
  end
end
```

## Validation Rules

`Nex.Upload.validate/2` accepts the following options:

*   **`:max_size`**: Maximum file size in bytes. (e.g., `5 * 1024 * 1024` for 5MB). Returns `{:error, "File too large"}` if exceeded.
*   **`:allowed_types`**: List of allowed MIME types (e.g., `["image/jpeg", "application/pdf"]`). Returns `{:error, "Invalid content type"}` if it doesn't match.
*   **`:allowed_extensions`**: List of allowed file extensions, including the dot (e.g., `[".jpg", ".png"]`). Case-insensitive. Returns `{:error, "Invalid file extension"}` if it doesn't match.

## Security Considerations

The `Nex.Upload.save/3` function automatically sanitizes the filename using `Path.basename/1` to prevent Path Traversal attacks (e.g., trying to save to `../../etc/passwd`).

However, it is highly recommended to **always generate your own unique filenames** (e.g., using UUIDs or database IDs) rather than relying on the user-provided `upload.filename`, to prevent users from overwriting each other's files.
