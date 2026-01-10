defmodule NexAI.Error do
  @moduledoc "Structured error types for NexAI."

  defmodule APIError do
    defexception [:message, :status, :type, :raw]

    def exception(opts) do
      msg = opts[:message] || "API Error"
      %__MODULE__{message: msg, status: opts[:status], type: opts[:type], raw: opts[:raw]}
    end
  end

  defmodule RateLimitError do
    defexception [:message, :retry_after]

    def exception(opts) do
      %__MODULE__{message: opts[:message] || "Rate limit exceeded", retry_after: opts[:retry_after]}
    end
  end

  defmodule AuthenticationError do
    defexception [:message, :status, :raw]

    def exception(opts) do
      %__MODULE__{message: opts[:message] || "Authentication failed", status: opts[:status], raw: opts[:raw]}
    end
  end

  defmodule InvalidRequestError do
    defexception [:message, :param, :status, :raw]

    def exception(opts) do
      %__MODULE__{message: opts[:message], param: opts[:param], status: opts[:status], raw: opts[:raw]}
    end
  end

  defmodule TimeoutError do
    defexception [:message, :timeout_ms]

    def exception(opts) do
      %__MODULE__{message: opts[:message] || "Request timed out", timeout_ms: opts[:timeout_ms]}
    end
  end

  defmodule ToolExecutionError do
    defexception [:message, :tool_name, :args, :error]

    def exception(opts) do
      %__MODULE__{
        message: opts[:message] || "Tool execution failed",
        tool_name: opts[:tool_name],
        args: opts[:args],
        error: opts[:error]
      }
    end
  end

  defmodule ValidationError do
    defexception [:message, :field, :value]

    def exception(opts) do
      %__MODULE__{
        message: opts[:message] || "Validation failed",
        field: opts[:field],
        value: opts[:value]
      }
    end
  end

  defmodule UnsupportedFeatureError do
    defexception [:message, :feature, :provider]

    def exception(opts) do
      %__MODULE__{
        message: opts[:message] || "Feature not supported",
        feature: opts[:feature],
        provider: opts[:provider]
      }
    end
  end
end
