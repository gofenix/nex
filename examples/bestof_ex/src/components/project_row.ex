defmodule BestofEx.Components.ProjectRow do
  use Nex

  def project_row(assigns) do
    ~H"""
    <div class="card bg-base-100 shadow-sm">
      <div class="card-body flex-row items-center gap-4">
        <div class="text-2xl font-bold text-base-content/30 w-8">
          #{@rank}
        </div>
        <div class="flex-1">
          <h3 class="font-semibold text-lg">
            <a href={"/projects/#{@project["id"]}"} class="hover:text-primary">{@project["name"]}</a>
          </h3>
          <p class="text-base-content/60 text-sm">{@project["description"]}</p>
        </div>
        <div class="text-center">
          <div class="text-xl font-bold">{@project["stars"] || 0}</div>
          <div class="text-xs text-base-content/50">stars</div>
        </div>
      </div>
    </div>
    """
  end
end
