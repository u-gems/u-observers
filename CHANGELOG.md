# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Per the project's stability policy, a major version bump signals only that a
Ruby or Rails version was dropped from the supported matrix — a dependency-floor
change, not a behavior break.

## [Unreleased]

## [3.0.0] - 2026-06-01

### Added

- `notify_observers!` — declare observers on an `ActiveModel`/`ActiveRecord`
  model **at the class level**, so they no longer need to be attached on every
  instance. Takes `event:` (the callback to hook, also the broadcast event
  name), `with:` (the observer(s) to attach), an optional `context:` forwarded
  to those observers, and any extra option (e.g. `on:`) passed straight through
  to the underlying callback.
- `observers_to_notify` — introspect the observers declared via
  `notify_observers!`, keyed by callback.
- `detach_observers_to_notify(*observers, from: nil)` — remove declared
  observers from a callback (or from all of them); with no observers it clears
  the callback entirely.

### Changed

- Raised the supported floor to **Ruby >= 2.7** (was `>= 2.2`) and
  **ActiveRecord/Rails >= 6.0** (was `>= 3.2`).
- Modernized CI/test setup: the suite now runs on Ruby 2.7 through 4.0 + head
  against Rails 6.0 through 8.1 + edge via [Appraisal](https://github.com/thoughtbot/appraisal),
  with a no-`activerecord` baseline run.

## [2.3.0] - 2020-11-25

### Added

- Allow defining observers using blocks (e.g. `after_commit(&notify_observers(:event))`).

## [2.2.1] - 2020-11-18

### Fixed

- `observers.once()` when its callable returns `nil`.

## [2.2.0] - 2020-11-18

### Added

- `Observers::Set#once` and `Observers::Set#off`.
- Allow defining multiple callables for the same event.
- `Observers::Set#include?` (with `included?` kept as an alias).

### Fixed

- Observer deletion when it must be performed only once.
- `Observers::Set#inspect`.

## [2.1.0] - 2020-10-16

### Added

- Allow defining callable observers with a context.
- Portuguese documentation ([`README.pt-BR.md`](https://github.com/u-gems/u-observers/blob/main/README.pt-BR.md)).

## [2.0.0] - 2020-10-06

### Added

- `Micro::Observers::Event` to represent the notification payload.

### Changed

- Renamed `Micro::Observers::Manager` to `Micro::Observers::Set`.
- Transformed `Micro::Observers::Events` into `Micro::Observers::Event::Names`.
- `subject_changed` methods now return booleans.

## [1.0.0] - 2020-10-05

### Added

- `Micro::Observers::For::ActiveModel` and `Micro::Observers::For::ActiveRecord`
  integrations (`notify_observers_on`, `notify_observers`).
- `call!` and `notify!` to broadcast even when the subject hasn't been changed.
- `Micro::Observers::Manager#inspect`.

## [0.9.0] - 2020-09-29

### Added

- CI running against multiple Ruby and ActiveRecord versions.

### Changed

- Added `subject_changed` to ensure idempotency of notifications.

### Removed

- The concept of "actions".

## [0.8.0] - 2020-09-28

### Changed

- Resolve a callable observer's argument only when the observer is executed.

## [0.7.0] - 2020-09-26

### Added

- Attach and detach multiple observers at once.

## [0.6.0] - 2020-09-26

### Changed

- Optimized `Micro::Observers::Manager#notify` and `#call`.

## [0.5.0] - 2020-09-26

### Changed

- Normalized the class and instance methods.

## [0.4.0] - 2020-09-25

### Added

- Notify events and call actions.

## [0.3.0] - 2020-09-25

### Added

- `Micro::Observers#on`.

## [0.2.0] - 2020-09-25

### Changed

- `Micro::Observers::Manager` receives the subject through its constructor.

## [0.1.0] - 2020-09-25

### Added

- Initial release — the `Micro::Observers` implementation of the observer pattern.

[Unreleased]: https://github.com/u-gems/u-observers/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/u-gems/u-observers/compare/v2.3.0...v3.0.0
[2.3.0]: https://github.com/u-gems/u-observers/compare/v2.2.1...v2.3.0
[2.2.1]: https://github.com/u-gems/u-observers/compare/v2.2.0...v2.2.1
[2.2.0]: https://github.com/u-gems/u-observers/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/u-gems/u-observers/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/u-gems/u-observers/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/u-gems/u-observers/compare/v0.9.0...v1.0.0
[0.9.0]: https://github.com/u-gems/u-observers/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/u-gems/u-observers/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/u-gems/u-observers/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/u-gems/u-observers/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/u-gems/u-observers/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/u-gems/u-observers/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/u-gems/u-observers/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/u-gems/u-observers/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/u-gems/u-observers/releases/tag/v0.1.0
