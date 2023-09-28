# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- Nothing should go in this section, please add to the latest unreleased version
  (and update the corresponding date), or add a new version.

## [1.0.10-cloud] - 2023-10-22
### Added
- Telemetry logs for ephemeral secrets
- Return conflict for existing issuer when variables associated with it

## [1.0.9-cloud] - 2023-10-15
### Added
- Add feature flag endpoint

## [1.0.8-cloud] - 2023-10-01
### Changed
- New env variables

## [1.0.7-cloud] - 2023-09-04
### Changed
- Renamed `platforms` to `issuers`, changed internal structure of ephemeral secret requests and removed default issuer secret
  [ONYX-42993](https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-42993)
- Get all authenticators endpoint, will be used by edge for replication
- Modify edge logs
- Add limit and offset to get all authenticators endpoint [ONYX-44074](https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-44074)

## [1.0.6-cloud] - 2023-08-21
### Changed
- Code refactoring

## [1.0.5-cloud] - 2023-08-16
### Security
- Previously, attempting to add and remove a privilege in the same policy load
  resulted in only the positive privilege (grant, permit) taking effect. Now we
  fail safe and the negative privilege statement (revoke, deny) is the final
  outcome
  [CONJSE-1785](https://ca-il-jira.il.cyber-ark.com:8443/browse/CONJSE-1785)

## [1.0.4-cloud] - 2023-08-10
### Security
- Support plural syntax for revoke and deny
  [CONJSE-1783](https://ca-il-jira.il.cyber-ark.com:8443/browse/CONJSE-1783)

### Added
- Added a call to the ephemeral secrets service when an ephemeral secret is requested https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-42995

## [1.0.3-cloud] - 2023-07-31
### Added
- Endpoint for edge installation token generation https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-41981
- Endpoint for creating edge host https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-41980
- Added create, update, delete and list REST APIs for Platforms https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-42284

## [1.0.2-cloud] - 2023-07-20
### Changed
- Add max edges endpoint for multi edge https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-41982_
- Add audit when Edge reports installation completed

## [1.0.1-cloud] - 2023-07-18
### Changed
- Improve DB connection usage https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-34591
- Pull Slosilo library to Conjur
- Change Slosilo id from "authn:account:host/user" to "authn:account:host/user:current"
- Add update slosilo key option to slosilo put key function
- Add slosilo key rotation scheduled task
- Add workload create endpoint https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-41138
- Modify slosilo endpoint to return current and previous keys
- Add Edges table and allow updating it by Edge https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-40661
- Mask Edge IP from audits emitted by Edge forwards https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-38139
- Add an exclude param to resources-list for filtering https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-41894

## [1.0.0-cloud] - 2023-06-07
### Changed
- Improve DB queries for Edge https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-37081
- Change Slosilo id regex to support: authn:conjur:user/host in addition to authn:conjur
- Split Slosilo key for hosts and users
- Fix No continuation in replication when an error occurs https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-35741

## [0.0.11-cloud] - 2023-05-24
### Changed
- Remove edge-hosts for edge endpoint
- oidc user name to be compare as lowercase https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-37450
- Support versions field in all secrets endpoint https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-37056

## [0.0.10-cloud] - 2023-05-16
### Added
- Implementation health endpoint
  https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-37338

## [0.0.9-cloud] - 2023-05-09
### Added
- Add an option to get all secrets from edge api with encode bse64, by Accept-Encoding header
  https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-35742

## [0.0.8-cloud] - 2023-04-30
### Added
- New edge-hosts endpoints for edge
- Api change. Host API key is return as hashed
  https://ca-il-jira.il.cyber-ark.com:8443/browse/ONYX-35892

## [0.0.7-cloud] - 2023-03-27
### Changed
- Merge from master 2023-03-27 to 2023-03-26

## [0.0.6-cloud] - 2023-03-19
### Security
- Updated github-pages version in docs/Gemfile to allow upgrading activesupport
  to v7.0.4.2 to resolve CVE-2022-22796
  [cyberark/conjur#2729](https://github.com/cyberark/conjur/pull/2729)
- Upgraded rack to v2.2.6.3 to resolve CVE-2023-27530
  [cyberark/conjur#2739](https://github.com/cyberark/conjur/pull/2739)
- Upgraded rack to v2.2.6.4 to resolve CVE-2023-27539
  [cyberark/conjur#2750](https://github.com/cyberark/conjur/pull/2750)

## [0.0.5-cloud] - 2023-03-15
### Changed
- Add get SlosiloKey api

## [0.0.4-cloud] - 2023-03-12
### Changed
- Change count=true not to consider limit and sum all

## [0.0.3-cloud] - 2023-03-06
### Changed
- Change edge group name

## [0.0.2-cloud] - 2023-03-06
### Added
- Edge host endpoint and secret endpoint

## [0.0.1-cloud] - 2022-01-13
### Changed
- Remove auto-release options to allow for a pseudo-fork development on a branch

## [1.20.0] - 2023-09-21

### Fixed
- Allow Factories with optional variables to save without error
  [cyberark/conjur#2956](https://github.com/cyberark/conjur/pull/2956)
- OIDC authenticators support `https_proxy` and `HTTPS_PROXY` environment variables
  [cyberark/conjur#2902](https://github.com/cyberark/conjur/pull/2902)
- Support plural syntax for revoke and deny
  [cyberark/conjur#2901](https://github.com/cyberark/conjur/pull/2901)

### Added
- Support an optional`ca-cert` variable for providing custom certs/chains to verify
  OIDC providers or proxies when using the OIDC authenticator
  [cyberark/conjur#2933](https://github.com/cyberark/conjur/pull/2933)
- New flag to `conjurctl server` command called `--no-migrate` which allows for skipping
  the database migration step when starting the server.
  [cyberark/conjur#2895](https://github.com/cyberark/conjur/pull/2895)
- Telemetry support
  [cyberark/conjur#2854](https://github.com/cyberark/conjur/pull/2854)
- Introduces support for Policy Factory, which enables resource creation
  through a new `factories` API.
  [cyberark/conjur#2855](https://github.com/cyberark/conjur/pull/2855/files)
- Use base images with newer Ubuntu and UBI.
  Display FIPS Mode status in the UI (requires temporary fix for OpenSSL gem).
  [cyberark/conjur#2874](https://github.com/cyberark/conjur/pull/2874)

### Changed
- The database thread pool max connection size is now based on the number of
  web worker threads per process, rather than an arbitrary fixed number. This
  mitigates the possibility of a web worker becoming starved while waiting for
  a connection to become available.
  [cyberark/conjur#2875](https://github.com/cyberark/conjur/pull/2875)
- Changed base-image tagging strategy
  [cyberark/conjur#2926](https://github.com/cyberark/conjur/pull/2926)

### Fixed
- Support Authn-IAM regional requests when host value is missing from signed headers.
  [cyberark/conjur#2827](https://github.com/cyberark/conjur/pull/2827)

### Security
- Upgrade google/cloud-sdk in ci/test_suites/authenticators_k8s/dev/Dockerfile/test
  to use latest version (448.0.0)
  [cyberark/conjur#2972](https://github.com/cyberark/conjur/pull/2972)
- Support plural syntax for revoke and deny
  [cyberark/conjur#2901](https://github.com/cyberark/conjur/pull/2901)
- Previously, attempting to add and remove a privilege in the same policy load
  resulted in only the positive privilege (grant, permit) taking effect. Now we
  fail safe and the negative privilege statement (revoke, deny) is the final
  outcome
  [cyberark/conjur#2907](https://github.com/cyberark/conjur/pull/2907)
- Update puma to 6.3.1 to address CVE-2023-40175.
  [cyberark/conjur#2925](https://github.com/cyberark/conjur/pull/2925)

## [1.19.5] - 2023-06-29

### Security
- Update bundler to 2.2.33 to remove CVE-2021-43809
  [cyberark/conjur#2804](https://github.com/cyberark/conjur/pull/2804/files)

### Fixed
- AuthnJWT now supports claims that include hyphens and inline namespaces.
  [cyberark/conjur#2792](https://github.com/cyberark/conjur/pull/2792)
- Authn-IAM now uses the host in the signed headers to determine which STS endpoint
  (global or regional) to use for validation.

### Changed
- OIDC tokens will now have a default ttl of 60 mins
  [cyberark/conjur#2800](https://github.com/cyberark/conjur/pull/2800)

## [1.19.3] - 2023-04-17

### Added
- Conjur now logs when it detects that the Conjur configuration file
  (conjur.yml) or directory permissions prevent the Conjur server from
  successfully reading it. Conjur also now logs at the DEBUG level when it
  detects that either the directory or file do not exist.
  [cyberark/conjur#2715](https://github.com/cyberark/conjur/pull/2715)
- Account admin roles now have a corresponding resource. This ensures that
  access controls work as expected for this role to access itself.
  [cyberark/conjur#2757](https://github.com/cyberark/conjur/pull/2757)

### Changed
- Removes support for disabling the `CONJUR_FEATURE_PKCE_SUPPORT_ENABLED` flag.
  [cyberark/conjur#2713](https://github.com/cyberark/conjur/pull/2713)
- Routes on the `/roles/` API endpoints now correctly verify the existing of
  a Role and return `404` when it doesn't exist or the caller has insufficient
  privilege.
  [cyberark/conjur#2755](https://github.com/cyberark/conjur/pull/2755)

### Fixed
- Fixed a thread-safety bug in secret retrieval when multiple threads attempt
  to decrypt a secret value with Slosilo/OpenSSL.
  [cyberark/slosilo#31](https://github.com/cyberark/slosilo/pull/31)
  [cyberark/conjur#2718](https://github.com/cyberark/conjur/pull/2718)
- Incomplete HTTP proxy support in the Kubernetes Authenticator is fixed. This
  allows for an HTTP proxy between Conjur and the Kubernetes API.
  [cyberark/conjur#2766](https://github.com/cyberark/conjur/pull/2766)

### Security
- Updated github-pages version in docs/Gemfile to allow upgrading activesupport
  to v7.0.4.2 to resolve CVE-2022-22796
  [cyberark/conjur#2729](https://github.com/cyberark/conjur/pull/2729)
- Upgraded rack to v2.2.6.3 to resolve CVE-2023-27530
  [cyberark/conjur#2739](https://github.com/cyberark/conjur/pull/2739)
- Upgraded rack to v2.2.6.4 to resolve CVE-2023-27539
  [cyberark/conjur#2750](https://github.com/cyberark/conjur/pull/2750)
- Updated nokogiri to 1.14.3 for CVE-2023-29469 and CVE-2023-28484 and rails to
  6.1.7.3 for CVE-2023-28120 in Gemfile.lock, nokogiri to 1.1.4.3 for CVE-2023-29469
  and commonmarker to 0.23.9 for CVE-2023-24824 and CVE-2023-26485 in docs/Gemfile.lock
  (all Medium severity issues flagged by Dependabot)
  [cyberark/conjur#2776](https://github.com/cyberark/conjur/pull/2776)

## [1.19.2] - 2022-01-13

### Fixed
- Previously, including `limit` or `offset` parameters to a resource list request
  resulted in the returned list being unexpectedly sorted. Now, all resource list
  request results are sorted by resource ID.
  [cyberark/conjur#2702](https://github.com/cyberark/conjur/pull/2702)

### Security
- Upgraded Rails to 6.1.7.1 to resolve CVE-2023-22794 (not vulnerable)
  [cyberark/conjur#2703](https://github.com/cyberark/conjur/pull/2703)

## [1.19.1] - 2022-12-08

### Security
- Update loofah to 2.19.1 for CVE-2022-23514, CVE-2022-23515 and CVE-2022-23516 (all Not Vulnerable)
  and rails-html-sanitizr to 1.4.4 for CVE-2022-23517, CVE-2022-23518, CVE-2022-23519, and CVE-2022-23520 (Not vulnerable)
  [cyberark/conjur#2686](https://github.com/cyberark/conjur/pull/2686)
- Updated nokogiri in root and docs Gemfile.lock files to resolve GHSA-qv4q-mr5r-qprj
  [cyberark/conjur#2684](https://github.com/cyberark/conjur/pull/2684)

### Fixed
- Previously, if an OIDC authenticator was configured with a `Status` webservice,
  the OIDC provider endpoint would include duplicate OIDC authenticators. This change resolves ONYX-25530.
  [cyberark/conjur#2678](https://github.com/cyberark/conjur/pull/2678)
- Allows V2 OIDC authenticators to be checked through the authenticator status
  endpoint.  This change resolves ONYX-25531.
  [cyberark/conjur#2692](https://github.com/cyberark/conjur/pull/2692)
- Previously, if an OIDC provider endpoint was incorrect, the provider list endpoint
  would raise an exception. This change resolves ONYX-30387
  [cyberark/conjur#2688](https://github.com/cyberark/conjur/pull/2688)

### Added
- Provides support for PKCE in the OIDC Authenticator code redirect workflow.
  This is enabled by default. If needed, it can be disabled using the
  `CONJUR_FEATURE_PKCE_SUPPORT_ENABLED` feature flag.
  [cyberark/conjur#2678](https://github.com/cyberark/conjur/pull/2678)
- OIDC Authenticator can now be configured to distribute access tokens with a
  custom time-to-live.
  [cyberark/conjur#2683](https://github.com/cyberark/conjur/pull/2683)
- List members request (`GET /roles/conjur/{kind}/{identifier}?members`) now produce audit events.
  [cyberark/conjur#2691](https://github.com/cyberark/conjur/pull/2691)
- Show resource request (`GET /resources/:account/:kind/*identifier`) now produce audit events.
  [cyberark/conjur#2695](https://github.com/cyberark/conjur/pull/2695)
- List memberships request (`GET /roles/:account/:kind/*identifier?memberships`) now produce audit events.
  [cyberark/conjur#2693](https://github.com/cyberark/conjur/pull/2693)

## [1.19.0] - 2022-11-29

### Added
- Conjur policy loads can now emit callbacks to extensions on policy
  load lifecycle events (e.g. before/after policy load). This is disabled
  by default, but is available under the
  `CONJUR_FEATURE_POLICY_LOAD_EXTENSIONS` feature flag.
  [cyberark/conjur#2671](https://github.com/cyberark/conjur/pull/2671)
- Conjur roles API can now emit callbacks to extensions on member add and
  remove events (e.g. before/after add member). This is disabled by default,
  but is available under the `CONJUR_FEATURE_ROLES_API_EXTENSIONS` feature flag.
  [cyberark/conjur#2671](https://github.com/cyberark/conjur/pull/2671)

### Security
- Updated nokogiri in root and docs Gemfile.lock files to resolve GHSA-2qc6-mcvw-92cw
  [cyberark/conjur#2670](https://github.com/cyberark/conjur/pull/2670)

## [1.18.5] - 2022-09-14

### Added
- List resources request (`GET /resources`) now produce audit events.
  [cyberark/conjur#2652](https://github.com/cyberark/conjur/pull/2652)

### Changed
- AWS Access Key Rotation now preserves only one key

## [1.18.4] - 2022-09-11

### Added
- Adds support for authorization token in header in OIDC authenticator.
  [cyberark/conjur#2637](https://github.com/cyberark/conjur/pull/2637)

## [1.18.3] - 2022-09-07

### Security
- Remove code and state from the debug logs
  [conjurinc/conjur-ui#2644](https://github.com/cyberark/conjur/pull/2644)

## [1.18.2] - 2022-09-01

### Changed
- Reduces debug log verbosity.
  [cyberark/conjur#2639](https://github.com/cyberark/conjur/pull/2639)

## [1.18.1] - 2022-08-01

### Changed
- Migrates OIDC Provider list to be accessable via an unauthentated
  endpoint. This is not a concern as logins using this endpoint already
  display the redirect endpoint on the login page.
  [cyberark/conjur#2625](https://github.com/cyberark/conjur/pull/2625)

## [1.18.0] - 2022-08-01

### Added
- Adds support for namespace label based identity scope for the Kubernetes Authenticator
  [cyberark/conjur#2613](https://github.com/cyberark/conjur/pull/2613)

### Changed
- Adds support for authentication using OIDC's code authorization flow
  [cyberark/conjur#2595](https://github.com/cyberark/conjur/pull/2595)

### Security
- Updated tzinfo to 1.2.10 to address CVE-2022-31163
  [cyberark/conjur#2610](https://github.com/cyberark/conjur/pull/2610)

## [1.17.8] - 2022-07-14

### Security
- Updated rails to 6.1.6.1 to remove CVE-2022-32224
  [cyberark/conjurinc#2605](https://github.com/cyberark/conjur/pull/2605)

## [1.17.7] - 2022-06-29
### Changed
- Made simplecov a dev/test dependency
  [cyberark/conjur#2564](https://github.com/cyberark/conjur/pull/2564)
- Added configuration for token TTL
  [cyberark/conjur#2510](https://github.com/cyberark/conjur/pull/2510)
- Added configuration for default value for maximum number of results return to `/resources` request
  [cyberark/conjur#2510](https://github.com/cyberark/conjur/pull/2510)

### Fixed
- Previously, the temporary schemas used to modify Conjur policy
  caused the Postgres database catalog cache to leak memory over time,
  leading to an eventual crash. Now, we recycle the database
  connection after modifying policy to free this cache and prevent
  the memory leak from occurring.
  [cyberark/conjur#2584](https://github.com/cyberark/conjur/pull/2584)

### Security
- Update rack to 2.2.3.1 to resolve CVE-2022-3023
  [cyberark/conjur#2564](https://github.com/cyberark/conjur/pull/2564)
- Update nokogiri to 1.13.6 to resolve un-numbered libxml CVEs (both in main
  Gemfile.lock and in docs/Gemfile.lock)
  [cyberark/conjur#2558](https://github.com/cyberark/conjur/pull/2558)

## [1.17.6] - 2022-04-07

### Changed
- Adds `CONJUR_USERS_IN_ROOT_POLICY_ONLY` environment variable to prevent users from being created outside the root policy.
- Fixed promotion behavior

### Security
- Upgrade Rails to 6.12.5.1 to close CVE-2022-22577 and CVE-2022-27777
  [cyberark/conjur#2553](https://github.com/cyberark/conjur/pull/2553)
- Updated nokogiri to 1.13.4 to resolve CVE-2022-24836
  [cyberark/conjur#2534](https://github.com/cyberark/conjur/pull/2534)

## [1.17.3] - 2022-04-04

### Changed
- Fixed issue where an invalid content type sent by our .NET SDK was causing
  Conjur to error - but this wasn't the case before the Ruby 3 upgrade
  [#2525](https://github.com/cyberark/conjur/pull/2525)
- Verify non user or host resources do not have credentials.
- Update to automated release process
- Proper error message appears when JWT Authenticator gets HTTP code error
  while trying to fetch JWKS data from `jwks-uri` [#2474](https://github.com/cyberark/conjur/pull/2474)
- Upgrade to Ruby 3. [#2444](https://github.com/cyberark/conjur/pull/2444)

### Added
- Added the ability to fetch signing keys from JWKS endpoints that use a self-signed
  certificate or a certificate signed by a third-party CA for JWT generic vendor
  configuration
  ([#2462](https://github.com/cyberark/conjur/pull/2462)
  [#2461](https://github.com/cyberark/conjur/pull/2461)
  [#2456](https://github.com/cyberark/conjur/pull/2456)
  [#2455](https://github.com/cyberark/conjur/pull/2455)
  [#2457](https://github.com/cyberark/conjur/pull/2457)
  [#2452](https://github.com/cyberark/conjur/pull/2452)
  [#2437](https://github.com/cyberark/conjur/pull/2437))
- Added the ability for JWT generic vendor configuration to receive signing keys
  for JWT token verification from a variable. Variable name is `public-keys`
  ([#2463](https://github.com/cyberark/conjur/pull/2463)
  [#2461](https://github.com/cyberark/conjur/pull/2461)
  [#2456](https://github.com/cyberark/conjur/pull/2456)
  [#2455](https://github.com/cyberark/conjur/pull/2455)
  [#2454](https://github.com/cyberark/conjur/pull/2454)
  [#2450](https://github.com/cyberark/conjur/pull/2450)
  [#2447](https://github.com/cyberark/conjur/pull/2447)
  [#2437](https://github.com/cyberark/conjur/pull/2437))
- Added support for SNI certificates when talking to the Kubernetes API
  server through the web socket client.
  [#2482](https://github.com/cyberark/conjur/pull/2482)
- Added support for http(s)_proxy for Kubernetes client in Kubernetes
  authenticator
  [#2432](https://github.com/cyberark/conjur/pull/2432)

### Fixed
- IAM Authn bug fix - Take rexml gem to production configuration [#2493](https://github.com/cyberark/conjur/pull/2493)
- Previously, a stale puma pid file would prevent the Conjur server from starting
  successfully. Conjur now removes a stale pid file at startup, if it exists.
  [#2498](https://github.com/cyberark/conjur/pull/2498)
- Use entirety of configured Kubernetes endpoint URL in Kubernetes authenticator's
  web socket client, instead of only host and port
  [#2479](https://github.com/cyberark/conjur/pull/2479)

### Security
- Updated rails to 6.1.4.7 to resolve CVE-2022-21831 (not vulnerable)
  [cyberark/conjur#2513](https://github.com/cyberark/conjur/pull/2513)
- Updated nokogiri to 1.13.3 to resolve CVE-2022-23308 and CVE-2021-30560
  [cyberark/conjur#2504](https://github.com/cyberark/conjur/pull/2504)
- Updated Rails to 6.1.4.4 to resolve CVE-2021-44528 (Medium, Not Vulnerable)
  [cyberark/conjur#2486](https://github.com/cyberark/conjur/pull/2486)
- Updated Rails to 6.1.4.6 to resolve CVE-2022-23633
- Updated Puma to 5.6.2 to resolve CVE-2022-23634
  [cyberark/conjur#2492](https://github.com/cyberark/conjur/pull/2492)
- Updated Puma to 5.6.4 to resolve CVE-2022-24790
  [cyberark/conjur#2534](https://github.com/cyberark/conjur/pull/2534)
- Updated KubeClient to 4.9.3 to resolve CVE-2022-0759
  [cyberark/conjur#2527](https://github.com/cyberark/conjur/pull/2527)

## [1.15.0] - 2021-12-21

### Added
- Added API endpoint to enable and disable GCP authenticator
  [#2448](https://github.com/cyberark/conjur/pull/2448)

### Fixed
- Check to stop hosts from setting passwords fixed for admin user
  [#2440](https://github.com/cyberark/conjur/pull/2440)

## [1.14.2] - 2021-12-13

### Changed
- Failed Login now writes the error code in the log
  [#2424](https://github.com/cyberark/conjur/pull/2424)
- Bump cyberark base images from 1.0.5 to 1.0.6
  [#2420](https://github.com/cyberark/conjur/pull/2420)
- Bump cyberark base images from 1.0.4 to 1.0.5
  [#2418](https://github.com/cyberark/conjur/pull/2418)

### Fixed
- Return 401 instead of 500 for invalid basic auth header.
  [#1990](https://github.com/cyberark/conjur/issues/1990)
- Added check to stop hosts from setting passwords
  [#1920](https://github/cyberark/conjur/issues/1920)

### Security
- Bump gems related to openid_connect stack for improving the certificate
  validation procedure during the OIDC keys discovery process
  [#2441](https://github.com/cyberark/conjur/pull/2441)

## [1.14.1] - 2021-11-05

### Fixed
- Version bump to resolve build error on tagged master. [#2416](https://github.com/cyberark/conjur/pull/2416)

## [1.14.0] - 2021-11-03

### Added
- Create default account when no account is specified in `conjurctl account create`.
  [cyberark/conjur#2388](https://github.com/cyberark/conjur/pull/2388)
- JWT Authenticator supports nested claims in `token-app-property`, `enforced-claims`,
  `claim-aliases` and role annotations.
  [#2397](https://github.com/cyberark/conjur/pull/2397)
  [#2404](https://github.com/cyberark/conjur/pull/2404)
  [#2403](https://github.com/cyberark/conjur/pull/2403)

### Changed
- Changed claims mapping variable name ('mapping-claims' => 'claim-aliases').
  [cyberark/conjur#2382](https://github.com/cyberark/conjur/pull/2382)

## [1.13.2] - 2021-10-13

### Security
- Updated puma to 5.5.1 to close
  [GHSA-48w2-rm65-62xx](https://github.com/puma/puma/security/advisories/GHSA-48w2-rm65-62xx).
  We were not vulnerable to this issue. [cyberark/conjur#2385](https://github.com/cyberark/conjur/pull/2385)
- GCP Authenticator: When defining the host using the instance-name annotation,
  you now need to define at least one additional annotation.
  [cyberark/conjur#2387](https://github.com/cyberark/conjur/pull/2387)
- Updated nokogiri to 1.12.5 in both Gemfile.lock and docs/Gemfile.lock to resolve
  [CVE-2021-41098](https://github.com/advisories/GHSA-2rr5-8q37-2w7h)
  [cyberark/conjur#2376](https://github.com/cyberark/conjur/pull/2376)
  [cyberark/conjur#2377](https://github.com/cyberark/conjur/pull/2377)

## [1.13.1] - 2021-09-13

### Fixed
- Fix bug of cache not working in authn jwt. [cyberark/conjur#2353](https://github.com/cyberark/conjur/pull/2353)
- Fix bug `authn-jwt` now appears in `installed` authenticators list of `authenticators` endpoint output. [cyberark/conjur#2365](https://github.com/cyberark/conjur/pull/2365)

### Changed
- OIDC based authenticators no longer return Bad Gateway and Gateway Timeout http error codes.
  Unauthorised is returned instead.
  [cyberark/conjur#2360](https://github.com/cyberark/conjur/pull/2360)

## [1.13.0] - 2021-07-29

### Added
- Added enforced claims support to JWT generic vendor configuration. [cyberark/conjur#2325](https://github.com/cyberark/conjur/pull/2325)
- Added claims mapping support to JWT generic vendor configuration. [cyberark/conjur#2330](https://github.com/cyberark/conjur/pull/2330)
- Added audience check to JWT generic vendor configuration. [cyberark/conjur#2345](https://github.com/cyberark/conjur/pull/2345)

### Security
- Bump `cyberark/ubi-ruby-fips` from 1.0.3 to 1.0.4 to address CVE-2021-33910.
  [cyberark/conjur#2333](https://github.com/cyberark/conjur/issues/2333)
- Upgraded addressable in ./Gemfile.lock and ./docs/Gemfile.lock to 2.8.0 to resolve
  GHSA-jxhc-q857-3j6g [cyberark/conjur#2311](https://github.com/cyberark/conjur/pull/2311)
- Previously, OIDC authentication requests that included a user ID in the URL
  path would return a Conjur access token without requiring a valid OIDC token
  in the request. OIDC authentication requests that attempt to include a user ID
  in the URL path now return a `404 Not Found` response.
  [Security Bulletin](https://github.com/cyberark/conjur/security/advisories/GHSA-6xj8-59gr-4jp3)

## [1.12.0] - 2021-06-25

### Added
- The JWT Authenticator (`authn-jwt`) supports authenticating third-party vendors that utilize JWT.
  See [design](https://github.com/cyberark/conjur/blob/master/design/authenticators/authn_jwt/authn_jwt_solution_design.md)
- Set MAX_REQUESTS_PER_CONNECTION to infinity and introduced an
  environment variable to allow users to set their own value,
  see PR for further information:
  [cyberark/conjur#2282](https://github.com/cyberark/conjur/issues/2282)

### Changed
- Parsing a Conjur config with invalid YAML content now outputs a more user
  friendly error message without a stack trace.
  [cyberark/conjur#2256](https://github.com/cyberark/conjur/issues/2256)
- Set the Puma process explicitly to reliably restart the correct process
  when the Conjur configuration is reloaded.
  [cyberark/conjur#2291](https://github.com/cyberark/conjur/pull/2291)

### Security
- Upgrade bindata to 2.4.10 to resolve Unspecified Issue reported by JFrog Xray
  [cyberark/conjur#2257](https://github.com/cyberark/conjur/issues/2257)

## [1.11.7] - 2021-06-08

### Added
- Enabled authenticators can now be configured via a configuration file, or the
  CONJUR_AUTHENTICATORS environment variable.
  [cyberark/conjur#2173](https://github.com/cyberark/conjur/issues/2173)
- Trusted Proxies can now be configured with a configuration file or by setting
  the CONJUR_TRUSTED_PROXIES environment variable.
  [cyberark/conjur#2168](https://github.com/cyberark/conjur/issues/2168)
- Added `conjurctl configuration show` command to print the Conjur configuration
  values and the sources they are loaded from.
  [cyberark/conjur#2169](https://github.com/cyberark/conjur/issues/2169)
- Added `conjurctl configuration apply` command restart the Conjur process and
  pick up changes to the configuration file.
  [cyberark/conjur#2171](https://github.com/cyberark/conjur/issues/2171)

### Fixed
- Fix bug where running `conjurctl server` or `conjurctl account create` with
  passwords that contain `,`s sent via stdin raised an error.
  [cyberark/conjur#2159](https://github.com/cyberark/conjur/issues/2159)
- Update the default keepalive timeout for puma to be longer than most common proxy and load balancers.
  Previously, the load balancer in front of Conjur would commonly have a longer timeout than the
  server itself, which can lead to Conjur closing connections even as there are pending requests and
  the proxy returning 502 errors to the client.
  [PR cyberark/conjur#2191](https://github.com/cyberark/conjur/pull/2191)

### Security
- Upgrade Rails to 5.2.6 to resolve CVE-2021-22885
  [cyberark/conjur#2149](https://github.com/cyberark/conjur/issues/2149)
- Upgrade Nokogiri to 1.11.5 to resolve
  [GHSA-7rrm-v45f-jp64](https://github.com/advisories/GHSA-7rrm-v45f-jp64).
- Upgrade Puma to 4.3.8 to resolve
  [CVE-2021-29509](https://nvd.nist.gov/vuln/detail/CVE-2021-29509).
- Upgrade Bundler to 2.2.18 to resolve
  [CVE-2020-36327](https://nvd.nist.gov/vuln/detail/CVE-2020-36327).

## [1.11.6] - 2021-04-28

### Fixed
- Fix bug where running `conjurctl server` or `conjurctl account create` with
  non-alpha-numeric passwords sent via stdin raised an error.
  [cyberark/conjur#2114](https://github.com/cyberark/conjur/issues/2114)

### Changed
- The batch secret retrieval endpoint now returns a 406 Not Acceptable instead
  of a 500 error when a secret with incompatible encoding is requested.
  [cyberark/conjur#2124](https://github.com/cyberark/conjur/pull/2124)

### Security
- Upgrade github-pages in docs/Gemfile to resolve CVE-2021-28834 in kramdown dependency [cyberark/conjur#2099](https://github.com/cyberark/conjur/issues/2099)
- Bump `cyberark/ubi-ruby-fips` from 1.0.1 to 1.0.2 to address CVE-2021-20305.
  [cyberark/conjur#2120](https://github.com/cyberark/conjur/issues/2120)

### Added
- File `API_VERSION` containing the current Conjur API Version, which corresponds to a
  release of the [Conjur OpenAPI Spec](https://github.com/cyberark/conjur-openapi-spec).
  [cyberark/conjur#2086](https://github.com/cyberark/conjur/pull/2086)
- Status page details section now displays the Conjur API version.
  [cyberark/conjur#2130](https://github.com/cyberark/conjur/issues/2130)

## [1.11.5] - 2021-04-05

### Fixed
- Secrets batch request with blank variable names, now returns `Error 422
  Unprocessable Entity`.
  [cyberark/conjur#2083](https://github.com/cyberark/conjur/issues/2083)

### Added
- `conjurctl server` and `conjurctl account create` allow the operator to specify
  the admin user's password via STDIN by providing the `--password-from-stdin` switch.
  [cyberark/conjur#2043](https://github.com/cyberark/conjur/issues/2043)
- `conjurctl account create` now allows the operator to specify the account name via
  the `--name` flag. We recommend using this explicit flag when using the `--password-from-stdin`
  option so that commands are explicit and more readable.
  [cyberark/conjur#2043](https://github.com/cyberark/conjur/issues/2043)
- `/whoami` API endpoint now produces audit events.
  [cyberark/conjur#2052](https://github.com/cyberark/conjur/issues/2052)
- When a user checks permissions of a non-existing role or a non-existing resource,
  Conjur now audits a failure message.
  [cyberark/conjur#2059](https://github.com/cyberark/conjur/issues/2059)

### Changed
- The secrets batch retrieval endpoint now refers to the `Accept-Encoding`
  header rather than `Accept` to determine the response encoding.
  [cyberark/conjur#2065](https://github.com/cyberark/conjur/pull/2065)
- When trying to fetch a missing or empty secret, a proper error message is now
  returned.
  [cyberark/conjur#2023](https://github.com/cyberark/conjur/issues/2023)
- Login and authentication error stack traces are printed to the log at the
  default INFO level. Previously, users had to restart their servers with
  `CONJUR_LOG_LEVEL=debug` to get meaningful log messages that diagnosed
  configuration or enablement errors; with this change, server logs will be
  clearer about login or authentication errors and will include minimal stack
  traces.
  [cyberark/conjur#2080](https://github.com/cyberark/conjur/issues/2080)
- Conjur base image updated to v1.0.1.
  [PR cyberark/conjur#2088](https://github.com/cyberark/conjur/pull/2088)

## [1.11.4] - 2021-03-09

### Security
- Updated Rails to 5.2.4.5 to address CVE-2021-22880.
  [cyberark/conjur#2056](https://github.com/cyberark/conjur/issues/2056)

## [1.11.3] - 2021-02-22

### Fixed
- Conjur now raises a new `ServiceIdMissing` error if the `service-id` param is
  missing in an authentication request for the OIDC authenticator.
  [cyberark/conjur#2004](https://github.com/cyberark/conjur/issues/2004)

### Changed
- Conjur now raises a `RoleNotFound` error when trying to authenticate a
  non-existent host in authn-k8s.
  [cyberark/conjur#2046](https://github.com/cyberark/conjur/issues/2046)

## [1.11.2] - 2021-02-02
### Added
- New `edge`-tagged images are published to DockerHub on every master branch
  build.
  [cyberark/conjur#1617](https://github.com/cyberark/conjur/issues/1617)

### Changed
- Conjur images are updated to use pinned versions of the public base images.
  Users can now determine exactly which dependencies in the
  [Conjur Base Image](https://github.com/cyberark/conjur-base-image) project
  are included in their Conjur image.
  [cyberark/conjur#1974](https://github.com/cyberark/conjur/issues/1974)
- When [batch secret retrieval](https://docs.conjur.org/Latest/en/Content/Developer/Conjur_API_Batch_Retrieve.htm)
  requests are sent with an `Accept: base64` header, the secret values in
  the response will all be Base64-encoded. Sending requests with this header
  allows users to retrieve binary secrets encoded in Base64.
  [cyberark/conjur#1962](https://github.com/cyberark/conjur/issues/1962)
- Conjur now verifies that the `offset` parameter is a valid integer value.
  The `GET /resources` request will fail if `offset` is not an integer greater
  than or equal to 0.
  [cyberark/conjur#1997](https://github.com/cyberark/conjur/issues/1997)

### Fixed
- Requests with empty body and `application/json` Content-Type Header will now
  return 400 error instead of 500 error.
  [cyberark/conjur#1968](https://github.com/cyberark/conjur/issues/1968)
- Users no longer receive 500 errors when loading policy after performing
  database backup and restore.
  [cyberark/conjur#1948](https://github.com/cyberark/conjur/issues/1948)
- The audit endpoint no longer incorrectly reports a 404 Not Found response
  when the resource ID used for retrieving audit events includes a period (.).
  With this change, the audit endpoint is now consistent with how other Conjur
  endpoints handle unencoded periods in resource IDs.
  [cyberark/conjur#2001](https://github.com/cyberark/conjur/issues/2001)
- Attempts to retrieve binary secret data in a
  [batch secret retrieval request](https://docs.conjur.org/Latest/en/Content/Developer/Conjur_API_Batch_Retrieve.htm)
  without using the `Accept: base64` header now returns a message with the 500
  response to explain that improper secret encoding is the cause of the error.
  [cyberark/conjur#1962](https://github.com/cyberark/conjur/issues/1962)
- `GET /resources` request with non-numeric delimiter (limit or offset) now
  returns `Error 422 Unprocessable Entity` instead of `Error 500`.
  [cyberark/conjur#1997](https://github.com/cyberark/conjur/issues/1997)
- `POST /host_factory_tokens` request with invalid ip address or CIDR range of
  `cidr` parameter now returns `Error 422 Unprocessable Entity` instead of `Error 500`.
  [cyberark/conjur#2011](https://github.com/cyberark/conjur/issues/2011)

### Security
- Kubernetes authenticator certificate injection process now performs certificate
  verification to prevent MitM attacks.
  [Security Bulletin](https://github.com/cyberark/conjur/security/advisories/GHSA-hvhv-f953-rwmv)

## [1.11.1] - 2020-11-19
### Added
- UBI-based Conjur image to support Conjur server running on OpenShift. Image
  will be published to RedHat Container Registry.
  [cyberark/conjur#1883](https://github.com/cyberark/conjur/issues/1883)

## [1.11.0] - 2020-11-06
### Added
- GCP authenticator (`authn-gcp`) supports authenticating from Google Cloud Function (GCF)
  using a GCE instance identity token.
  See [design](https://github.com/cyberark/conjur/blob/master/design/authenticators/authn_gcp/authn_gcp_solution_design.md)
  for details. [cyberark/conjur#1804](https://github.com/cyberark/conjur/issues/1804)

### Changed
- Conjur now raises an ExecCommandError error instead of a CertInstallationError
  error in case it failed to install the client certificate during authn-k8s.
  [cyberark/conjur#1860](https://github.com/cyberark/conjur/issues/1860)

### Fixed
- Conjur now raises an Unauthorized error when a user attempts to rotate the API key of a
  nonexistent role. Previously, the operation would result in a successful rotation of the
  existing user's API key, with no indication that the target of the operation had changed.
  [cybeark/conjur#1914](https://github.com/cyberark/conjur/issues/1914)

### Security
- Bumped Ruby version from 2.5.1 to 2.5.8 to address
  [CVE-2020-10663](https://nvd.nist.gov/vuln/detail/CVE-2020-10663).
  [cyberark/conjur#1906](https://github.com/cyberark/conjur/pull/1906)

## [1.10.0] - 2020-10-16
### Added
- [Documentation](https://github.com/cyberark/conjur/blob/master/UPGRADING.md)
  explaining how to upgrade a Conjur server deployed in a Docker Compose environment.
  [cyberark/conjur#1528](https://github.com/cyberark/conjur/issues/1528), [cyberark/conjur#1584](https://github.com/cyberark/conjur/issues/1584)
- When Conjur starts, we now convert blank environment variables to nil. This ensures we treat empty environment values as
  if the environment variable is not present, rather than attempting to use the empty string value. [cyberark/conjur#1841](https://github.com/cyberark/conjur/issues/1841)

### Changed
- The "inject_client_cert" request now returns 202 Accepted instead of 200 OK to
  indicate that the cert injection has started but not necessarily completed.
  [cyberark/conjur#1848](https://github.com/cyberark/conjur/issues/1848)

### Fixed
- Conjur now verifies that Kubernetes Authenticator variables exist and have value before retrieving them so that a
  proper error will be raised if they aren't.
  [cyberark/conjur#1315](https://github.com/cyberark/conjur/issues/1315)

## [1.9.0] - 2020-08-31
### Added
- A new authenticator for applications running in Google Cloud Platform (`authn-gcp`),
  which supports authenticating from Google Compute Engines (GCE) using a GCE instance
  identity token. See [design](design/authenticators/authn_gcp/authn_gcp_solution_design.md)
  for details. [cyberark/conjur#1711](https://github.com/cyberark/conjur/issues/1711)
- New `/whoami` API endpoint for improved supportability and debugging for access
  tokens and client IP address determination. [cyberark/conjur#1697](https://github.com/cyberark/conjur/issues/1697)
- `TRUSTED_PROXIES` is validated at Conjur startup to ensure that it contains
  valid IP addresses and/or address ranges in CIDR notation.
  [cyberark/conjur#1727](https://github.com/cyberark/conjur/issues/1727)
- The `/authenticate` endpoint now returns a text/plain base64 encoded access token
  if the `Accept-Encoding` request header includes `base64`.
  [cyberark/conjur#151](https://github.com/cyberark/conjur/issues/151)

### Changed
- The "inject_client_cert" request now returns 202 Accepted instead of 200 OK to
  indicate that the cert injection has started but not necessarily completed.
  [cyberark/conjur#1848](https://github.com/cyberark/conjur/issues/1848)
- The Conjur server request logs now records the same IP address used by audit
  logs and network authentication filters with the `restricted_to` attribute.
  [cyberark/conjur#1719](https://github.com/cyberark/conjur/issues/1719)
- Conjur now only trusts `127.0.0.1` to send the `X-Forwarded-For` header by
  default. Additional trusted IP addresses may be added with the `TRUSTED_PROXIES`
  environment variable. [cyberark/conjur#1725](https://github.com/cyberark/conjur/issues/1725)
- Invalid CIDR notation in `restricted_to` now returns a policy validation
  error, rather than an internal server error.
  [cyberark/conjur#1763](https://github.com/cyberark/conjur/issues/1763)

### Fixed
- The `TRUSTED_PROXIES` environment variable now works correctly again after the
  Rails 5 upgrade. This is to indicate trusted proxy IP addresses when using the
  `X-Forwarded-For` HTTP header to identity the true client IP address of a request.
  [cyberark/conjur#1689](https://github.com/cyberark/conjur/issues/1689)
- A new database migration step updates the fingerprints in slosilo. The FIPS compliance
  update in `v1.8.0` caused the previous fingerprints to be invalid.
  [cyberark/conjur#1584](https://github.com/cyberark/conjur/issues/1584)

### Security
- Replaces string comparison with Secure Compare to prevent timing attacks against
  the API authentication endpoint. [Security Bulletin](https://github.com/cyberark/conjur/security/advisories/GHSA-c7x2-6g4j-327p)
- Roles must use basic authentication to rotate their own API key, and can no longer
  rotate their API key using only an access token. [Security Bulletin](https://github.com/cyberark/conjur/security/advisories/GHSA-qhjf-g9gm-64jq)

## [1.8.1] - 2020-07-14
### Fixed
- Log the OpenSSL FIPS mode after Rails is initialized for both OSS and DAP.
  [cyberark/conjur#1684](https://github.com/cyberark/conjur/pull/1684)
- Bump `conjur-policy-parser` so `revoke (member)` and `deny (role)`
  can correctly utilize relative paths. [cyberark/conjur-policy-parser#23](https://github.com/cyberark/conjur-policy-parser/pull/23)

## [1.8.0] - 2020-07-10
### Changed
- Use OpenSSL 1.0.2u to support FIPS compliance.
  [cyberark/conjur#1527](https://github.com/cyberark/conjur/issues/1527)
- Conjur can be configured to run in FIPS compliant or Non-FIPS compliant mode depending on requirements.
  FIPS Compliant mode is slightly slower then non-FIPS compliant.
  [cyberark/conjur#1527](https://github.com/cyberark/conjur/issues/1527)
- Bump conjur-rack from 4.0.0 to 4.2.0 that consumes FIPS compliant slosilo.
  [cyberark/conjur#1527](https://github.com/cyberark/conjur/issues/1527)
- Print login and authentication error to the log in INFO level.
  [cyberark/conjur#1377](https://github.com/cyberark/conjur/issues/1377)
- Print proper message when user does not exist in authn or login request with
  default authenticator.
  [cyberark/conjur#1655](https://github.com/cyberark/conjur/issues/1655)

### Added
- Password changes (`PUT /authn/:account/password`) now produce audit events with
  message ID `password`. [cyberark/conjur#1548](https://github.com/cyberark/conjur/issues/1548)
- API key rotations (`PUT /:authenticator/:account/api_key`) now produce audit events with
  message ID `api-key`. [cyberark/conjur#1549](https://github.com/cyberark/conjur/issues/1549)
- All audit events now contain the IP address of the client that initiated the
  API request (e.g. `[client@43868 ip="172.24.0.5"]`).
  [cyberark/conjur#1550](https://github.com/cyberark/conjur/issues/1550)
- Print Conjur server FIPS mode status. [cyberark/conjur#1654](https://github.com/cyberark/conjur/issues/1654)

### Security
- Updated `rack` to `2.2.3` to resolve CVE-2020-8184. [cyberark/conjur#1643](https://github.com/cyberark/conjur/pull/1643)

## [1.7.4] - 2020-06-17

### Fixed
- The default content type for requests is now set at the beginning of the
  Rack middleware chain, so that the content type is available for
  subsequent middleware ([cyberark/conjur#1622](https://github.com/cyberark/conjur/issues/1622))
- The default content type middleware now correctly checks for the
  absence of the `Content-Type` header
  ([cyberark/conjur#1622](https://github.com/cyberark/conjur/issues/1622))

## [1.7.3] - 2020-06-11

### Fixed
- Host Factory Host creation no longer makes unecessary database queries, causing
  performance issues with large numbers of created hosts
  ([cyberark/conjur#1605](https://github.com/cyberark/conjur/issues/1605))

## [1.7.2] - 2020-06-08

### Fixed
- The Conjur version is now printed on server startup, after running `conjurctl server`
  ([cyberark/conjur#1590](https://github.com/cyberark/conjur/pull/1590))
- Raise proper error of an authn request with a non-existing user to the `authn`
  authenticator ([cyberark/conjur#1591](https://github.com/cyberark/conjur/pull/1591))

## [1.7.1] - 2020-06-03

### Added
- Print version on server startup ([cyberark/conjur#1531](https://github.com/cyberark/conjur/issues/1531))

### Fixed
- `rake policy:load` fails when loading policy ([cyberark/conjur#1581](https://github.com/cyberark/conjur/issues/1581))

## [1.7.0] - 2020-05-29

### Fixed
- The k8s authenticator correctly authenticates an app using the host ID to specify
  the k8s resource constraints and an annotation to specify the authenticator
  container name using the "authn-k8s" prefix ([cyberark/conjur#1535](https://github.com/cyberark/conjur/issues/1535), [conjurinc/dap-support#79](https://github.com/conjurinc/dap-support/issues/79)) - [PR](https://github.com/cyberark/conjur/pull/1499).
- Fixed exception in `conjurctl` when loading policy ([conjurinc/dap-support#80](https://github.com/conjurinc/dap-support/issues/80)) - [PR](https://github.com/cyberark/conjur/pull/1510).

### Changed
- Updated the title of status page to `Conjur Status` from `Conjur` ([conjurinc/dap-support](https://github.com/conjurinc/dap-support/issues/75)) - [PR](https://github.com/cyberark/conjur/pull/1499).
- Policy load API endpoints now default to the `application/x-yaml` content-type if no content type is provided in the request ([conjurinc/dap-support#74](https://github.com/conjurinc/dap-support/issues/74)) - [PR](https://github.com/cyberark/conjur/pull/1505).
- ActiveSupport uses SHA1 instead of MD5 ([cyberark/conjur#1418](https://github.com/cyberark/conjur/issues/1418)).
- Authentication audit events now use separate operations for `authenticate`,
  `login`, and `validate-status` workflows
  ([cyberark/conjur#1054](https://github.com/cyberark/conjur/issues/1054)).
- Authentication workflow checks origin before credentials to insure a request can authenticate before authenticating ([cyberark/conjur#1568](https://github.com/cyberark/conjur/issues/1568)).

### Added
- The Kubernetes authentication `/inject-client-cert` endpoint now generates
  an authentication audit event with the `k8s-inject-client-cert` operation
  ([cyberark/conjur#1538](https://github.com/cyberark/conjur/issues/1538)).
- Adds a `CertMissingCNEntry` error to improve visibility of Kubernetes authenticator failures ([cyberark/conjur#1278](cyberark/conjur/issues/1278)).
- Logs the authenticator used when the `authentication-container-name` annotation is missing ([conjurinc/dap-support#69](https://github.com/conjurinc/dap-support/issues/69)) - [PR](https://github.com/cyberark/conjur/pull/1526).

### Removed
- Images are no longer published to Quay.io.

## [1.6.0] - 2020-04-14

### Changed
- Use Ubuntu 18.04 LTS as the base image for Conjur to continue using Ruby 2.5
  ([cyberark/conjur#1456](https://github.com/cyberark/conjur/issues/1456)).
- Conjur image now performs a `dist-upgrade` as the first image build step to
  ensure the image includes all available vulnerability fixes in the base OS.
- Upgrade from Rails 4 to Rails 5

## [1.5.1] - 2020-03-25

### Fixed
- Status page details section now displays the Conjur version number
  [cyberark/conjur#1438](https://github.com/cyberark/conjur/issues/1438).

## [1.5.0] - 2020-03-23

### Added
- Hosts can authenticate from Azure VMs using an Azure access token. See
  [design](design/authenticators/authn_azure/authn_azure_solution_design.md) for details
  ([conjurinc/appliance#927](https://github.com/conjurinc/appliance/issues/927)).

### Changed
- Lock rotators to prevent multiple rotations from incurring simultaneously.

### Fixed
- Fix support for using deployment as K8s authentication resource type for Kubernetes >= 1.16
  ([#1440](https://github.com/cyberark/conjur/issues/1440))

## [1.4.7] - 2020-03-12

### Changed
- Improved flows and rules around user creation (#1272)
- Kubernetes authenticator now returns 403 on unpermitted hosts instead of a 401 (#1283)
- Conjur hosts can authenticate with authn-k8s from anywhere in the policy branch (#1189)

### Fixed
- Updated broken links on server status page (#1341)

## [1.4.6] - 2020-01-21

### Changed
- K8s hosts' resource restrictions is extracted from annotations or id. If it is
  defined in annotations it will taken from there and if not, it will be taken
  from the id.

## [1.4.5] - 2019-12-22

### Added
- Added API endpoint to enable and disable authenticators. See
  [design/authenticator_whitelist_api.md](design/authenticators/authenticator_whitelist_api.md)
  for details.

### Changed
- The k8s host id does not use the "{@account}:host:conjur/authn-k8s/#{@service_name}/apps"
  prefix and takes the full host-id from the CSR. We also handle backwards-compatibility and use
  the prefix in case of an older client.

## [1.4.4] - 2019-12-19

### Added
- Early validation of account existence during OIDC authentication
- Code coverage reporting and collection

### Changed
- Bumped `puma` from 3.12.0 to 3.12.2
- Bumped `rack` from 1.6.11 to 1.6.12
- Bumped `excon` from 0.62.0 to 0.71.0

### Fixed
- Fixed password rotation of blank password
- Fixed bug with multi-cert CA chains in Kubernetes service accounts
- Fixed build issues with creating namespaces with multiple values

### Removed
- Removed follower env configuration

## [1.4.3] - 2019-11-26

### Added
- Flattening of OSS container layers.

### Changed
- Upgraded Nokogiri to 1.10.5.
- Upgrade base image of OSS to `ubuntu:20.20`.
- Enablement work to get OSS container to work on OpenShift as-is.

## [1.4.2] - 2019-09-13

### Fixed
- An unset initContainer field in a deployment config pod spec will no
  longer cause the k8s authenticator to fail with `undefined method` ([#1182](https://github.com/cyberark/conjur/issues/1182)).

## [1.4.1] - 2019-06-24
### Fixed
- Make sure the authentication framework only caches Role lookups for the
  duration of a single request. Reusing stale lookups was leading to
  authentication failures.

## [1.4.0] - 2019-04-23
### Added
- Kubernetes authentication can now work externally from Kubernetes

### Changed
- Moved changelog validation up in CI pipeline

## [1.3.7] - 2019-03-27
### Changed
- Updated links to Policy & Cryptography reference in API documentation
- Updated conjur-policy-parser to
  [v3.0.3](https://github.com/conjurinc/conjur-policy-parser/blob/conjur-oss/CHANGELOG.md#v303).
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

[Unreleased]: https://github.com/cyberark/conjur/compare/v1.20.0...HEAD
[1.20.0]: https://github.com/cyberark/conjur/compare/v1.19.5...v1.20.0
[1.19.5]: https://github.com/cyberark/conjur/compare/v1.19.3...v1.19.5
[1.19.3]: https://github.com/cyberark/conjur/compare/v1.19.2...v1.19.3
[1.19.2]: https://github.com/cyberark/conjur/compare/v1.19.1...v1.19.2
[1.19.1]: https://github.com/cyberark/conjur/compare/v1.19.0...v1.19.1
[1.19.0]: https://github.com/cyberark/conjur/compare/v1.18.5...v1.19.0
[1.18.5]: https://github.com/cyberark/conjur/compare/v1.18.4...v1.18.5
[1.18.4]: https://github.com/cyberark/conjur/compare/v1.18.3...v1.18.4
[1.18.3]: https://github.com/cyberark/conjur/compare/v1.18.2...v1.18.3
[1.18.2]: https://github.com/cyberark/conjur/compare/v1.18.1...v1.18.2
[1.18.1]: https://github.com/cyberark/conjur/compare/v1.18.0...v1.18.1
[1.18.0]: https://github.com/cyberark/conjur/compare/v1.17.8...v1.18.0
[1.17.8]: https://github.com/cyberark/conjur/compare/v1.17.7...v1.17.8
[1.17.7]: https://github.com/cyberark/conjur/compare/v1.17.6...v1.17.7
[1.17.6]: https://github.com/cyberark/conjur/compare/v1.17.3...v1.17.6
[1.17.3]: https://github.com/cyberark/conjur/compare/v1.15.0...v1.17.3
[1.15.0]: https://github.com/cyberark/conjur/compare/v1.14.2...v1.15.0
[1.14.2]: https://github.com/cyberark/conjur/compare/v1.14.1...v1.14.2
[1.14.1]: https://github.com/cyberark/conjur/compare/v1.14.0...v1.14.1
[1.14.0]: https://github.com/cyberark/conjur/compare/v1.13.2...v1.14.0
[1.13.2]: https://github.com/cyberark/conjur/compare/v1.13.1...v1.13.2
[1.13.1]: https://github.com/cyberark/conjur/compare/v1.13.0...v1.13.1
[1.13.0]: https://github.com/cyberark/conjur/compare/v1.12.0...v1.13.0
[1.12.0]: https://github.com/cyberark/conjur/compare/v1.11.7...v1.12.0
[1.11.7]: https://github.com/cyberark/conjur/compare/v1.11.6...v1.11.7
[1.11.6]: https://github.com/cyberark/conjur/compare/v1.11.5...v1.11.6
[1.11.5]: https://github.com/cyberark/conjur/compare/v1.11.4...v1.11.5
[1.11.4]: https://github.com/cyberark/conjur/compare/v1.11.3...v1.11.4
[1.11.3]: https://github.com/cyberark/conjur/compare/v1.11.2...v1.11.3
[1.11.2]: https://github.com/cyberark/conjur/compare/v1.11.1...v1.11.2
[1.11.1]: https://github.com/cyberark/conjur/compare/v1.11.0...v1.11.1
[1.11.0]: https://github.com/cyberark/conjur/compare/v1.10.0...v1.11.0
[1.10.0]: https://github.com/cyberark/conjur/compare/v1.9.0...v1.10.0
[1.9.0]: https://github.com/cyberark/conjur/compare/v1.8.1...v1.9.0
[1.8.1]: https://github.com/cyberark/conjur/compare/v1.7.0...v1.8.1
[1.8.0]: https://github.com/cyberark/conjur/compare/v1.7.4...v1.8.0
[1.7.4]: https://github.com/cyberark/conjur/compare/v1.7.3...v1.7.4
[1.7.3]: https://github.com/cyberark/conjur/compare/v1.7.2...v1.7.3
[1.7.2]: https://github.com/cyberark/conjur/compare/v1.7.1...v1.7.2
[1.7.1]: https://github.com/cyberark/conjur/compare/v1.7.0...v1.7.1
[1.7.0]: https://github.com/cyberark/conjur/compare/v1.6.0...v1.7.0
[1.6.0]: https://github.com/cyberark/conjur/compare/v1.5.1...v1.6.0
[1.5.1]: https://github.com/cyberark/conjur/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/cyberark/conjur/compare/v1.4.7...v1.5.0
[1.4.7]: https://github.com/cyberark/conjur/compare/v1.4.6...v1.4.7
[1.4.6]: https://github.com/cyberark/conjur/compare/v1.4.5...v1.4.6
[1.4.5]: https://github.com/cyberark/conjur/compare/v1.4.4...v1.4.5
[1.4.4]: https://github.com/cyberark/conjur/compare/v1.4.3...v1.4.4
[1.4.3]: https://github.com/cyberark/conjur/compare/v1.4.2...v1.4.3
[1.4.2]: https://github.com/cyberark/conjur/compare/v1.4.1...v1.4.2
[1.4.1]: https://github.com/cyberark/conjur/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/cyberark/conjur/compare/v1.3.7...v1.4.0
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
