# Conjur

[![Conjur on DockerHub](https://img.shields.io/docker/pulls/cyberark/conjur.svg)](https://hub.docker.com/r/cyberark/conjur/)
[![Maintainability](https://api.codeclimate.com/v1/badges/3754a79b22b9430040ba/maintainability)](https://codeclimate.com/github/cyberark/conjur/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/3754a79b22b9430040ba/test_coverage)](https://codeclimate.com/github/cyberark/conjur/test_coverage)

[![CyberArk Commons - ask](https://img.shields.io/badge/CyberArk%20Commons-ask-e01563.svg)][commons]
[![Follow Conjur on Twitter](https://img.shields.io/twitter/follow/conjurinc.svg?style=social&label=Follow%20%40ConjurInc)][twitter]

[commons]: https://discuss.cyberarkcommons.org/c/conjur/5 "Find answers on CyberArk Commons"
[twitter]: https://twitter.com/intent/user?screen_name=ConjurInc "Follow Conjur on Twitter"

Conjur provides secrets management and application identity for modern infrastructure:

* **Machine Authorization Markup Language ("MAML")**, a role-based
  access policy language to define system components & their roles,
  privileges and metadata
* **A REST web service** to:
  * manage identity life cycles for humans and machines
  * organize and search roles and data in your secrets infrastructure
  * authorize access to resources using a sophisticated permission model
  * store secrets and make them available securely
* **Integrations** throughout the cloud toolchain:
  * infrastructure as a service (IaaS)
  * configuration management
  * continuous integration and deployment (CI/CD)
  * container management and cloud orchestration

_Note: our badges and social media buttons never track you._

- [Getting Started](#getting-started)
  * [Compatibility](#compatibility)
- [Community Support](#community-support)
- [Migrating to Conjur EE](#migrating-to-conjur-ee)
- [Architecture](#architecture)
  * [Database](#database)
    + [DATABASE_URL environment variable](#database-url-environment-variable)
    + [Database initialization](#database-initialization)
  * [Authenticators](#authenticators)
  * [Rotators](#rotators)
  * [Secrets and keys](#secrets-and-keys)
    + [Important: avoid data loss](#important--avoid-data-loss)
  * [Account management](#account-management)
- [Versioning](#versioning)
- [Contributing](#contributing)
- [License](#license)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents
generated with markdown-toc</a></i></small>


## Getting Started 

Please refer to our [Quick Start Guide](https://www.conjur.org/get-started/quick-start/oss-environment/) for detailed information on using Conjur OSS for the first time, or, refer to the 
[Conjur docs](https://docs.conjur.org/Latest/en/Content/Resources/_TopNav/cc_Home.htm) for specific guides relating to setup, integrations, administration, and more.

### Compatibility 

We **strongly** recommend choosing the version of this project to use from the latest [Conjur OSS 
suite release](https://docs.conjur.org/Latest/en/Content/Overview/Conjur-OSS-Suite-Overview.html). 
Conjur maintainers perform additional testing on the suite release versions to ensure 
compatibility. When possible, upgrade your Conjur version to match the 
[latest suite release](https://docs.conjur.org/Latest/en/Content/ReleaseNotes/ConjurOSS-suite-RN.htm); 
when using integrations, choose the latest suite release that matches your Conjur version.

When upgrading your Conjur server running in a Docker Compose environment to the
latest suite release version, please review the
[upgrade instructions](./UPGRADING.md). For any questions, please contact us on [Discourse](https://discuss.cyberarkcommons.org/c/conjur/5).

## Community Support

Our primary channel for support is through our CyberArk Commons community
[here][commons]

## Migrating to Conjur EE

Migrating data from Conjur Open Source to Conjur EE is simple using our
[migration guide][migration]

[migration]: design/MIGRATION.md

## Architecture

Conjur is designed to run in a Docker container(s), using Postgresql as the
backing data store. It's easy to run both Conjur and Postgresql in Docker; see
the `demo` directory for an example.

### Database

#### DATABASE_URL environment variable

Conjur uses the `DATABASE_URL` environment variable to connect to the database.
Typical options for this URL are:

* Local linked `pg` container
* External managed database such as AWS RDS.

#### Database initialization

Conjur creates and/or updates the database schema automatically when it starts
up. Migration scripts are located in the `db/migrate` directory.

### Authenticators

Conjur makes it easy to:

- Enable and disable built-in authenticators
- Secure access to authenticators using policy files
- Create custom authenticators

[Detailed authenticator design documentation](design/authenticators/AUTHENTICATORS.md)

### Rotators

Conjur makes it easy to:

- Rotate variables regularly using built-in rotators
- Create custom rotators

[Detailed rotator design documenation](design/ROTATORS.md)

### Secrets and keys

Main article: [Conjur Cryptography](https://docs.conjur.org/Latest/en/Content/Get%20Started/cryptography.html)

Conjur uses industry-standard cryptography to protect your data.

Some operations require storage and management of encrypted data. For example:

* Roles can have associated API keys, which are stored encrypted in
  the database
* the `authenticate` function issues a signed JSON token; the signing key is a
  2048 bit RSA key which is stored encrypted in the database

Data is encrypted in and out of the database
using [Slosilo](https://github.com/conjurinc/slosilo), a library which provides:

* symmetric encryption using AES-256-GCM
* a Ruby class mixin for easy encryption of object attributes into the database
* asymmetric encryption and signing
* a keystore in a Postgresql database for easy storage and retrieval of keys

Slosilo has been verified by a professional cryptographic audit. Ask in our
CyberArk Commons community for more details. (You can join [here][commons].)

#### Important: avoid data loss

When you start Conjur, you must provide a Base64-encoded master data key in the
environment variable `CONJUR_DATA_KEY`. You can generate a data key using the
following command:

```
$ docker run --rm conjur data-key generate
```

Do NOT lose the data key, or all the encrypted data will be unrecoverable.

### Account management

Conjur supports the simultaneous operation of multiple separate accounts within
the same database. In other words, it's multi-tenant.

Each account (also called "organization account") has its own token-signing
private key. When a role is authenticated, the HMAC of the access token is
computed using the signing key of the role's account.

Accounts can be listed, created, and deleted via the `/accounts` service.
Permission to use this service is controlled by the built-in resource
`!:webservice:accounts`. Note that `!` is itself an organization account, and
therefore privileges on the `!:webservice:accounts` can be managed
via Conjur [policies](https://developer.conjur.net/policy).

## Versioning

Starting from version 0.1.0, this project follows
[Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Contributing

If you’re interested in running Conjur locally and learning about how it works,
please see our [Contributing Guide](./CONTRIBUTING.md). It includes helpful
instructions for Conjur development and debugging, including:
- [Development prerequisites](./CONTRIBUTING.md#prerequisites)
- [Building Conjur as a Docker image](./CONTRIBUTING.md#build-conjur-as-a-docker-image)
- [Setting up a local development environment](./CONTRIBUTING.md#set-up-a-development-environment)
- [Running the test suites](./CONTRIBUTING.md#testing)
- [Pull request workflow](./CONTRIBUTING.md#pull-request-workflow)
- [Style guide](./CONTRIBUTING.md#style-guide)
- [Changelog maintenance](./CONTRIBUTING.md#changelog-maintenance)

If you have any questions, please [open an issue](https://github.com/cyberark/conjur/issues/new/choose)
or [ask us on Discourse][commons].

## License

The Conjur server (as in, the code within this repository) is licensed under the
Free Software Foundation's [GNU LGPL v3.0][lgpl]. This license was chosen to
ensure that all contributions to the Conjur server are made available to the
community. Commercial licenses are also available
from [CyberArk](https://www.cyberark.com).

The Conjur API clients and other extensions are licensed under
the [Apache Software License v2.0][apache].

Copyright (c) 2020 CyberArk Software Ltd. All rights reserved.

[apache]: http://www.apache.org/licenses/LICENSE-2.0
[lgpl]: https://www.gnu.org/licenses/lgpl-3.0.en.html
