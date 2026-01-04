# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a monorepo for the **Nex** web framework with these main components:

- `framework/` - Core framework package (`nex_core`) published to Hex.pm
- `installer/` - Project generator package (`nex_new`) published as a Mix archive
- `website/` - Official documentation website (built with Nex itself)
- `examples/` - Example projects demonstrating framework features

## AI Agent Principles

**IMPORTANT**: All AI agents must strictly follow the core principles defined in **`AGENTS.md`**. These principles cover:
- Framework modification rules
- Version upgrade procedures
- Changelog management

## Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):
- **Format**: `<type>(<scope>): <subject>`
- **Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- **Scopes**: `framework`, `website`, `installer`, `examples`, `core`
- **Rules**:
  - No triple backticks (```) in the message.
  - Subject line should be 50 characters or less.
  - Body lines (if any) should be 72 characters or less.
  - Use imperative mood in the subject (e.g., "add feature" instead of "added feature").
