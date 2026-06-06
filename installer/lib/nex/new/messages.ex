defmodule Nex.New.Messages do
  @moduledoc false

  alias Nex.New.Legacy

  def success_message(name, starter, deps_installed, base_path \\ ".") do
    Legacy.success_message(name, starter, deps_installed, base_path)
  end
end
