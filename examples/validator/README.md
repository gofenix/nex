# Nex.Validator Example

Demonstrates form validation with Nex.Validator from Nex 0.4.

## Features

- Real-time field validation with HTMX
- Validators: `:required`, `:string`, `:email`, `:min`, `:max`, `:format`
- Inline error display
- Form submission validation

## Run

```bash
cd examples/validator
mix deps.get
mix nex.dev
```

Visit http://localhost:4000

## Validation Rules

| Field | Validators |
|-------|-----------|
| Name | required, string |
| Email | required, string, email |
| Age | required, min(0), max(120) |
| Password | required, string, min(6), max(128) |
| Website | format(URL pattern) |

## Code Example

```elixir
Nex.Validator.validate(params, [
  name: [:required, :string],
  email: [:required, :string, :email],
  age: [:required, {:min, 0}, {:max, 120}],
  password: [:required, :string, {:min, 6}],
  website: [{:format, ~r/^(https?:\/\/)?/}]
])
```
