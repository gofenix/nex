defmodule DatastarDemo.Api.Stream do
  use Nex

  @event_count 5

  def get(_req) do
    Nex.stream(fn send ->
      Enum.each(1..@event_count, fn i ->
        now = Calendar.strftime(DateTime.utc_now(), "%H:%M:%S")

        send.(
          Nex.Datastar.patch_elements(
            ~s(<div id="feed" data-testid="datastar-feed" class="space-y-2 p-4 bg-base-200 rounded-lg min-h-[80px]"><div class="flex items-center gap-2"><span class="badge badge-outline badge-sm">#{now}</span><span>Event ##{i}</span></div></div>),
            selector: "#feed"
          )
        )

        send.(Nex.Datastar.patch_signals(%{streamCount: i}))

        if i < @event_count, do: Process.sleep(1_000)
      end)
    end)
  end
end
