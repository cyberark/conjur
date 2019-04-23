# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.0] - 2019-04-23
### Added
- Kubernetes authentication can now work externally from Kubernetes

### Changed
- Moved changelog validation up in CI pipeline

## [1.3.7] - 2019-03-27
### Changed
- Updated links to Policy & Cryptography reference in API documentation
- Updated conjur-policy-parser to
  [v3.0.3](https://github.com/conjurinc/conjur-policy-parser/blob/possum/CHANGELOG.md#v303).
- Replaced `changelog` entrypoint in `ci/test` with a separate script. Building
  the `conjur` and `conjur-test` images just to be able to install and run the
  `parse_a_changelog` gem seemed a little heavyweight.
- Renamed the old docs/ folder to design/

## [1.3.6] - 2019-02-19
### Changed
- Reduced IAM authentication logging
- Refactored authentication strategies

### Removed
- Removed OIDC APIs public access

## [1.3.5] - 2019-02-07
### Changed
- Rails version updated to v4.2.11.
- Updated Docker build to pre-compile Rails assets for Conjur image.

## [1.3.4] - 2018-12-19
### Changed
- Updated dependencies and Ruby version of Docker image
- Removed the cloudformation template in favor of the one found in the docs
  at https://docs.conjur.org/Latest/en/Content/Get%20Started/install-open-source.htm#h2-item-2

### Fixed
- Fixed the authn_restricted_to.feature so that it doesn't depend on the default docker
  network (172.0.0.0/8).
- Fixed Syslog formatting to properly escape the closing square bracket (]) per RFC 5424

## [1.3.3] - 2018-11-20
### Added
- Added support for secure LDAP connections in the LDAP authenticator.
- Added support to configure the LDAP authenticator with policy instead
   of environment variables.

## [1.3.2] - 2018-11-14
### Fixed
- Fixed request parameter parsing when creating or deleting a host factory token.
- Updated ffi and loofah dependencies to latest versions of each.

## [1.3.1] - 2018-10-19
### Fixed
- Fixed host factory `500` server response when a `Role` for a given host ID already
  exists but there is no corresponding `Resource` record.
- Improved authenticator error handling and logging.

## [1.3.0] - 2018-10-10
### Fixed
- Previously, loading a policy with a host factory that doesn't include
  any layers would cause a `nil` runtime exception. Now this case is checked
  specifically and raises a policy load error with a description of the problem.
- Added support for authenticators to implement `/login` in addition to `/authenticate`
- Implemented `/login` for `authn-ldap`.

## [1.2.0] - 2018-09-18
### Added
- Added support for issuing certificates to Hosts using CAs configured as
  Conjur services. More details are available [here](design/CERTIFICATE_SIGNING.md).
- Added support for Conjur CAs to use encrypted private keys
- Implemented keyword search for Role memberships
- Update Conjur issued certificates to include a SPIFFE SVID as a subject alternative
  name (SAN).

### Changed
- Change authn-k8s to expect the client cert (passed in `X-SSL-Client-Certificate`) to be
  url-escaped.
- Update Conjur issued certificates to use the common name derived from the authenticated
  host, rather than use the value from the CSR.

### Fixed
- Prevent anonymous (password-less) authentication with LDAP.

## [1.1.2] - 2018-08-22
### Fixed
- Substantial performance improvement when loading large policy files

### Security
- Fixes a vulnerability that could allow an authn-K8s request to bypass mutual TLS authentication. All Conjur users using authn-k8s within Kubernetes or OpenShift are strongly recommended to upgrade to this version.

## [1.1.1] - 2018-08-10
### Added
- `conjurctl export` now includes the account list to support migration
- `conjurctl export` allows the operator to specify the file name label using the `-l` or `--label` flag
- Update puma to a version that understands how to handle having ipv6 disabled
- Update puma worker timeout to allow longer requests to finish (from 1 minute to 10 minutes)

## [1.1.0] - 2018-07-30
### Added
- Adds `conjurctl export` command to provide a migration data package to Conjur EE

## [1.0.1] - 2018-07-23
### Fixed
- Handling of absolute user ids in policies.
- Attempts to fetch a secret from a nonexistent resource no longer cause 500.

## [1.0.0] - 2018-07-16
### Added
- Audit attempts to update and fetch an invisible secret.
- Updated license to LGPL

## [0.9.0] - 2018-07-11
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
### Added
- AWS Hosts can authenticate using their assigned AWS IAM role.
- Added variable rotation for Postgres databases
- Experimental audit querying engine mounted at /audit. It can be configured to work with
  an external audit database by using config.audit_database configuration entry.
- API endpoints for granting and revoking role membership
- API endpoint for the role graph
- Paging parameters (`offset` and `limit`) for audit API endpoints

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

### Changed
- CTA was updated

### Fixed
- Resolved bug: Policy replace can fail when user is deleted and removed from group

## [0.1.1] - 2017-12-04
### Changed
- Build scripts now look at git tags to determine version and tags to use.

### Fixed
- When a policy is loaded which references a non-existant object, that error is now reported as a JSON-formatted 404 error rather than an ugly 500 error.

## 0.1.0 - 2017-12-04
### Added
- The first tagged version.

[Unreleased]: https://github.com/cyberark/conjur/compare/v1.3.0...HEAD
[1.3.7]: https://github.com/cyberark/conjur/compare/v1.3.6...v1.3.7
[1.3.6]: https://github.com/cyberark/conjur/compare/v1.3.5...v1.3.6
[1.3.5]: https://github.com/cyberark/conjur/compare/v1.3.4...v1.3.5
[1.3.4]: https://github.com/cyberark/conjur/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/cyberark/conjur/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/cyberark/conjur/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/cyberark/conjur/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/cyberark/conjur/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/cyberark/conjur/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/cyberark/conjur/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/cyberark/conjur/compare/v1.1.0...v1.1.1
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
