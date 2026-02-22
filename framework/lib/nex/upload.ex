defmodule Nex.Upload do
  @moduledoc """
  File upload handling for Nex applications.

  ## Usage

  Files are automatically parsed from multipart form data and available in `req.body`.

      def post(req) do
        # req.body["avatar"] is a %Plug.Upload{} struct
        case req.body["avatar"] do
          nil ->
            Nex.json(%{error: "No file uploaded"}, status: 400)

          upload ->
            # Save to disk
            case save(upload, "priv/uploads") do
              {:ok, path} ->
                Nex.json(%{url: path})

              {:error, reason} ->
                Nex.json(%{error: reason}, status: 500)
            end
        end
      end

  ## File Validation

      def post(req) do
        upload = req.body["file"]

        # Validate before saving
        case validate(upload, max_size: 5_000_000, types: ["image/jpeg", "image/png"]) do
          :ok ->
            save(upload, "priv/uploads")

          {:error, reason} ->
            Nex.json(%{error: reason}, status: 400)
        end
      end
  """

  @type upload :: %Plug.Upload{}
  @type result :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Saves an uploaded file to disk.

  ## Arguments

    * `upload` - %Plug.Upload{} struct from req.body
    * `dir` - Directory to save to (created if not exists)

  ## Returns

    * `{:ok, "/uploads/filename.jpg"}` - Relative URL path
    * `{:error, "reason"}` - Error message
  """
  @spec save(upload(), String.t()) :: result()
  def save(%Plug.Upload{path: source_path, filename: filename}, dir) do
    with :ok <- ensure_dir_exists(dir),
         :ok <- copy_file(source_path, dir, filename) do
      {:ok, "/#{dir}/#{filename}"}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Saves with a custom filename (avoids filename conflicts).

  ## Arguments

    * `upload` - %Plug.Upload{} struct
    * `dir` - Directory to save to
    * `options` - [prefix: "custom_"] to add prefix
  """
  @spec save(upload(), String.t(), keyword()) :: result()
  def save(%Plug.Upload{} = original_upload, dir, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "")
    ext = Path.extname(original_upload.filename)
    base = Path.basename(original_upload.filename, ext)
    unique_name = "#{prefix}#{base}_#{:os.system_time()}#{ext}"

    upload = %Plug.Upload{
      original_upload
      | filename: unique_name
    }

    save(upload, dir)
  end

  @doc """
  Validates an upload before saving.

  ## Options

    * `:max_size` - Maximum file size in bytes (e.g., 5_000_000 for 5MB)
    * `:types` - Allowed MIME types (e.g., ["image/jpeg", "image/png"])
    * `:exts` - Allowed extensions (e.g., [".jpg", ".png"])

  ## Returns

    * `:ok` - Validation passed
    * `{:error, "reason"}` - Validation failed
  """
  @spec validate(upload() | nil, keyword()) :: :ok | {:error, String.t()}
  def validate(nil, _opts), do: {:error, "No file uploaded"}

  def validate(%Plug.Upload{} = upload, opts) do
    with :ok <- validate_size(upload, opts),
         :ok <- validate_type(upload, opts),
         :ok <- validate_ext(upload, opts) do
      :ok
    end
  end

  defp ensure_dir_exists(dir) do
    case File.mkdir_p(dir) do
      :ok -> :ok
      {:error, reason} -> {:error, "Cannot create directory: #{inspect(reason)}"}
    end
  end

  defp copy_file(source, dest_dir, filename) do
    dest = Path.join(dest_dir, filename)

    case File.cp(source, dest) do
      :ok -> :ok
      {:error, reason} -> {:error, "Cannot copy file: #{inspect(reason)}"}
    end
  end

  defp validate_size(%Plug.Upload{path: path}, opts) do
    case Keyword.get(opts, :max_size) do
      nil ->
        :ok

      max_size ->
        case File.stat(path) do
          {:ok, %{size: size}} when size > max_size ->
            {:error, "File too large. Maximum size is #{max_size} bytes"}

          _ ->
            :ok
        end
    end
  end

  defp validate_type(%Plug.Upload{content_type: type}, opts) do
    case Keyword.get(opts, :types) do
      nil ->
        :ok

      types ->
        if type in types do
          :ok
        else
          {:error, "Invalid file type. Allowed: #{Enum.join(types, ", ")}"}
        end
    end
  end

  defp validate_ext(%Plug.Upload{filename: filename}, opts) do
    case Keyword.get(opts, :exts) do
      nil ->
        :ok

      exts ->
        ext = Path.extname(filename) |> String.downcase()

        if ext in exts do
          :ok
        else
          {:error, "Invalid file extension. Allowed: #{Enum.join(exts, ", ")}"}
        end
    end
  end
end
