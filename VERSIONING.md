# Version Management

Nex adopts a **fully synchronized versioning strategy**.

## Strategy

`nex_core` (framework) and `nex_new` (installer) **always use the same version number**.

Even if only one package is modified, both packages will upgrade their version numbers and be released simultaneously.

## Version Number Locations

- `/VERSION` - Master version number (shared by all packages)
- `/framework/VERSION` - Framework version number (synchronized with master version)
- `/installer/VERSION` - Installer version number (synchronized with master version)
- `/framework/mix.exs` - Framework package version
- `/installer/mix.exs` - Installer package version

## Release Process

1. Update `/VERSION` file
2. Update CHANGELOG (update both packages)
3. Run `./scripts/publish_hex.sh` - Automatically synchronize version numbers and publish all packages

## Why Choose Synchronized Versioning?

**Advantages**:
- Simple and clear, version numbers are always consistent
- Easy for users to understand (nex v0.2.1 = nex_core v0.2.1 + nex_new v0.2.1)
- Reduces cognitive burden of version management

**Disadvantages**:
- There will be some "empty versions" (a package with no actual changes)
- Release frequency may be slightly higher

We believe the value of simplicity outweighs the disadvantages.
