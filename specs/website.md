# Build Official Website

Carefully read the code of this framework, then refer to the design style of https://www.phoenixframework.org/, and build an official website using this framework.

First understand this requirement, then write an implementation plan in English for me to review. Write to specs/<number>-tech.md

# Railway Deployment ✅

Refer to Railway's documentation and deploy the website to Railway.

Already configured:
- `website/railway.json` - Railway deployment configuration
- `specs/deploy-railway.md` - Deployment documentation

Deployment commands:
- Build: `mix do deps.get, compile`
- Start: `mix nex.start` (automatically reads PORT environment variable, defaults to 4000)