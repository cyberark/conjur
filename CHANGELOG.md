# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2018-01-11
### Added
- `conjurctl wait` command is added that can be used to check if the Conjur server is ready

### Removed
- Moved Conjur docs to a [separate repo](https://github.com/cyberark/conjur-org)

## [0.2.0] - 2017-12-07
### Added
- Add `authn-local` service which issues access tokens over a Unix domain socket.

### Fixed
- Resolved bug: Policy replace can fail when user is deleted and removed from group

### Changed
- CTA was updated

## [0.1.1] - 2017-12-04
### Changed
- Build scripts now look at git tags to determine version and tags to use.

### Fixed
- When a policy is loaded which references a non-existant object, that error is now reported as a JSON-formatted 404 error rather than an ugly 500 error.

## 0.1.0 - 2017-12-04

The first tagged version.

[Unreleased]: https://github.com/cyberark/conjur/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/cyberark/conjur/compare/v0.1.0...v0.1.1
[0.2.0]: https://github.com/cyberark/conjur/compare/v0.1.1...v0.2.0
[0.3.0]: https://github.com/cyberark/conjur/compare/v0.2.0...v0.3.0
