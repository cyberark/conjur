# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2017-12-07

- Add `authn-local` service which issues access tokens over a Unix domain socket.

## [0.1.1] - 2017-12-04
### Changed
- Build scripts now look at git tags to determine version and tags to use.

### Fixed
- When a policy is loaded which references a non-existant object, that error is now reported as a JSON-formatted 404 error rather than an ugly 500 error.

## 0.1.0 - 2017-12-04

The first tagged version.

[Unreleased]: https://github.com/cyberark/conjur/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/cyberark/conjur/compare/v0.1.0...v0.1.1
