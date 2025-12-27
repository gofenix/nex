# Changelog

All notable changes to the Nex framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **Nex.Env**: Fixed `.env` file loading to correctly resolve project root directory using `Mix.Project.app_path()` instead of relying on current working directory
- **Nex.Env**: Fixed environment variables not being accessible via `System.get_env/1` by explicitly setting loaded variables to system environment after Dotenvy parsing
- **Nex.Env**: Added debug logging to show which `.env` files are being loaded, their paths, and how many variables were loaded
- **Mix.Tasks.Nex.Dev**: Fixed user application not being started, which prevented application supervision trees (like Finch for HTTP clients) from running

### Changed
- **Nex.Env**: Improved `.env` file path resolution to work correctly regardless of where `mix nex.dev` is executed from
- **Nex.Env**: Enhanced error handling to show specific error messages when `.env` file loading fails
