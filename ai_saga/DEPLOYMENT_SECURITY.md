# AI Saga 安全部署说明

## 生成功能改造

为了防止 OpenAI API 费用被滥用，生成功能已改为**定时脚本**，不再对外提供公开访问。

## GitHub Actions 定时执行

### 配置 Secrets

在 GitHub 仓库 Settings → Secrets and variables → Actions 中添加：

1. **FLY_API_TOKEN**
   ```bash
   # 本地运行获取 token
   flyctl auth token
   ```

2. **DATABASE_URL**
   ```
   你的 Supabase PostgreSQL 连接字符串
   ```

3. **OPENAI_API_KEY**
   ```
   sk-...
   ```

4. **HF_TOKEN**
   ```
   hf_...
   ```

### 手动触发测试

1. 前往 GitHub 仓库 → Actions
2. 选择 "Daily AI Paper Generation"
3. 点击 "Run workflow"
4. 等待执行完成（约 2-3 分钟）
5. 检查网站是否有新论文

### 执行时间

- **自动执行**：每天 UTC 02:00（北京时间 10:00）
- **手动触发**：随时在 GitHub Actions 页面手动运行

## 成本估算

- Fly.io 临时机器：约 $0.009/次
- OpenAI API：约 $0.07/次
- **每月总计**：约 $2.37（30 天 × $0.079）

## 本地测试

```bash
cd ai_saga

# 测试 Mix Task（需要配置 .env）
mix ai_saga.generate_daily
```

## 故障排查

### 问题：GitHub Actions 执行失败

检查：
1. Secrets 是否正确配置
2. Fly.io API token 是否有效
3. 数据库连接字符串是否正确
4. Docker 镜像是否存在（`registry.fly.io/ai_saga:latest`）

解决：
```bash
# 确保主应用已部署（生成 Docker 镜像）
fly deploy
```

### 问题：执行超时

增加 workflow 中的超时时间：
```yaml
timeout-minutes: 20  # 默认 15 分钟
```

## 安全状态

- ✅ 公开访问已完全移除
- ✅ 成本完全可控（每月固定约 $2.37）
- ✅ 仅 GitHub Actions 可触发
- ✅ API keys 通过 GitHub Secrets 安全管理
