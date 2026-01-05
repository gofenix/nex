defmodule NexAI.Error do
  @moduledoc """
  Standardized errors for NexAI, matching Vercel AI SDK Core error types.
  """

  defmodule APICallError do
    @moduledoc "Thrown when an API call fails."
    defexception [:message, :status_code, :body, :url, :is_retryable]

    @impl true
    def exception(opts) do
      msg = opts[:message] || "API call failed with status #{opts[:status_code]}"
      %__MODULE__{
        message: msg,
        status_code: opts[:status_code],
        body: opts[:body],
        url: opts[:url],
        is_retryable: opts[:is_retryable] || false
      }
    end
  end

  defmodule NoSuchModelError do
    @moduledoc "Thrown when the specified model does not exist."
    defexception [:message, :model_id]

    @impl true
    def exception(opts) do
      msg = opts[:message] || "Model '#{opts[:model_id]}' not found."
      %__MODULE__{message: msg, model_id: opts[:model_id]}
    end
  end

  defmodule InvalidArgumentError do
    @moduledoc "Thrown when an argument is invalid."
    defexception [:message, :argument]

    @impl true
    def exception(opts) do
      msg = opts[:message] || "Invalid argument: #{opts[:argument]}"
      %__MODULE__{message: msg, argument: opts[:argument]}
    end
  end
  
  defmodule RetryError do
    @moduledoc "Thrown when max retries are exceeded."
    defexception [:message, :last_error, :attempts]
    
    @impl true
    def exception(opts) do
      msg = opts[:message] || "Exceeded max retries (#{opts[:attempts]}). Last error: #{inspect(opts[:last_error])}"
      %__MODULE__{message: msg, last_error: opts[:last_error], attempts: opts[:attempts]}
    end
  end
end
