# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-07-19

### Added

- Initial release of SpecyDocs, a mountable Rails engine for API docs from RSpec captures
- Capture request/response examples from RSpec request specs via `SpecyDocs::Capturable`
- `SpecyDocs.setup_rspec` helper for include filters that follow configuration
- Opt-in (`specy: true`) and opt-out (`specy: false`) capture modes
- Optional `capture_paths` for legacy controller specs without `type: :request`
- Report generation via `bin/rails specy_docs:report`
- Mountable browsable docs UI
- Configurable title, eyebrow, paths, and masked header keys
- Support for API-only Rails apps (`config.api_only = true`)

[0.1.0]: https://github.com/thabotitus/specy_docs/releases/tag/v0.1.0
