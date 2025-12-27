defmodule Nex.Partial do
  @moduledoc """
  Partial module for reusable UI components.
  
  Partials have NO HTTP routes - they are pure components
  that can be imported and used in Pages.
  
  ## Usage
  
      # src/partials/todos/item.ex
      defmodule MyApp.Partials.Todos.Item do
        use Nex.Partial
        
        def todo_item(assigns) do
          ~H\"\"\"
          <li id={"todo-\#{@todo.id}"}>
            {@todo.text}
          </li>
          \"\"\"
        end
      end
      
      # In a Page:
      alias MyApp.Partials.Todos.Item
      <Item.todo_item todo={todo} />
  """

  defmacro __using__(_opts) do
    quote do
      import Phoenix.Component, only: [sigil_H: 2]
    end
  end
end
