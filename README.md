# Conjur

Conjur is an identity and authorization service for infrastructure.

[![Join Conjur Slack](https://slackin-conjur.herokuapp.com/badge.svg)](https://slackin-conjur.herokuapp.com)
[![Stories in Ready](https://badge.waffle.io/conjurinc/jenkins-seed.png?label=ready&title=Ready)](http://waffle.io/conjurinc/jenkins-seed)

---

Conjur provides:

* **A role-based access policy language** which is used to define system components, their roles, privileges and metadata.
* **A REST web service** to:
  * Enroll and revoke identities.
  * List roles and perform permission checks.
  * Store and serve secrets.
  * Receive and store audit records.
* **Integrations** with other popular software in the cloud toolchain such as IaaS, configuration management, continuous integration (CI), container management and cloud orchestration.

For more information, visit [try.conjur.org](https://try.conjur.org).

## Build the Docker images

Conjur is packaged primarily as a Docker image. To build it:

```sh-session
$ ./build.sh
...
Successfully built 9a18a1396977
$ docker images | grep conjur
conjurinc/conjur latest a8229592474c 7 minutes ago 560.7 MB
conjur           latest a8229592474c 7 minutes ago 560.7 MB
conjur-dev       latest af98cb5b2a68 4 days ago    639.9 MB
```

The API documentation is generated using a separate image. To build that image and generate the docs:

```sh-session
$ apidocs/build.sh
$ docker run --rm conjurinc/possum-apidocs > api.html
$ open api.html  # To see the docs in your browser
```

## Development environment

The `dev` directory contains a `docker-compose` file which brings up a development environment consisting of a database container (`pg`), and `conjur` container with the source code mounted into the directory `/src/conjur`.

To use it, first build Conjur from the project directory. Then:

```sh-session
$ cd dev
$ ./start.sh
...
root@f39015718062:/src/conjur#
```

Once the start.sh script finishes, you're in a Bash shell in the Conjur container.

### Run the server

To run the Conjur server:

```sh-session
root@f39015718062:/src/conjur# conjurctl server
<database migration>
<find or create the token-signing key>
<web server startup messages>
* Listening on tcp://localhost:3000
Use Ctrl-C to stop
```

The `conjurctl server` script performs the following:

* Wait for the database to be available
* Create and/or upgrade the database schema according to the `db/migrate` directory
* Find or create the token-signing key
* Start the web server

### Tests

Conjur has `rspec` and `cucumber` tests.

#### RSpec

RSpec tests are easy to run from within the `conjur` container:

```sh-session
root@aa8bc35ba7f4:/src/conjur# rspec
Run options: exclude {:performance=>true}

Randomized with seed 62317
.............................................

Finished in 3.84 seconds (files took 3.33 seconds to load)
45 examples, 0 failures
```

#### Cucumber

Cucumber tests require the Conjur server to be running. It's easiest to achieve this by starting Conjur in one container, and running Cucumber from another. Run the service in the `conjur` container:

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

There are two cucumber suites: `api` and `policy`. They are located in subdirectories of `./cucumber`.

Run the cukes:

```sh-session
root@9feae5e5e001:/src/conjur# cd cucumber/api
root@9feae5e5e001:/src/conjur/cucumber/api# cucumber
...
27 scenarios (27 passed)
101 steps (101 passed)
0m4.404s
```

# Architecture

Conjur is designed to run in a Docker container(s), using Postgresql as the backing data store. It's easy to run both Conjur and Postgresql in Docker; see the `demo` directory for an example.

## DATABASE_URL

Conjur uses the `DATABASE_URL` environment variable to connect to the database. Typical options for this URL are:

* Local linked `pg` container
* External managed database such as AWS RDS.

## Database initialization

Conjur creates and/or updates the database schema automatically when it starts up. Migration scripts are located in the `db/migrate` directory.

## Secrets and keys

Conjur performs some operations which require storage and management of encrypted data. For example:

* Users and Hosts can have associated API keys, which are stored encrypted in the database.
* The `authenticate` function issues a signed JSON token. The signing key is a 2048 bit RSA key which is stored encrypted in the database.

Data is encrypted in and out of the database using [Slosilo](https://github.com/conjurinc/slosilo), a library which provides:

* Symmetric encryption using AES-256-GCM.
* A mixin for easy encryption of object attributes into the database.
* Asymmetric encryption and signing.
* A keystore in a Postgresqsl, for easy storage and retrieval of keys.

The Slosilo project has been verified by a professional cryptographic audit. Contact Conjur Inc for more details.

When you start Conjur, you must provide a Base64-encoded master data key in the environment variable `CONJUR_DATA_KEY`. You can generate a data key using the following command:

```
$ docker run --rm possum data-key generate
```

Do NOT lose the data key, or all the encrypted data will be unrecoverable.

## Account management

Conjur supports the simultaneous operation of multiple separate accounts within the same database. In other words, it's multi-tenant.

Each account (also called "organization account") has its own token-signing private key. When a role is authenticated, the HMAC of the access token is computed using the signing key of the role's account.

Accounts can be listed, created, and deleted via the `/accounts` service. Permission to use this service is controlled by the built-in resource `!:webservice:accounts`. Note that `!` is itself an organization account, and therefore privileges on the `!:webservice:accounts` can be managed via policies.

# Licensing

The Conjur server (as in, the code within this repository) is licensed under the Free Software Foundation's [GNU AGPL v3.0](https://www.gnu.org/licenses/agpl-3.0.html). This license was chosen to ensure that all contributions to the Conjur server are made available to the community. Commercial licenses are also available from [CyberArk](https://www.cyberark.com).

The Conjur API clients and other extensions are licensed under the [Apache Software License v2.0](http://www.apache.org/licenses/LICENSE-2.0).
