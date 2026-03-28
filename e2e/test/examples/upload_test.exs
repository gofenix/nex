defmodule E2E.UploadTest do
  use E2E.ExampleCase, example: "upload"

  alias E2E.Root

  test "accepts valid uploads and rejects empty or invalid ones", %{
    client: client,
    example_config: example
  } do
    {home, _jar} = HTTP.get(client, "/")
    assert_has_test_id(home.body, "upload-page")
    headers = HTTP.nex_headers(home.body, htmx: true, target: "#result")

    {empty_submission, _jar} = HTTP.post(client, "/upload", headers: headers)
    assert_status(empty_submission, 200)
    assert empty_submission.body =~ "No file selected"

    filename = "upload-#{System.unique_integer([:positive])}.png"
    fixture = Root.repo_path(["e2e", "fixtures", "test-image.png"])

    {uploaded, _jar} =
      HTTP.post(client, "/upload",
        headers: headers,
        multipart: [HTTP.file_part("file", fixture, "image/png", filename)]
      )

    assert uploaded.body =~ "Upload successful"

    image_path = first_attr(uploaded.body, "img", "src")
    assert image_path == "/static/uploads/#{filename}"

    {image_response, _jar} = HTTP.get(client, image_path)
    assert_status(image_response, 200)

    saved_file = Path.join(example.cwd, "priv/static/uploads/#{filename}")

    on_exit(fn ->
      File.rm(saved_file)
    end)

    invalid_fixture = Root.repo_path(["e2e", "fixtures", "invalid.txt"])

    {invalid_upload, _jar} =
      HTTP.post(client, "/upload",
        headers: headers,
        multipart: [HTTP.file_part("file", invalid_fixture, "text/plain", "invalid.txt")]
      )

    assert invalid_upload.body =~ "Validation failed"
  end
end
