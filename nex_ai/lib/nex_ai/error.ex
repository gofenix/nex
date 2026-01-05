defmodule NexAI.Error do
  @moduledoc "Structured error types for NexAI."

  defmodule APIError do
    defstruct [:message, :status, :type, :raw]
    
    def exception(opts) do
      msg = opts[:message] || "API Error"
      %__MODULE__{message: msg, status: opts[:status], type: opts[:type], raw: opts[:raw]}
    end
  end

  defmodule RateLimitError do
    defstruct [:message, :retry_after]
    
    def exception(opts) do
      %__MODULE__{message: opts[:message] || "Rate limit exceeded", retry_after: opts[:retry_after]}
    end
  end

  defmodule InvalidRequestError do
    defstruct [:message, :param]
    
    def exception(opts) do
      %__MODULE__{message: opts[:message], param: opts[:param]}
    end
  end

  defmodule TimeoutError do
    defstruct [:message, :timeout_ms]
    
    def exception(opts) do
      %__MODULE__{message: opts[:message] || "Request timed out", timeout_ms: opts[:timeout_ms]}
    end
  end
end
