defmodule NexExamplesTestSupport.Assertions do
  import ExUnit.Assertions

  alias NexExamplesTestSupport.{HTML, HTTP}

  def assert_status(response, expected_status) do
    assert response.status == expected_status
  end

  def assert_redirect(response, expected_location) do
    case HTTP.header(response, "hx-redirect") do
      nil ->
        assert response.status in [301, 302, 303, 307, 308]
        assert HTTP.header(response, "location") == expected_location

      location ->
        assert location == expected_location
    end
  end

  def assert_has_test_id(html, test_id) do
    assert HTML.has_test_id?(html, test_id)
  end

  def assert_test_id_text(html, test_id, expected) do
    assert HTML.text_at(html, test_id) == expected
  end

  def assert_test_id_contains(html, test_id, expected) do
    assert HTML.text_at(html, test_id) =~ expected
  end
end
