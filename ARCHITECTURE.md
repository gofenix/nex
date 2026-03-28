# Nex Monorepo Architecture

## Root Layout

The Nex repository is a disciplined monorepo with four top-level concerns:

- Published packages: `framework/`, `installer/`, `nex_env/`, `nex_base/`
- First-party apps: `examples/`, `website/`
- Tooling: `scripts/`, `.github/workflows/`
- Isolated internal assets: `internal/`

The root should not accumulate ad-hoc working directories, archived package snapshots, or agent scratch space.

## Examples Gallery

`examples/` is the only public gallery. It contains both:

- `:pattern` examples for focused framework capabilities
- `:app` examples for larger, product-shaped reference apps

The gallery metadata lives in `examples/catalog.exs`. That file is the single source of truth for:

- batch example tests
- compatibility verification
- the website examples section
- the GitHub Actions matrix for example-owned tests

Each retained example owns its own acceptance tests:

- `test/e2e/*_test.exs` for example-specific behavior
- `test/support/` for the thinnest local adapter layer

Shared test helpers live in `examples/test_support/`. The shared layer may provide infrastructure, but it must not own example specs.

## Website

`website/` is a first-party Nex app inside the monorepo. It should:

- depend on local path packages from the same checkout
- read the root `VERSION` instead of hardcoding release strings
- read `examples/catalog.exs` instead of maintaining a duplicate example list

Public documentation and article content belongs under `website/priv/docs/` or `website/priv/content/`.

## Internal Assets

`internal/` is the only allowed home for versioned assets that are not part of the public product surface, such as:

- agent instructions
- editor rule files
- workflow notes
- operational playbooks

Those files should not live under `examples/` or `website/`.

## Structural Guardrails

The repository should not contain:

- `showcase/`
- root `e2e/`
- `.sisyphus/`
- archived package snapshots such as `nex_base-0.x.y/`
- deleted or half-deleted examples such as `examples/agent_demo/`

Run `./scripts/check-structure.sh` to validate the expected structure.
