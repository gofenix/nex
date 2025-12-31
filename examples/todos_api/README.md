# Todos API - RESTful JSON API Example

**100% aligned with Next.js API Routes**

This example demonstrates a complete RESTful JSON API built with Nex, showcasing perfect alignment with Next.js serverless functions.

## 🎯 What This Example Shows

- ✅ Complete RESTful CRUD operations (GET, POST, PUT, DELETE)
- ✅ Next.js-style request handling (`req.query`, `req.body`)
- ✅ Next.js-style response helpers (`Nex.json`, `Nex.status`)
- ✅ Dynamic route parameters (`/api/todos/[id]`)
- ✅ Query string filtering and pagination
- ✅ Proper HTTP status codes (200, 201, 204, 400, 404)
- ✅ Error handling and validation

## 📊 Next.js API Routes Comparison

| Feature | Next.js | Nex | Status |
|---------|---------|-----|--------|
| Request query | `req.query.id` | `req.query["id"]` | ✅ 100% aligned |
| Request body | `req.body.text` | `req.body["text"]` | ✅ 100% aligned |
| JSON response | `res.json({data})` | `Nex.json(%{data: ...})` | ✅ 100% aligned |
| Status code | `res.status(201)` | `Nex.json(..., status: 201)` | ✅ 100% aligned |
| Dynamic routes | `/api/users/[id]` | `/api/users/[id]` | ✅ 100% aligned |

## 🚀 API Endpoints

### Collection Endpoints

**GET /api/todos** - List all todos
```bash
curl "http://localhost:4000/api/todos?completed=false&limit=10"
```

**POST /api/todos** - Create a new todo
```bash
curl -X POST http://localhost:4000/api/todos \
  -H "Content-Type: application/json" \
  -d '{"text": "Buy groceries"}'
```

### Resource Endpoints

**GET /api/todos/[id]** - Get a specific todo
```bash
curl http://localhost:4000/api/todos/123
```

**PUT /api/todos/[id]** - Update a todo
```bash
curl -X PUT http://localhost:4000/api/todos/123 \
  -H "Content-Type: application/json" \
  -d '{"completed": true}'
```

**DELETE /api/todos/[id]** - Delete a todo
```bash
curl -X DELETE http://localhost:4000/api/todos/123
```

## 💡 Code Examples

### Next.js vs Nex - Side by Side

**Next.js** (`pages/api/todos/index.js`):
```javascript
export default function handler(req, res) {
  const { completed, limit } = req.query
  const todos = getTodos({ completed, limit })
  res.json({ data: todos })
}
```

**Nex** (`src/api/todos/index.ex`):
```elixir
def get(req) do
  completed = req.query["completed"]
  limit = req.query["limit"]
  todos = get_todos(completed, limit)
  Nex.json(%{data: todos})
end
```

### Creating a Resource

**Next.js**:
```javascript
export default function handler(req, res) {
  const { text } = req.body
  const todo = createTodo(text)
  res.status(201).json({ data: todo })
}
```

**Nex**:
```elixir
def post(req) do
  text = req.body["text"]
  todo = create_todo(text)
  Nex.json(%{data: todo}, status: 201)
end
```

### Dynamic Routes

**Next.js** (`pages/api/todos/[id].js`):
```javascript
export default function handler(req, res) {
  const { id } = req.query  // From [id]
  const todo = findTodo(id)
  res.json({ data: todo })
}
```

**Nex** (`src/api/todos/[id].ex`):
```elixir
def get(req) do
  id = req.query["id"]  # From [id]
  todo = find_todo(id)
  Nex.json(%{data: todo})
end
```

## 📁 Project Structure

```
src/
├── api/
│   └── todos/
│       ├── index.ex       # GET /api/todos, POST /api/todos
│       └── [id].ex        # GET/PUT/DELETE /api/todos/[id]
├── pages/
│   └── index.ex           # API documentation page
├── application.ex         # App configuration
└── layouts.ex             # Layout template
```

## 🏃 Running the Example

```bash
cd examples/todos_api
mix deps.get
mix nex.dev
```

Visit http://localhost:4000 to see the interactive API documentation.

## 🔍 Key Features Demonstrated

### 1. Request Handling (100% Next.js Compatible)

```elixir
def get(req) do
  # Path parameters from [id]
  id = req.query["id"]
  
  # Query string parameters
  page = req.query["page"]
  limit = req.query["limit"]
  
  # Request body (POST/PUT)
  text = req.body["text"]
  completed = req.body["completed"]
end
```

### 2. Response Types

```elixir
# JSON response
Nex.json(%{data: todos})

# JSON with custom status
Nex.json(%{data: todo}, status: 201)

# Status only (e.g., DELETE)
Nex.status(204)

# Error response
Nex.json(%{error: "Not found"}, status: 404)
```

### 3. Error Handling

```elixir
def get(req) do
  id = req.query["id"]
  
  case find_todo(id) do
    nil ->
      Nex.json(%{error: "Todo not found"}, status: 404)
    
    todo ->
      Nex.json(%{data: todo})
  end
end
```

### 4. Input Validation

```elixir
def post(req) do
  text = req.body["text"]
  
  cond do
    is_nil(text) or text == "" ->
      Nex.json(%{error: "Text is required"}, status: 400)
    
    true ->
      todo = create_todo(text)
      Nex.json(%{data: todo}, status: 201)
  end
end
```

## 🎓 Learning Resources

This example is perfect for:
- Understanding RESTful API design
- Learning Next.js-style API development in Elixir
- Migrating from Next.js to Nex
- Building production-ready JSON APIs

## 📝 Notes

- All responses are JSON (use `todos` example for HTMX/HTML)
- Follows REST conventions (GET, POST, PUT, DELETE)
- Uses proper HTTP status codes
- 100% compatible with Next.js API Routes patterns

## 🔗 Related Examples

- **`todos`** - HTMX-based todo app (HTML responses)
- **`dynamic_routes`** - Dynamic routing patterns
- **`chatbot_sse`** - Server-Sent Events API
