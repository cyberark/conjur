# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.2] - 2018-
### Security
- Fixes bug that allowed an Authn-Kubernetes request to bypass mutual TLS. All users are strongly recommended to upgrade to this version of Conjur.

### Fixed
- Substantial performance improvement when loading large policy files

## [1.1.1] - 2018-8-10
### Added
- `conjurctl export` now includes the account list to support migration
- `conjurctl export` allows the operator to specify the file name label using the `-l` or `--label` flag
- Update puma to a version that understands how to handle having ipv6 disabled
- Update puma worker timeout to allow longer requests to finish (from 1 minute to 10 minutes)

## [1.1.0] - 2018-7-30
### Added
- Adds `conjurctl export` command to provide a migration data package to Conjur EE

## [1.0.1] - 2018-7-23
### Fixed
- Handling of absolute user ids in policies.
- Attempts to fetch a secret from a nonexistent resource no longer cause 500.

## [1.0.0] - 2018-7-16
### Added
- Audit attempts to update and fetch an invisible secret.
- Updated license to LGPL

## [0.9.0] - 2018-7-11
### Added
- Adds CIDR restrictions to Host and User resources
- Adds Kubernete authentication
- Optimize audit database and responses, for a significant improvement of performance.

### Fixed
- `start` no longer fails to show Help information.

## [0.8.1] - 2018-06-29
### Added
- Audit events for failed variable fetches and updates.

## [0.8.0] - 2018-06-26
### Added

- Audit events for entitlements, variable fetches and updates, authentication and authorization.

## [0.7.0] - 2018-06-25
### Added

- Added AWS Secret Access Key Rotator

## [0.6.0] - 2018-06-25
### Changed
- RolesController#index now accepts `role` as a query parameter. If
  present, resources visible to that role are listed.

- Resources are now only visible if the user is a member of a role that owns them or has some
permission on them.

- RolesController now implements #direct_memberships to return the
  direct members of a role, without recursive expansion.

- Updated Ruby version from 2.2, which is no longer supported, to version 2.5.

- RolesController now implements #members to return a searchable, pageable collection
  of members of a Role.

### Added
- AWS Hosts can authenticate using their assigned AWS IAM role.

- Added variable rotation for Postgres databases

- Experimental audit querying engine mounted at /audit. It can be configured to work with
an external audit database by using config.audit_database configuration entry.

- API endpoints for granting and revoking role membership

- API endpoint for the role graph

- Paging parameters (`offset` and `limit`) for audit API endpoints

## [0.4.0] - 2018-04-10
### Added
- Policy changes now generate audit log messages. These can optionally be generated in RFC5424
format and pushed to a UNIX socket for further processing.
- Code of Conduct

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

[Unreleased]: https://github.com/cyberark/conjur/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/cyberark/conjur/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/cyberark/conjur/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/cyberark/conjur/compare/v0.9.0...v1.0.0
[0.9.0]: https://github.com/cyberark/conjur/compare/v0.8.1...v0.9.0
[0.8.1]: https://github.com/cyberark/conjur/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/cyberark/conjur/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/cyberark/conjur/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/cyberark/conjur/compare/v0.3.0...v0.6.0
[0.3.0]: https://github.com/cyberark/conjur/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/cyberark/conjur/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/cyberark/conjur/compare/v0.1.0...v0.1.1
