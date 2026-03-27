defmodule ErrorPagesExample.ErrorPages do
  @moduledoc """
  Custom error page module for Nex 0.4.
  Implements render_error/4 callback.
  """

  def render_error(_conn, status, message, _stacktrace) when status == 404 do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>404 - Page Not Found</title>
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-gradient-to-br from-blue-500 to-purple-600 min-h-screen flex items-center justify-center">
      <div data-testid="error-page-404" class="bg-white rounded-lg shadow-2xl p-12 text-center max-w-md">
        <div class="text-6xl mb-4">🔍</div>
        <h1 class="text-4xl font-bold text-gray-800 mb-2">404</h1>
        <p class="text-xl text-gray-600 mb-4">#{message}</p>
        <p class="text-gray-500 mb-6">The page you're looking for doesn't exist.</p>
        <a href="/" class="bg-blue-500 text-white px-6 py-2 rounded hover:bg-blue-600">Go Home</a>
      </div>
    </body>
    </html>
    """
  end

  def render_error(_conn, status, message, _stacktrace) when status == 403 do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>403 - Forbidden</title>
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-gradient-to-br from-red-500 to-orange-600 min-h-screen flex items-center justify-center">
      <div data-testid="error-page-403" class="bg-white rounded-lg shadow-2xl p-12 text-center max-w-md">
        <div class="text-6xl mb-4">🚫</div>
        <h1 class="text-4xl font-bold text-gray-800 mb-2">403</h1>
        <p class="text-xl text-gray-600 mb-4">#{message}</p>
        <p class="text-gray-500 mb-6">You don't have permission to access this resource.</p>
        <a href="/" class="bg-red-500 text-white px-6 py-2 rounded hover:bg-red-600">Go Home</a>
      </div>
    </body>
    </html>
    """
  end

  def render_error(_conn, status, message, stacktrace) when status == 500 do
    # In production, don't show stacktrace
    details =
      if Mix.env() == :dev do
        "<pre class=\"text-left text-sm mt-4 bg-gray-100 p-4 rounded overflow-auto\">#{inspect(stacktrace, limit: 10)}</pre>"
      else
        ""
      end

    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>500 - Internal Server Error</title>
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-gradient-to-br from-gray-700 to-gray-900 min-h-screen flex items-center justify-center">
      <div data-testid="error-page-500" class="bg-white rounded-lg shadow-2xl p-12 text-center max-w-2xl">
        <div class="text-6xl mb-4">💥</div>
        <h1 class="text-4xl font-bold text-gray-800 mb-2">500</h1>
        <p class="text-xl text-gray-600 mb-4">#{message}</p>
        <p class="text-gray-500 mb-6">Something went wrong on our end. Please try again later.</p>
        #{details}
        <a href="/" class="bg-gray-700 text-white px-6 py-2 rounded hover:bg-gray-800 mt-4 inline-block">Go Home</a>
      </div>
    </body>
    </html>
    """
  end

  def render_error(_conn, status, message, _stacktrace) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <title>Error #{status}</title>
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-gray-100 min-h-screen flex items-center justify-center">
      <div class="bg-white rounded-lg shadow p-12 text-center">
        <h1 class="text-4xl font-bold mb-4">Error #{status}</h1>
        <p class="text-gray-600">#{message}</p>
        <a href="/" class="text-blue-500 hover:underline mt-4 inline-block">Go Home</a>
      </div>
    </body>
    </html>
    """
  end
end
