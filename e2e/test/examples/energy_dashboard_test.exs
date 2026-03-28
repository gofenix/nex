defmodule E2E.EnergyDashboardTest do
  use E2E.ExampleCase, example: "energy_dashboard"

  test "renders the dashboard and streams synchronized SSE updates", %{
    client: client,
    example_config: example
  } do
    {home, _jar} = HTTP.get(client, "/")
    assert_has_test_id(home.body, "energy-dashboard-page")
    assert_has_test_id(home.body, "energy-price")
    assert_has_test_id(home.body, "energy-time")
    assert_has_test_id(home.body, "energy-data-points")

    events = SSE.collect(Example.base_url(example) <> "/api/energy_stream", 6, timeout: 7_000)

    assert Enum.at(events, 0).event == "price"
    assert Enum.at(events, 1).event == "time"
    assert Enum.at(events, 2).event == "data_points"
    assert Enum.at(events, 3).event == "price"
    assert Enum.at(events, 4).event == "time"
    assert Enum.at(events, 5).event == "data_points"

    assert Enum.at(events, 0).data =~ ~r/^\d+\.\d{2}$/
    assert Enum.at(events, 1).data =~ ~r/^\d{2}:\d{2}:\d{2} UTC$/
    assert Enum.at(events, 2).data =~ ~r/^\d+$/
    assert Enum.at(events, 2).data != Enum.at(events, 5).data
  end
end
