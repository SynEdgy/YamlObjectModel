# Changelog for YamlObjectModel

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added Kubernetes-style `apiVersion`, `kind`, `metadata`, and `spec` YOM resource envelopes, omitting unset optional fields.
- Added typed short-envelope dispatch when a default type is supplied.

### Changed

- Preserved backward-compatible loading of legacy raw specs and `kind`/`spec` definitions.
- Stopped injecting `SavedAtPath` into portable object specifications during file loading.
- Replaced the placeholder README and expanded the conceptual wiki with envelope, dispatch, short-form, nesting, serialization, and compatibility guidance.

### Fixed

- Pinned the Azure Pipelines GitVersion tool to the compatible 5.x release line.

## [0.1.4] - 2022-10-26

### Added

- Base class
- Saveable Base class (supports Save(), LoadFromFile(), Reload() methods).
- YOMApiDispatcher and its DispatchSpec() static method.
- Get-YOMObject to have a function to interact with the static method.
- Added tests.
- Updated pipeline config.
- Adding an example with comments and wiki doc file.
- Cosmetic fixes.

### Changed

- If module is loaded invoke object creation or method in module context.
### Security

- In case of vulnerabilities please report them to contact {at} synedgy.com.
