# CLAUDE.md for BestofEx

This project uses the Nex framework. Refer to `AGENTS.md` for core architectural principles.

## Key Patterns
- **Actions**: Public functions in a Page module called by HTMX.
- **State**: `Nex.Store` for per-session page state.
- **UI**: Tailwind CSS + DaisyUI.

Always prioritize code locality and declarative interaction.
