# Contributing to Nex

Thanks for your interest in contributing to Nex.

## Before You Start

Please read these files first:

- `README.md`
- `AGENTS.md`
- `CONSTITUTION.md`
- `VERSIONING.md`
- `CHANGELOG.md`

## Ground Rules

- Use English for code, comments, docs, commits, and pull requests
- Follow Conventional Commits: `<type>(<scope>): <subject>`
- Keep subjects imperative and 50 characters or fewer
- Do not introduce breaking changes without documentation and a migration path
- Do not add credentials or secrets to the repository
- Prefer small, focused pull requests over broad refactors

## Development Expectations

### For framework or package changes

- Update the changelog before modifying framework behavior
- Keep public API changes clearly documented
- Add or update examples when they improve comprehension
- Preserve backward compatibility where possible

## Pull Request Checklist

Before opening a pull request, make sure you have:

- Explained the problem being solved
- Described the chosen approach and any trade-offs
- Listed how to review or validate the change
- Updated docs if public behavior changed
- Updated the changelog if the change affects framework behavior

## Reporting Bugs

A good bug report includes:

- Package or directory affected
- Expected behavior
- Actual behavior
- Reproduction steps
- Relevant logs, screenshots, or code snippets

## Feature Requests

Please explain:

- The use case
- Why the current behavior is insufficient
- Why the proposed change fits the philosophy of the project
- Whether the request fits the philosophy of the project

## Security

Do not open public issues for security vulnerabilities.

Please follow the private disclosure process in `SECURITY.md`.
