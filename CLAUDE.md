# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a monorepo for the **Nex** web framework with these main components:

- `framework/` - Core framework package (`nex_core`) published to Hex.pm
- `installer/` - Project generator package (`nex_new`) published as a Mix archive
- `website/` - Official documentation website (built with Nex itself)
- `examples/` - Example projects demonstrating framework features

# Principle 1
Every modification to the framework code must be recorded in the changelog to facilitate future framework version releases.

I will give you instructions when it's time to upgrade versions. You will determine whether a version upgrade is needed based on the changelog. If an upgrade is needed, update the version number and then update the changelog.

# Principle 2

When creating example projects, such as those in website or examples, if you determine that we need to modify the framework code to support them, please let me know. I will evaluate whether to make those changes.

# Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):
- **Format**: `<type>(<scope>): <subject>`
- **Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- **Scopes**: `framework`, `website`, `installer`, `examples`, `core`
- **Rules**:
  - No triple backticks (```) in the message.
  - Subject line should be 50 characters or less.
  - Body lines (if any) should be 72 characters or less.
  - Use imperative mood in the subject (e.g., "add feature" instead of "added feature").
