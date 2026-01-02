defmodule Nex.SSE do
  @moduledoc """
  Behaviour for Server-Sent Events (SSE) endpoints.

  SSE endpoints can be placed anywhere in your application structure
  (e.g., `src/api/chat/stream.ex`) and are identified by `use Nex`.

  ## Example

      defmodule MyApp.Api.Chat.Stream do
        use Nex

        @impl true
        def stream(params, send_fn) do
          # Send SSE events using the callback function
          send_fn.(%{event: "message", data: "Hello"})
          send_fn.(%{event: "message", data: "World"})
          :ok
        end
      end

  The `stream/2` callback receives:
  - `params` - Request parameters (query params, form data, etc.)
  - `send_fn` - Callback function to send SSE events immediately

  SSE events should be maps with:
  - `event` - Event type (e.g., "message", "error", "done")
  - `data` - Event data (string or will be JSON-encoded)
  - `id` - Optional event ID
  """

  @doc """
  Stream SSE events to the client.

  This callback is invoked when a client connects to the SSE endpoint.
  Use the `send_fn` callback to send events immediately as they're generated.

  ## Parameters

  - `params` - Map of request parameters
  - `send_fn` - Function to send SSE events: `send_fn.(%{event: type, data: content})`

  ## Return value

  Should return `:ok` when streaming is complete.
  """
  @callback stream(params :: map(), send_fn :: function()) :: :ok

  defmacro __using__(_opts) do
    quote do
      @behaviour Nex.SSE

      # Mark this module as an SSE endpoint
      def __sse_endpoint__, do: true
    end
  end
end
