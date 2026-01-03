defmodule DatastarDemo.Pages.Signals do
  use Nex

  def mount(_params) do
    %{title: "Lesson 2: Reactive Signals"}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-8 max-w-3xl mx-auto">
      <h2 class="text-3xl font-bold text-gray-800 mb-4">Lesson 2: Reactive Signals</h2>
      <p class="text-gray-600 mb-6">Frontend reactivity with data attributes and signals</p>

      <div class="mb-8 p-6 border-2 border-green-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 1: data-signals and data-text</h3>
        <p class="text-sm text-gray-600 mb-4">Define signals and display their values</p>

        <div data-signals="{count: 0}" class="text-center">
          <div class="text-5xl font-bold text-green-600 mb-4" data-text="$count"></div>
          <div class="flex gap-2 justify-center">
            <button data-on:click="$count--" class="px-4 py-2 bg-red-500 text-white rounded">-</button>
            <button data-on:click="$count = 0" class="px-4 py-2 bg-gray-500 text-white rounded">Reset</button>
            <button data-on:click="$count++" class="px-4 py-2 bg-green-500 text-white rounded">+</button>
          </div>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-green-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 2: data-bind</h3>
        <p class="text-sm text-gray-600 mb-4">Two-way binding between input and signal</p>

        <div data-signals="{name: ''}" class="space-y-4">
          <input type="text" data-bind:name placeholder="Enter your name" class="w-full px-4 py-2 border rounded"/>
          <div class="text-lg font-semibold" data-text="'Hello ' + ($name || 'Guest') + '!'"></div>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-green-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 3: data-show</h3>
        <p class="text-sm text-gray-600 mb-4">Conditionally show or hide elements</p>

        <div data-signals="{showDetails: false}" class="space-y-4">
          <button data-on:click="$showDetails = !$showDetails" class="px-4 py-2 bg-blue-500 text-white rounded">
            Toggle Details
          </button>
          <div data-show="$showDetails" class="p-4 bg-blue-50 rounded">
            <p>These details are shown when showDetails is true</p>
          </div>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-green-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 4: data-class</h3>
        <p class="text-sm text-gray-600 mb-4">Dynamically add or remove CSS classes</p>

        <div data-signals="{isActive: false}" class="space-y-4">
          <button data-on:click="$isActive = !$isActive" class="px-4 py-2 bg-purple-500 text-white rounded">
            Toggle Active
          </button>
          <div data-class="{'bg-green-200 border-2 border-green-500': $isActive, 'bg-gray-100': !$isActive}" class="p-4 rounded transition-colors">
            This box changes color when active
          </div>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-green-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 5: data-attr</h3>
        <p class="text-sm text-gray-600 mb-4">Bind HTML attributes to signals</p>

        <div data-signals="{isDisabled: false}" class="space-y-4">
          <button data-on:click="$isDisabled = !$isDisabled" class="px-4 py-2 bg-orange-500 text-white rounded cursor-pointer hover:bg-orange-600">
            Toggle Button State
          </button>
          <div class="p-3 bg-gray-50 rounded text-sm">
            <p data-text="$isDisabled ? 'Button is DISABLED (cannot click)' : 'Button is ENABLED (can click)'"></p>
          </div>
          <button data-attr="{disabled: $isDisabled}" data-class="{'opacity-50 cursor-not-allowed': $isDisabled, 'opacity-100 cursor-pointer hover:bg-blue-600': !$isDisabled}" class="px-4 py-2 bg-blue-500 text-white rounded transition-all">
            Click me (may be disabled)
          </button>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-green-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 6: data-computed</h3>
        <p class="text-sm text-gray-600 mb-4">Derived signals that update automatically</p>

        <div data-signals="{firstName: 'John', lastName: 'Doe'}" class="space-y-4">
          <div class="space-y-2">
            <input type="text" data-on:input="$firstName = event.target.value" placeholder="First name" class="w-full px-4 py-2 border rounded"/>
            <input type="text" data-on:input="$lastName = event.target.value" placeholder="Last name" class="w-full px-4 py-2 border rounded"/>
          </div>
          <div class="p-3 bg-blue-50 rounded">
            <p class="text-sm text-gray-600 mb-2">Full name (computed):</p>
            <p class="text-lg font-semibold" data-text="$firstName + ' ' + $lastName"></p>
          </div>
        </div>
      </div>

      <div class="p-6 bg-gradient-to-r from-green-50 to-blue-50 rounded-lg">
        <h3 class="text-xl font-bold text-gray-800 mb-3">Summary</h3>
        <ul class="space-y-2 text-sm text-gray-700">
          <li>data-signals: Define reactive state</li>
          <li>data-text: Display signal values</li>
          <li>data-bind: Two-way input binding</li>
          <li>data-show: Conditional visibility</li>
          <li>data-class: Dynamic CSS classes</li>
          <li>data-attr: Bind HTML attributes</li>
          <li>data-computed: Derived reactive values</li>
        </ul>
      </div>
    </div>
    """
  end
end
