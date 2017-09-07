# CyberArk Conjur

[![Join Conjur Slack](https://img.shields.io/badge/slack-open-e01563.svg)][slack]
[![Issues ready for work](https://img.shields.io/waffle/label/cyberark/conjur/ready.svg?label=issues%20ready%20for%20work)][waffle]
[![Issues in progress](https://img.shields.io/waffle/label/cyberark/conjur/in%20progress.svg)][waffle]
[![Conjur on Quay.io](https://img.shields.io/badge/quay%20build-automated-0db7ed.svg)][quay]
[![Follow Conjur on Twitter](https://img.shields.io/twitter/follow/conjurinc.svg?style=social&label=Follow%20%40ConjurInc)][twitter]

Conjur provides secrets management and machine identity for modern infrastructure.

[slack]: https://slackin-conjur.herokuapp.com "Join our Slack community"
[waffle]: https://waffle.io/cyberark/conjur "Conjur issues on Waffle.io"
[quay]: https://quay.io/repository/cyberark/conjur "Conjur container image on Quay.io"
[twitter]: https://twitter.com/intent/user?screen_name=ConjurInc "Follow Conjur on Twitter"

Conjur provides:

* **a role-based access policy language** to define system components, their
  roles, privileges and metadata
* **a REST web service** to:
  * enroll and revoke identities
  * list and search roles and data
  * perform permission checks
  * store and serve secrets
* **integrations** with other popular software in the cloud toolchain such as
  IaaS, configuration management, continuous integration (CI), container
  management and cloud orchestration

_Note: our badges and social media buttons never track you._

## Links

* [support](https://www.conjur.org/support.html)
* [API Documentation][api]

[api]: https://www.conjur.org/apidocs.html

# Development

We welcome contributions of all kinds to Conjur. See our [contributing
guide][contrib].

[contrib]: https://github.com/cyberark/conjur/blob/master/CONTRIBUTING.md

## Prerequisites

Before getting started, you should install some developer tools. These are not
required to deploy Conjur but they will let you develop using a standardized,
expertly configured environment.

1. [git][get-git] to manage source code
2. [Docker][get-docker] to manage dependencies and runtime environments
3. [Docker Compose][get-docker-compose] to orchestrate Docker environments

[get-docker]: https://docs.docker.com/engine/installation
[get-git]: https://git-scm.com/downloads
[get-docker-compose]: https://docs.docker.com/compose/install

## Build Conjur as a Docker image

It's easy to get started with Conjur and Docker:

1. install dependencies (as above)
2. clone this repository
3. run the build script in your terminal:

   ```sh-session
   $ ./build.sh
   ...
   Successfully built 9a18a1396977
   $ docker images | grep conjur
   conjurinc/conjur latest a8229592474c 7 minutes ago 560.7 MB
   conjur           latest a8229592474c 7 minutes ago 560.7 MB
   conjur-dev       latest af98cb5b2a68 4 days ago    639.9 MB
   ```

## Set up a development environment

The `dev` directory contains a `docker-compose` file which creates a development
environment with a database container (`pg`, short for *postgres*), and a
`conjur` server container with source code mounted into the directory
`/src/conjur`.

To use it:

1. install dependencies (as above)
2. build the Conjur image:

   ```sh-session
   $ ./build.sh
   ```
3. start the container:

   ```sh-session
   $ cd dev
   $ ./start.sh
   ...
   root@f39015718062:/src/conjur#
   ```

   Once the start.sh script finishes, you're in a Bash shell in the Conjur
   server container.

4. run the server

   ```sh-session
   root@f39015718062:/src/conjur# conjurctl server
   <various startup messages, then finally:>
   * Listening on tcp://localhost:3000
   Use Ctrl-C to stop
   ```

   The `conjurctl server` script performs the following:

   * wait for the database to be available
   * create and/or upgrade the database schema according to the `db/migrate`
     directory
   * find or create the token-signing key
   * start the web server

## Testing

Conjur has `rspec` and `cucumber` tests.

### RSpec

RSpec tests are easy to run from within the `conjur` server container:

```sh-session
root@aa8bc35ba7f4:/src/conjur# rspec
Run options: exclude {:performance=>true}

Randomized with seed 62317
.............................................

Finished in 3.84 seconds (files took 3.33 seconds to load)
45 examples, 0 failures
```

### Cucumber

Cucumber tests require the Conjur server to be running. It's easiest to achieve
this by starting Conjur in one container and running Cucumber from another. Run
the service in the `conjur` server container:

```sh-session
root@aa8bc35ba7f4:/src/conjur# conjurctl server
...
* Listening on tcp://localhost:3000
Use Ctrl-C to stop
```

Then start a second container to run the cukes:

```sh-session
$ ./cucumber.sh
...
root@9feae5e5e001:/src/conjur#
```

There are two cucumber suites: `api` and `policy`. They are located in
subdirectories of `./cucumber`.

#### Run all the cukes:

```sh-session
root@9feae5e5e001:/src/conjur# cd cucumber/api
root@9feae5e5e001:/src/conjur/cucumber/api# cucumber
...
27 scenarios (27 passed)
101 steps (101 passed)
0m4.404s
```

#### Run just one feature:

```sh-session
root@9feae5e5e001:/src/conjur# cucumber -r cucumber/api/features/support -r cucumber/api/features/step_definitions cucumber/api/features/resource_list.feature
```

## Documentation site

This repository also contains the entire source code for the [Conjur
documentation website][docs]. For instructions on how to work on the
site locally, visit the [docs README][docs-readme].

Or in brief:

```sh-session
$ docker-compose run --rm apidocs > docs/_includes/api.html
$ docker-compose up -d docs
$ open localhost:4000
```

[docs]: https://www.conjur.org "Conjur website"
[docs-readme]: docs/README.md "Conjur docs README"

# Architecture

Conjur is designed to run in a Docker container(s), using Postgresql as the
backing data store. It's easy to run both Conjur and Postgresql in Docker; see
the `demo` directory for an example.

## Database

### DATABASE_URL environment variable

Conjur uses the `DATABASE_URL` environment variable to connect to the database.
Typical options for this URL are:

* Local linked `pg` container
* External managed database such as AWS RDS.

## Database initialization

Conjur creates and/or updates the database schema automatically when it starts
up. Migration scripts are located in the `db/migrate` directory.

## Secrets and keys

Main article: [Conjur Cryptography](https://www.conjur.org/reference/cryptography.html)

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
Slack community for more details. (You can join [here][slack].)

### Important: avoid data loss

When you start Conjur, you must provide a Base64-encoded master data key in the
environment variable `CONJUR_DATA_KEY`. You can generate a data key using the
following command:

```
$ docker run --rm conjur data-key generate
```

Do NOT lose the data key, or all the encrypted data will be unrecoverable.

## Account management

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

# Licensing

The Conjur server (as in, the code within this repository) is licensed under the
Free Software Foundation's [GNU AGPL v3.0][agpl]. This license was chosen to
ensure that all contributions to the Conjur server are made available to the
community. Commercial licenses are also available
from [CyberArk](https://www.cyberark.com).

The Conjur API clients and other extensions are licensed under
the [Apache Software License v2.0][apache]

[apache]: http://www.apache.org/licenses/LICENSE-2.0
[agpl]: https://www.gnu.org/licenses/agpl-3.0.html
