# Page ID 传输优化

## 问题背景

在之前的实现中，`page_id` 通过 HTMX 的 `hx-vals` 属性在请求 payload 中传输：

```javascript
document.body.setAttribute('hx-vals', JSON.stringify({_page_id: "abc123"}));
```

这导致了以下问题：
1. **隐私泄露**：`page_id` 在浏览器开发工具的 Network 面板中可见
2. **安全风险**：用户可以轻易篡改或复制 `page_id`
3. **调试干扰**：每个请求的 payload 都包含额外的 `_page_id` 字段

## 优化方案

### 使用 HTTP Header 传输

将 `page_id` 从请求 payload 移到 HTTP Header (`X-Nex-Page-Id`)：

```javascript
// 存储在 data attribute 中
document.body.dataset.pageId = "abc123";

// 通过 HTMX 事件拦截器添加到 header
document.body.addEventListener('htmx:configRequest', function(evt) {
  evt.detail.headers['X-Nex-Page-Id'] = document.body.dataset.pageId;
});
```

### 服务端处理

新增辅助函数优先从 header 读取，向后兼容 payload：

```elixir
defp get_page_id_from_request(conn) do
  case get_req_header(conn, "x-nex-page-id") do
    [page_id | _] when is_binary(page_id) and page_id != "" -> page_id
    _ -> conn.params["_page_id"] || "unknown"  # 向后兼容
  end
end
```

## 优势

### 1. 隐私保护
- Header 在浏览器开发工具中不如 payload 显眼
- 减少了敏感信息的暴露面

### 2. 符合 HTTP 规范
- 元数据应该放在 header 中，而非 body
- 与 `X-Request-ID`、`X-Session-ID` 等标准实践一致

### 3. 向后兼容
- 保留了从 `params["_page_id"]` 读取的逻辑
- 现有应用无需修改即可工作

### 4. 清晰的请求 payload
- POST/PUT 请求的 payload 只包含业务数据
- 便于调试和日志分析

## 浏览器兼容性

- ✅ 所有现代浏览器支持 `dataset` API
- ✅ HTMX 1.0+ 支持 `htmx:configRequest` 事件
- ✅ 无需额外的 polyfill

## 迁移指南

### 对于新项目
无需任何操作，框架自动使用 header 传输。

### 对于现有项目
1. 更新框架到最新版本
2. 刷新浏览器页面（自动切换到新方式）
3. 旧的 payload 方式仍然有效（向后兼容）

### 自定义 HTMX 请求
如果你有手动发起的 HTMX 请求，确保包含 header：

```html
<button hx-post="/action" 
        hx-headers='{"X-Nex-Page-Id": "your-page-id"}'>
  Action
</button>
```

或者使用全局配置：

```javascript
htmx.on('htmx:configRequest', function(evt) {
  evt.detail.headers['X-Nex-Page-Id'] = document.body.dataset.pageId;
});
```

## 安全考虑

虽然 header 比 payload 更隐蔽，但 `page_id` 仍然是客户端可见的。如果需要更高的安全性：

1. **使用签名**：在服务端对 `page_id` 进行 HMAC 签名
2. **短期有效**：为 `page_id` 设置较短的 TTL（当前默认 1 小时）
3. **IP 绑定**：将 `page_id` 与客户端 IP 关联
4. **HTTPS**：生产环境必须使用 HTTPS

## 性能影响

- ✅ **无性能损失**：header 传输与 payload 传输开销相同
- ✅ **减少 payload 大小**：每个请求减少约 20-30 字节
- ✅ **更好的缓存**：header 不影响 POST 请求的 body hash

## 相关文件

- `framework/lib/nex/handler.ex` - 主要实现
- `CHANGELOG.md` - 变更记录
- `nex-framework-technical-review.md` - 技术评审报告

## 参考资料

- [HTMX Events](https://htmx.org/events/)
- [HTTP Headers Best Practices](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers)
- [Web Security Guidelines](https://owasp.org/www-project-web-security-testing-guide/)
