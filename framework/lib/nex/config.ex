defmodule Nex.Config do
  @moduledoc """
  Centralized configuration access for Nex framework.
  """

  @doc "Returns the application module name."
  def app_module, do: Application.get_env(:nex_core, :app_module, "MyApp")

  @doc "Returns the source path for routes."
  def src_path, do: Application.get_env(:nex_core, :src_path, "src")

  @doc "Returns whether running in dev environment."
  def dev?, do: Application.get_env(:nex_core, :env, :prod) == :dev

  @doc "Returns the error page module if configured."
  def error_page_module, do: Application.get_env(:nex_core, :error_page_module)
end
