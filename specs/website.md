# 构建官网

仔细阅读这个框架的代码，然后参考https://www.phoenixframework.org/的设计风格，通过这个框架来做一个官网。

你首先理解这个需求，然后用中文写一个实施方案让我review。写到 specs/<number>-tech.md

# railway部署 ✅

参考railway的文档，将website部署到railway上。

已配置：
- `website/railway.json` - Railway 部署配置
- `specs/deploy-railway.md` - 部署文档

部署命令：
- Build: `mix do deps.get, compile`
- Start: `mix nex.start` (自动读取 PORT 环境变量，默认为 4000)