defmodule ErrorShowcase.Api.Error do
  use Nex

  def get(%{"code" => code_str}) do
    code = String.to_integer(code_str)

    Nex.json(
      %{
        error: true,
        code: code,
        message: get_error_message(code),
        description: get_error_description(code),
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      },
      status: code
    )
  end

  defp get_error_message(404), do: "Not Found"
  defp get_error_message(500), do: "Internal Server Error"
  defp get_error_message(code), do: "Error #{code}"

  defp get_error_description(404) do
    "The requested resource does not exist."
  end

  defp get_error_description(500) do
    "An internal server error occurred while processing your request."
  end

  defp get_error_description(_code) do
    "An unexpected error occurred."
  end
end
