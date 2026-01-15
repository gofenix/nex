defmodule Bestofex.Components.Card do
  @moduledoc """
  Reusable card component with slots.

  ## Usage

      <Bestofex.Components.Card.card title="Card Title" icon="⚡️">
        Main content here
      </Bestofex.Components.Card.card>
  """
  use Nex

  def card(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm border border-base-300 hover:border-primary/30 transition-all group">
      <div class="card-body p-6">
        <div class="flex items-center gap-3 mb-2">
          <span class="text-2xl group-hover:scale-110 transition-transform">{@icon}</span>
          <h2 class="card-title text-base font-bold tracking-tight">{@title}</h2>
        </div>
        <div class="text-base-content/60 text-sm leading-relaxed">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end
end
