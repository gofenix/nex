defmodule DatastarDemo.Pages.Expressions do
  use Nex

  def mount(_params) do
    %{title: "Lesson 3: Datastar Expressions"}
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-8 max-w-3xl mx-auto">
      <h2 class="text-3xl font-bold text-gray-800 mb-4">Lesson 3: Datastar Expressions</h2>
      <p class="text-gray-600 mb-6">Using JavaScript expressions in Datastar</p>

      <div class="mb-8 p-6 border-2 border-purple-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 1: Basic Expressions</h3>
        <p class="text-sm text-gray-600 mb-4">Use JavaScript expressions in data attributes</p>

        <div data-signals="{x: 5, y: 3}" class="space-y-4">
          <div class="text-2xl font-bold" data-text="$x + $y"></div>
          <div class="text-lg" data-text="$x * $y"></div>
          <div class="text-lg" data-text="$x > $y ? 'X is greater' : 'Y is greater'"></div>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-purple-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 2: String Operations</h3>
        <p class="text-sm text-gray-600 mb-4">Manipulate strings with JavaScript methods</p>

        <div data-signals="{text: 'hello world'}" class="space-y-4">
          <input type="text" data-bind:text placeholder="Enter text" class="w-full px-4 py-2 border rounded"/>
          <div class="text-lg" data-text="$text.toUpperCase()"></div>
          <div class="text-lg" data-text="$text.length"></div>
          <div class="text-lg" data-text="$text.split(' ').length"></div>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-purple-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 3: Array Operations</h3>
        <p class="text-sm text-gray-600 mb-4">Work with arrays in expressions</p>

        <div data-signals="{items: ['apple', 'banana', 'cherry']}" class="space-y-4">
          <div class="text-lg" data-text="$items.length"></div>
          <div class="text-lg" data-text="$items.join(', ')"></div>
          <div class="text-lg" data-text="$items[0]"></div>
          <button data-on:click="$items.push('date')" class="px-4 py-2 bg-purple-500 text-white rounded">
            Add Item
          </button>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-purple-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 4: Object Operations</h3>
        <p class="text-sm text-gray-600 mb-4">Access object properties in expressions</p>

        <div data-signals="{user: {name: 'John', age: 30, email: 'john@example.com'}}" class="space-y-4">
          <div class="text-lg" data-text="$user.name"></div>
          <div class="text-lg" data-text="$user.age"></div>
          <div class="text-lg" data-text="$user.name + ' is ' + $user.age + ' years old'"></div>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-purple-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 5: Logical Expressions</h3>
        <p class="text-sm text-gray-600 mb-4">Use logical operators in conditions</p>

        <div data-signals="{age: 25, hasLicense: true}" class="space-y-4">
          <div class="flex gap-2 mb-4">
            <input type="number" data-bind:age placeholder="Age" class="px-4 py-2 border rounded w-32"/>
            <label class="flex items-center gap-2">
              <input type="checkbox" data-bind:hasLicense/>
              Has License
            </label>
          </div>
          <div data-show="$age >= 18 && $hasLicense" class="p-4 bg-green-50 rounded">
            You can drive!
          </div>
          <div data-show="$age < 18" class="p-4 bg-yellow-50 rounded">
            You are too young to drive
          </div>
          <div data-show="$age >= 18 && !$hasLicense" class="p-4 bg-red-50 rounded">
            You need a license to drive
          </div>
        </div>
      </div>

      <div class="mb-8 p-6 border-2 border-purple-200 rounded-lg">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">Example 6: Template Literals</h3>
        <p class="text-sm text-gray-600 mb-4">Use template literals for complex strings</p>

        <div data-signals="{firstName: 'John', lastName: 'Doe', year: 2024}" class="space-y-4">
          <input type="text" data-bind:firstName placeholder="First name" class="w-full px-4 py-2 border rounded mb-2"/>
          <input type="text" data-bind:lastName placeholder="Last name" class="w-full px-4 py-2 border rounded"/>
          <div class="text-lg font-semibold" data-text="`${$firstName} ${$lastName} - ${$year}`"></div>
        </div>
      </div>

      <div class="p-6 bg-gradient-to-r from-purple-50 to-blue-50 rounded-lg">
        <h3 class="text-xl font-bold text-gray-800 mb-3">Summary</h3>
        <ul class="space-y-2 text-sm text-gray-700">
          <li>Expressions use standard JavaScript syntax</li>
          <li>Access signals with $ prefix</li>
          <li>Use operators: +, -, *, /, %, &&, ||, !</li>
          <li>Use methods: toUpperCase(), length, split(), join()</li>
          <li>Use ternary operator: condition ? true : false</li>
          <li>Use template literals for complex strings</li>
          <li>All expressions are reactive and update automatically</li>
        </ul>
      </div>
    </div>
    """
  end
end
