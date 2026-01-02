defmodule NexWebsite.Partials.Nav do
  use Nex

  def render(assigns) do
    ~H"""
    <div class="navbar sticky top-0 z-50 px-4 md:px-8">
      <div class="navbar-start">
        <div class="dropdown">
          <div tabindex="0" role="button" class="btn btn-ghost lg:hidden">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h8m-8 6h16" /></svg>
          </div>
          <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52 font-medium">
            <li><a href="/features">Features</a></li>
            <li><a href="/getting_started">Get Started</a></li>
            <li><a href="https://github.com/gofenix/nex">GitHub</a></li>
          </ul>
        </div>
        <a href="/" class="btn btn-ghost text-2xl font-black tracking-tighter gap-1">
          <span class="text-claude-purple">Nex</span>
        </a>
      </div>
      <div class="navbar-end hidden lg:flex">
        <ul class="menu menu-horizontal px-1 font-semibold gap-2">
          <li><a href="/features" class="px-4">Features</a></li>
          <li><a href="/docs" class="px-4">Docs</a></li>
          <li><a href="/getting_started" class="px-4">Get Started</a></li>
          <li><a href="https://github.com/gofenix/nex" class="px-4">GitHub</a></li>
        </ul>
        <a href="/getting_started" class="btn btn-claude-purple ml-4 px-6 rounded-full shadow-lg shadow-purple-200">
          Install Now
        </a>
      </div>
    </div>
    """
  end
end
