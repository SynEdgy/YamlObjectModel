# Changelog for YamlObjectModel

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
