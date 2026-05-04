defmodule DatastarDemo.E2ETest do
  use DatastarDemo.ExampleCase

  test "page renders with all sections", %{client: client} do
    {home, _jar} = HTTP.get(client, "/")
    assert_status(home, 200)
    assert_has_test_id(home.body, "datastar-page")
    assert_has_test_id(home.body, "datastar-signals-section")
    assert_has_test_id(home.body, "datastar-morph-section")
    assert_has_test_id(home.body, "datastar-stream-section")
    assert_has_test_id(home.body, "datastar-todos-section")
    assert home.body =~ "data-signals"
    assert home.body =~ "data-bind:name"
    assert home.body =~ "data-bind:newTodo"
    assert home.body =~ "data-text"
  end

  test "process endpoint returns HTML fragment", %{client: client} do
    {resp, _jar} =
      HTTP.post(client, "/api/process", json: %{"text" => "hello world"})

    assert_status(resp, 200)
    assert resp.body =~ "HELLO WORLD"
    assert resp.body =~ "dlrow olleh"
    assert resp.body =~ "11 characters"
    assert resp.body =~ ~s(id="result")
  end

  test "stream endpoint sends Datastar SSE events", %{example_config: config} do
    base_url = "http://127.0.0.1:#{config.port}"
    events = SSE.collect("#{base_url}/api/stream", 4, timeout: 10_000)

    patch_elements = Enum.filter(events, &(&1.event == "datastar-patch-elements"))
    patch_signals = Enum.filter(events, &(&1.event == "datastar-patch-signals"))

    assert length(patch_elements) >= 1
    assert length(patch_signals) >= 1

    first_el = hd(patch_elements)
    assert first_el.data =~ "selector #feed"
    assert first_el.data =~ "fragments"
    assert first_el.data =~ "Event #"

    first_sig = hd(patch_signals)
    assert first_sig.data =~ "signals"
    assert first_sig.data =~ "streamCount"
  end

  test "todo endpoint stores todos and returns Datastar patches", %{client: client} do
    page_id = "datastar-todos-test-#{System.unique_integer([:positive])}"

    {resp, _jar} =
      HTTP.post(client, "/api/todos", json: %{"text" => "ship the spike", "pageId" => page_id})

    assert_status(resp, 200)
    assert HTTP.header(resp, "content-type") =~ "text/event-stream"
    assert resp.body =~ "event: datastar-patch-elements"
    assert resp.body =~ "selector #todo-list"
    assert resp.body =~ "mode append"
    assert resp.body =~ "ship the spike"
    assert resp.body =~ "event: datastar-patch-signals"
    assert resp.body =~ ~s("todoCount":1)

    {second_resp, _jar} =
      HTTP.post(client, "/api/todos",
        json: %{"text" => "write the forum update", "pageId" => page_id}
      )

    assert_status(second_resp, 200)
    assert second_resp.body =~ "write the forum update"
    assert second_resp.body =~ ~s("todoCount":2)
  end
end
