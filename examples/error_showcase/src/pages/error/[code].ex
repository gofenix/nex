defmodule ErrorShowcase.Pages.Error do
  use Nex

  def mount(%{"code" => code_str}) do
    code = String.to_integer(code_str)

    %{
      title: "Error #{code}",
      code: code,
      message: get_error_message(code),
      description: get_error_description(code)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto p-6">
      <div class="bg-white rounded-lg shadow-md p-8 text-center">
        <h1 class="text-6xl font-bold text-red-600 mb-4">{@code}</h1>
        <h2 class="text-2xl font-semibold text-gray-800 mb-4">{@message}</h2>
        <p class="text-gray-600 mb-8">{@description}</p>

        <a href="/"
           class="inline-block px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
          ← Back to Home
        </a>
      </div>

      <div class="mt-8 bg-blue-50 border border-blue-200 rounded-lg p-6">
        <h3 class="font-semibold text-blue-900 mb-2">What happened?</h3>
        <p class="text-sm text-blue-800">
          This error page was triggered intentionally to demonstrate Nex's smart error handling.
          In a real application, errors like these would indicate actual problems that need to be fixed.
        </p>
      </div>
    </div>
    """
  end

  defp get_error_message(404), do: "Not Found"
  defp get_error_message(500), do: "Internal Server Error"
  defp get_error_message(code), do: "Error #{code}"

  defp get_error_description(404) do
    "The page you're looking for doesn't exist. It might have been moved or deleted."
  end

  defp get_error_description(500) do
    "Something went wrong on our end. Our team has been notified and is working on a fix."
  end

  defp get_error_description(_code) do
    "An unexpected error occurred. Please try again later."
  end
end
