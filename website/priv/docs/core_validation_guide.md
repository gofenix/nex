# Validation (Nex.Validator)

Nex provides a built-in validation module to validate parameters from user input (like form submissions or API requests) cleanly and efficiently.

The `Nex.Validator` module helps ensure your application receives the correct data types, required fields, and well-formatted data before processing it.

## Basic Usage

The `validate/2` function takes a map of parameters and a keyword list of rules. It returns `{:ok, valid_params}` or `{:error, errors}`.

```elixir
def create_user(req) do
  rules = [
    name: [required: true, type: :string, min: 3],
    age: [required: true, type: :integer, min: 18],
    email: [required: true, type: :string, format: ~r/@/]
  ]

  case Nex.Validator.validate(req.body, rules) do
    {:ok, valid_params} ->
      # valid_params contains casted values (e.g., "18" -> 18)
      # Proceed with creating the user
      Nex.redirect("/users")
      
    {:error, errors} ->
      # errors is a map: %{name: ["is required"], age: ["must be at least 18"]}
      Nex.json(%{error: "Validation failed", details: errors}, status: 400)
  end
end
```

## Available Rules

### Type Casting & Validation

*   **`type: :string`** - Ensures the value is a string.
*   **`type: :integer`** - Casts strings to integers (e.g., `"123"` -> `123`).
*   **`type: :float`** - Casts strings to floats.
*   **`type: :boolean`** - Casts `"true"`, `"1"`, `true` to `true`; `"false"`, `"0"`, `false` to `false`.

### Constraints

*   **`required: true`** - The field must be present and not empty.
*   **`min: number`** - For strings, minimum length. For numbers, minimum value.
*   **`max: number`** - For strings, maximum length. For numbers, maximum value.
*   **`format: regex`** - Value must match the given regular expression.
*   **`in: list`** - Value must be one of the items in the list.

## Custom Validators

You can provide a custom function for validation using the `custom` rule. The function should take the value and return `:ok`, `{:ok, casted_value}`, or `{:error, message}`.

```elixir
rules = [
  username: [
    required: true,
    type: :string,
    custom: fn val -> 
      if String.starts_with?(val, "admin_") do
        {:error, "reserved prefix"}
      else
        :ok
      end
    end
  ]
]
```

## Example: Form Validation with UI Feedback

Here's how you might use `Nex.Validator` in a Page module to handle a form submission and display errors:

```elixir
defmodule MyApp.Pages.Signup do
  use Nex

  def mount(_params) do
    %{errors: %{}, values: %{}}
  end

  def submit(req) do
    rules = [
      email: [required: true, type: :string, format: ~r/^[^\s]+@[^\s]+$/],
      password: [required: true, type: :string, min: 8]
    ]

    case Nex.Validator.validate(req.body, rules) do
      {:ok, params} ->
        # Save user...
        {:redirect, "/dashboard"}

      {:error, errors} ->
        # Re-render the form with errors and submitted values
        render(%{errors: errors, values: req.body})
    end
  end

  def render(assigns) do
    ~H"""
    <form method="post" action="/signup/submit">
      <div>
        <label>Email</label>
        <input type="email" name="email" value={@values["email"]} />
        <span class="error" :if={@errors[:email]}>{Enum.join(@errors[:email], ", ")}</span>
      </div>
      
      <div>
        <label>Password</label>
        <input type="password" name="password" />
        <span class="error" :if={@errors[:password]}>{Enum.join(@errors[:password], ", ")}</span>
      </div>
      
      <button type="submit">Sign Up</button>
    </form>
    """
  end
end
```
