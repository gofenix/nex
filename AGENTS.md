# AI Agent Handbook & Principles

## 1. Core Principles

### Principle 1: Changelog First
Every modification to the framework code must be recorded in the changelog to facilitate future framework version releases. 
Check the changelog before and after any modification.

### Principle 2: Framework Modification Policy
When creating example projects (in `website/` or `examples/`), if you determine that we need to modify the framework code to support them, please let me know. I will evaluate whether to make those changes.

### Principle 3: Upgrade Verification
When upgrading the framework:
1. Ensure the changelog is actually updated.
2. Ensure the version number is correctly bumped.
3. Ensure the installer code (`installer/`) is updated to reflect the change.

---

## 2. Project Context

### Project Structure
- `framework/`: Core package (`nex_core`)
- `installer/`: Project generator (`nex_new`)
- `website/`: Official documentation site
- `examples/`: Example projects

### Commit Message Convention
Follow [Conventional Commits](https://www.conventionalcommits.org/):
- **Format**: `<type>(<scope>): <subject>`
- **Strict Rule**: **NO triple backticks (```)** in the commit message.
- Subject: ≤ 50 chars, imperative mood.

### Developer Experience (DX)
- **Zero Boilerplate**: Nex handles CSRF automatically. Do NOT manually add CSRF input tags or headers unless specifically requested.
- **Convention over Configuration**: File paths are routes. Modules use a unified `use Nex` interface.
