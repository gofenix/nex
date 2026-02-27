defmodule Nex.UploadTest do
  use ExUnit.Case, async: true

  describe "save/2" do
    test "saves upload to specified directory" do
      # Create a temporary file to upload
      temp_file = "/tmp/test_upload_#{:rand.uniform(10000)}.txt"
      File.write!(temp_file, "test content")

      upload = %Plug.Upload{
        path: temp_file,
        filename: "test.txt",
        content_type: "text/plain"
      }

      upload_dir = "/tmp/nex_test_uploads_#{:rand.uniform(10000)}"

      result = Nex.Upload.save(upload, upload_dir)

      assert match?({:ok, _}, result)
      {:ok, path} = result
      assert path =~ ~r/\/nex_test_uploads.*test\.txt/

      # Cleanup
      File.rm_rf!(upload_dir)
    end

    test "returns error when source file missing" do
      upload = %Plug.Upload{
        path: "/nonexistent/file.txt",
        filename: "test.txt",
        content_type: "text/plain"
      }

      result = Nex.Upload.save(upload, "/tmp")

      assert match?({:error, _}, result)
    end

    test "saves with custom prefix" do
      temp_file = "/tmp/test_prefix_#{:rand.uniform(10000)}.txt"
      File.write!(temp_file, "content")

      upload = %Plug.Upload{
        path: temp_file,
        filename: "original.txt",
        content_type: "text/plain"
      }

      upload_dir = "/tmp/nex_test_prefix_#{:rand.uniform(10000)}"

      result = Nex.Upload.save(upload, upload_dir, prefix: "custom_")

      assert {:ok, path} = result
      assert path =~ "custom_original"

      File.rm_rf!(upload_dir)
    end
  end

  describe "validate/2" do
    test "returns ok for valid upload" do
      temp_file = "/tmp/test_validate_#{:rand.uniform(10000)}.txt"
      File.write!(temp_file, "content")

      upload = %Plug.Upload{
        path: temp_file,
        filename: "test.txt",
        content_type: "text/plain"
      }

      result = Nex.Upload.validate(upload, max_size: 1_000_000, types: ["text/plain"])

      assert result == :ok

      File.rm(temp_file)
    end

    test "returns error for nil upload" do
      result = Nex.Upload.validate(nil, max_size: 1_000_000)
      assert result == {:error, "No file uploaded"}
    end

    test "returns error when file too large" do
      temp_file = "/tmp/test_large_#{:rand.uniform(10000)}.txt"
      File.write!(temp_file, String.duplicate("x", 100))

      upload = %Plug.Upload{
        path: temp_file,
        filename: "large.txt",
        content_type: "text/plain"
      }

      result = Nex.Upload.validate(upload, max_size: 50)

      {:error, msg} = result
      assert String.contains?(msg, "too large")

      File.rm(temp_file)
    end

    test "returns error for invalid file type" do
      temp_file = "/tmp/test_type_#{:rand.uniform(10000)}.txt"
      File.write!(temp_file, "content")

      upload = %Plug.Upload{
        path: temp_file,
        filename: "test.exe",
        content_type: "application/octet-stream"
      }

      result = Nex.Upload.validate(upload, types: ["image/jpeg", "image/png"])

      {:error, msg} = result
      assert String.contains?(msg, "Invalid file type")

      File.rm(temp_file)
    end

    test "returns error for invalid file extension" do
      temp_file = "/tmp/test_ext_#{:rand.uniform(10000)}.txt"
      File.write!(temp_file, "content")

      upload = %Plug.Upload{
        path: temp_file,
        filename: "script.exe",
        content_type: "text/plain"
      }

      result = Nex.Upload.validate(upload, exts: [".jpg", ".png"])

      {:error, msg} = result
      assert String.contains?(msg, "Invalid file extension")

      File.rm(temp_file)
    end

    test "accepts all types when types option not provided" do
      temp_file = "/tmp/test_all_types_#{:rand.uniform(10000)}.txt"
      File.write!(temp_file, "content")

      upload = %Plug.Upload{
        path: temp_file,
        filename: "test.any",
        content_type: "anything"
      }

      result = Nex.Upload.validate(upload, max_size: 1_000_000)

      assert result == :ok

      File.rm(temp_file)
    end
  end
end
