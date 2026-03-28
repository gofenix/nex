defmodule Nex.New.Messages do
  @moduledoc false

  alias Nex.New.Legacy

  def success_message(name, starter, deps_installed) do
    Legacy.success_message(name, starter, deps_installed)
  end
end
