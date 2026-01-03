# File Upload Example

完整的文件上传应用，展示 Nex 对 Multipart/form-data 的零配置原生支持。

## 功能特性

- ✅ **文件上传** - 支持任何文件类型
- ✅ **描述信息** - 为每个文件添加可选描述
- ✅ **文件管理** - 单个删除或批量清空
- ✅ **文件保存** - 上传的文件保存到 `uploads/` 目录
- ✅ **文件大小显示** - 自动格式化文件大小（B/KB/MB）
- ✅ **HTMX 交互** - 无刷新上传和删除

## 学习要点

### 1. Multipart 零配置支持

Nex 框架默认配置了 `Plug.Parsers`，包括 `:multipart` 支持。无需任何额外配置：

```elixir
# Router.ex 中已经包含
plug Plug.Parsers,
  parsers: [:urlencoded, :multipart, :json],
  pass: ["*/*"],
  json_decoder: Jason
```

### 2. 处理 Plug.Upload 对象

当用户上传文件时，Nex 自动将其转换为 `Plug.Upload` 结构体：

```elixir
def upload(%{"file" => %Plug.Upload{filename: filename, path: temp_path}}) do
  # filename: 原始文件名（用户上传时的名称）
  # path: 临时文件路径（Plug 自动创建的临时文件）
  
  # 将临时文件复制到永久位置
  File.cp!(temp_path, final_path)
  
  # 保存文件信息到状态
  Nex.Store.update(:uploaded_files, [], &[file_info | &1])
  
  # 返回 HTML 片段显示在列表中
  ~H"<.file_item file={@file_info} />"
end
```

### 3. 文件处理最佳实践

```elixir
# 生成安全的文件名（避免覆盖）
file_id = System.unique_integer([:positive])
ext = Path.extname(filename)
safe_filename = "file_#{file_id}#{ext}"

# 确保目录存在
File.mkdir_p!("uploads")

# 复制文件到永久位置
File.cp!(temp_path, final_path)

# 获取文件信息
stat = File.stat!(final_path)
size = stat.size
```

### 4. 删除文件

```elixir
def delete_file(%{"id" => id}) do
  Nex.Store.update(:uploaded_files, [], fn files ->
    Enum.reject(files, fn file ->
      if file.id == id do
        # 从磁盘删除实际文件
        File.rm(file.path)
        true
      else
        false
      end
    end)
  end)
  
  :empty  # 不更新 DOM，HTMX 会自动移除元素
end
```

### 5. HTML 表单配置

```html
<!-- enctype="multipart/form-data" 是必需的 -->
<form hx-post="/upload"
      enctype="multipart/form-data"
      hx-target="#file-list"
      hx-swap="beforeend">
  <input type="file" name="file" required />
  <input type="text" name="description" />
  <button type="submit">Upload</button>
</form>
```

## 运行

```bash
cd examples/file_upload
mix deps.get
mix phx.server
```

访问 http://localhost:4000

## 文件结构

```
file_upload/
├── src/
│   ├── pages/
│   │   └── index.ex          # 上传表单和文件列表
│   ├── components/
│   │   └── file/
│   │       └── item.ex       # 文件项组件
│   └── layouts.ex            # 全局布局
├── uploads/                  # 上传的文件保存位置
├── mix.exs
└── README.md
```

## 关键概念

| 概念 | 说明 |
|-----|-----|
| **Multipart 零配置** | Nex 自动处理 multipart/form-data，无需额外配置 |
| **Plug.Upload** | 上传的文件自动转换为 Plug.Upload 结构体 |
| **临时文件** | Plug 创建临时文件，需要手动复制到永久位置 |
| **文件安全** | 生成唯一文件名避免覆盖，防止目录遍历攻击 |
| **HTMX 集成** | 使用 HTMX 实现无刷新上传和删除 |

## 扩展思考

1. **文件验证**：如何验证文件类型和大小？
2. **异步处理**：如何使用 Task 异步处理大文件？
3. **进度显示**：如何显示上传进度？
4. **云存储**：如何将文件上传到 S3 或其他云服务？
5. **访问控制**：如何限制文件访问权限？

---

**这个示例展示了 Nex 对 Multipart 的完整支持，是教程 03 的最佳实践。**
