# Version Management

Nex adopts a **fully synchronized versioning strategy**.

## Strategy

All core packages **always use the same version number**.

Even if only one package is modified, all packages will upgrade their version numbers and be released simultaneously.

## Packages

| Package | Directory | Hex Name | Current Version |
|--------|-----------|----------|-----------------|
| nex_core | framework/ | nex_core | 0.3.9 |
| nex_env | nex_env/ | nex_env | 0.3.9 |
| nex_base | nex_base/ | nex_base | 0.3.9 |
| nex_agent | nex_agent/ | nex_agent | 0.3.9 |
| nex_new | installer/ | nex_new | 0.3.9 |

## Version Number Locations

- `/VERSION` - Master version number (shared by all packages)
- `/framework/VERSION` - Framework version (synchronized)
- `/nex_env/VERSION` - Environment version (synchronized)
- `/nex_base/VERSION` - Database version (synchronized)
- `/nex_agent/VERSION` - Agent version (synchronized)
- `/installer/VERSION` - Installer version (synchronized)
- `/framework/mix.exs` - nex_core package version
- `/nex_env/mix.exs` - nex_env package version
- `/nex_base/mix.exs` - nex_base package version
- `/nex_agent/mix.exs` - nex_agent package version
- `/installer/mix.exs` - nex_new package version

## Release Process

1. Update `/VERSION` file to new version (e.g., 0.4.0)
2. Update CHANGELOG.md with changes
3. Run `./scripts/publish_hex.sh` - Automatically synchronize and publish all packages

## Non-Released Projects

These projects are **not released to Hex** and are for development/demo purposes:

- `/examples/*/` - Example applications
- `/showcase/*/` - Showcase applications
- `/website/` - Official documentation website

These use Hex dependencies pointing to released packages.

## Why Choose Synchronized Versioning?

**Advantages**:
- Simple and clear, version numbers are always consistent
- Easy for users to understand (nex v0.4.0 = all packages v0.4.0)
- Reduces cognitive burden of version management
- Users don't need to track which package has what version

**Disadvantages**:
- There will be some "empty versions" (a package with no actual changes)
- Release frequency may be slightly higher

We believe the value of simplicity outweighs the disadvantages.
