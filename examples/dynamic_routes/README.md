# 动态路由示例

这个示例展示了 Nex 框架的动态路由功能，包括：

## 路由类型

### 1. 单参数动态路由
```
src/pages/users/[id].ex
匹配: /users/123, /users/456
参数: %{"id" => "123"}
```

### 2. 嵌套动态路由
```
src/pages/users/[id]/profile.ex
匹配: /users/123/profile
参数: %{"id" => "123"}
```

### 3. 多参数动态路由
```
src/pages/posts/[year]/[month].ex
匹配: /posts/2024/12
参数: %{"year" => "2024", "month" => "12"}
```

### 4. Slug 路由
```
src/pages/posts/[slug].ex
匹配: /posts/hello-world, /posts/my-first-post
参数: %{"slug" => "hello-world"}
```

### 5. 通配符路由
```
src/pages/docs/[...path].ex
匹配: /docs/* (任意层级)
参数: %{"path" => ["getting-started", "install"]}
```

### 6. 混合路由
```
src/pages/files/[category]/[...path].ex
匹配: /files/images/2024/12/photo.jpg
参数: %{"category" => "images", "path" => ["2024", "12", "photo.jpg"]}
```

### 7. API 动态路由
```
src/api/users/[id].ex
匹配: GET /api/users/123
参数: %{"id" => "123"}
```

## 运行示例

```bash
cd examples/dynamic_routes
mix deps.get
mix nex.dev
```

然后访问 http://localhost:4000

## 路由规则

1. **文件名约定**：
   - `[param]` - 单个动态参数
   - `[...path]` - 通配符参数（匹配剩余路径）

2. **参数提取**：
   - 方括号内的名称会成为参数键
   - 通配符参数总是返回字符串列表

3. **匹配优先级**：
   - 精确匹配 > 动态匹配
   - 少参数 > 多参数
   - 非通配 > 通配

## 实际应用场景

- **用户系统**: `/users/[id]`, `/users/[id]/posts`
- **博客系统**: `/posts/[slug]`, `/posts/[year]/[month]`
- **文档系统**: `/docs/[...path]`
- **文件管理**: `/files/[category]/[...path]`
- **API 设计**: `/api/[resource]/[id]`

## 注意事项

1. 动态参数总是以字符串形式传递
2. 通配符参数可以匹配空路径（如 `/docs/`）
3. 嵌套路由支持任意层级
4. API 和页面路由使用相同的动态规则
