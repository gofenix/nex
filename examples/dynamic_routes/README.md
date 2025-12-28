# Dynamic Routes Example

This example demonstrates the dynamic routing capabilities of the Nex framework, including:

## Route Types

### 1. Single Parameter Dynamic Routes
```
src/pages/users/[id].ex
Matches: /users/123, /users/456
Params: %{"id" => "123"}
```

### 2. Nested Dynamic Routes
```
src/pages/users/[id]/profile.ex
Matches: /users/123/profile
Params: %{"id" => "123"}
```

### 3. Multi-Parameter Dynamic Routes
```
src/pages/posts/[year]/[month].ex
Matches: /posts/2024/12
Params: %{"year" => "2024", "month" => "12"}
```

### 4. Slug Routes
```
src/pages/posts/[slug].ex
Matches: /posts/hello-world, /posts/my-first-post
Params: %{"slug" => "hello-world"}
```

### 5. Wildcard Routes
```
src/pages/docs/[...path].ex
Matches: /docs/* (any level)
Params: %{"path" => ["getting-started", "install"]}
```

### 6. Mixed Routes
```
src/pages/files/[category]/[...path].ex
Matches: /files/images/2024/12/photo.jpg
Params: %{"category" => "images", "path" => ["2024", "12", "photo.jpg"]}
```

### 7. API Dynamic Routes
```
src/api/users/[id].ex
Matches: GET /api/users/123
Params: %{"id" => "123"}
```

## Running the Example

```bash
cd examples/dynamic_routes
mix deps.get
mix nex.dev
```

Then visit http://localhost:4000

## Routing Rules

1. **File Naming Conventions**:
   - `[param]` - Single dynamic parameter
   - `[...path]` - Wildcard parameter (matches remaining path)

2. **Parameter Extraction**:
   - The name inside brackets becomes the parameter key
   - Wildcard parameters always return a list of strings

3. **Matching Priority**:
   - Exact match > Dynamic match
   - Fewer parameters > More parameters
   - Non-wildcard > Wildcard

## Real-World Use Cases

- **User Systems**: `/users/[id]`, `/users/[id]/posts`
- **Blog Systems**: `/posts/[slug]`, `/posts/[year]/[month]`
- **Documentation Systems**: `/docs/[...path]`
- **File Management**: `/files/[category]/[...path]`
- **API Design**: `/api/[resource]/[id]`

## Notes

1. Dynamic parameters are always passed as strings
2. Wildcard parameters can match empty paths (e.g., `/docs/`)
3. Nested routes support arbitrary levels
4. API and page routes use the same dynamic rules
