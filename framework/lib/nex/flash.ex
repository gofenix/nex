defmodule Nex.Flash do
  @moduledoc """
  One-time flash messages for Nex applications.

  Flash messages are stored in the session and automatically cleared after
  being read on the next page render. Perfect for post-action notifications
  like "Saved successfully!" or "Invalid credentials."

  ## Usage

      # In an action — set a flash message
      def create(%{"title" => title}) do
        # ... create logic ...
        Nex.Flash.put(:info, "Post created successfully!")
        {:redirect, "/posts"}
      end

      def login(%{"email" => email, "password" => password}) do
        case authenticate(email, password) do
          {:ok, _user} ->
            Nex.Flash.put(:success, "Welcome back!")
            {:redirect, "/dashboard"}
          {:error, _} ->
            Nex.Flash.put(:error, "Invalid email or password.")
            {:redirect, "/login"}
        end
      end

      # In mount/1 — read and clear flash messages
      def mount(_params) do
        flash = Nex.Flash.pop_all()
        %{flash: flash}
      end

      # In your layout or page template
      ~H\"\"\"
      <%= if @flash[:error] do %>
        <div class="alert alert-error">{@flash[:error]}</div>
      <% end %>
      <%= if @flash[:info] do %>
        <div class="alert alert-info">{@flash[:info]}</div>
      <% end %>
      \"\"\"

  ## Flash Types

  Any atom key is valid. Common conventions:
  - `:info` — neutral informational message
  - `:success` — positive confirmation
  - `:error` — error or failure
  - `:warning` — caution message
  """

  @flash_key :__nex_flash__

  @doc """
  Puts a flash message. Stored in session, survives one redirect.

  ## Examples

      Nex.Flash.put(:info, "Saved!")
      Nex.Flash.put(:error, "Something went wrong.")
  """
  def put(type, message) when is_atom(type) do
    current = Nex.Session.get(@flash_key, %{})
    updated = Map.put(current, type, message)
    Nex.Session.put(@flash_key, updated)
    :ok
  end

  @doc """
  Gets a single flash message by type without clearing it.
  """
  def get(type) when is_atom(type) do
    Nex.Session.get(@flash_key, %{}) |> Map.get(type)
  end

  @doc """
  Returns all flash messages as a map and clears them from the session.

  Call this in `mount/1` to retrieve and consume flash messages.

  ## Example

      def mount(_params) do
        flash = Nex.Flash.pop_all()
        %{flash: flash}
      end
  """
  def pop_all do
    messages = Nex.Session.get(@flash_key, %{})
    Nex.Session.delete(@flash_key)
    messages
  end

  @doc """
  Returns all flash messages without clearing them.
  """
  def peek_all do
    Nex.Session.get(@flash_key, %{})
  end

  @doc """
  Clears all flash messages.
  """
  def clear do
    Nex.Session.delete(@flash_key)
    :ok
  end
end
