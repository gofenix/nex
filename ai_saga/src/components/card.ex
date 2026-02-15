defmodule AiSaga.Components.Card do
  @moduledoc """
  Reusable card component with slots.

  ## Usage

      <AiSaga.Components.Card.card title="Card Title" icon="⚡️">
        Main content here
      </AiSaga.Components.Card.card>
  """
  use Nex

  def card(assigns) do
    ~H"""
    <div class="bg-white p-6 border-2 border-black md-shadow-sm hover:translate-x-1 hover:translate-y-1 transition-transform group">
      <div class="flex items-center gap-3 mb-3">
        <span class="text-2xl group-hover:scale-110 transition-transform">{@icon}</span>
        <h2 class="text-base font-bold tracking-tight">{@title}</h2>
      </div>
      <div class="text-sm opacity-70 leading-relaxed">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
