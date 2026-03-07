# Contributing to Nex

Thanks for your interest in contributing to Nex.

## Scope

This repository contains two product lines:

- `Nex` — the main product line, including the web framework, installer, environment helper, database layer, examples, website, and showcases
- `nex_agent` — a separate product line with its own positioning and usage narrative

When opening an issue or pull request, make it clear which product line you are targeting.

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

### For documentation changes

Please keep messaging consistent with the repository positioning:

- `Nex` should be described as the main product
- `nex_agent` should be described as a separate product line
- Avoid mixing both narratives in the same intro section unless the relationship is explicitly explained

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

- Product line: `Nex` or `nex_agent`
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
- Whether the request is for `Nex`, `nex_agent`, or both

## Security

Do not open public issues for security vulnerabilities.

Please follow the private disclosure process in `SECURITY.md`.
