# CyberArk Conjur

Conjur is a trust platform: an identity and authorization service that works with humans and machines.

[![Join Conjur Slack](https://slackin-conjur.herokuapp.com/badge.svg)][join-slack]
[![Stories tagged "Ready"](https://badge.waffle.io/conjurinc/jenkins-seed.png?label=ready&title=Ready)](http://waffle.io/conjurinc/jenkins-seed)

[join-slack]: https://slackin-conjur.herokuapp.com

---

Conjur provides:

* **a role-based access policy language** which is used to define system
  components, their roles, privileges and metadata
* **a REST web service** to:
  * enroll and revoke identities
  * list roles and perform permission checks
  * store and serve secrets
  * receive and store audit records
* **integrations** with other popular software in the cloud toolchain such as
  IaaS, configuration management, continuous integration (CI), container
  management and cloud orchestration

## Links

* try Conjur: [Start Here](https://try.conjur.org)
* [support](https://try.conjur.org/support.html)
* [API Documentation][api-doc]

[api-doc]: https://try.conjur.org/apidocs.html

# Development

We use Jenkins as our Continuous Integration server. CyberArk employees and
approved developers can view the current status here:
https://jenkins.conjur.net/job/possum/

To get access to Jenkins, ask in our Slack community. (You can
join [here][join-slack].)

### Development Dependencies

Before getting started, you should install some developer tools. These are not
required to deploy Conjur, but they will help you quickly get started.

1. [git][get-git] to manage source code
2. [Docker][get-docker] to manage dependencies and runtime environments
3. [docker-compose][get-docker-compose] to orchestrate Docker environments

## Build Conjur as a Docker image

It's easy to get started with Conjur and Docker:

1. install dependencies (as above)
2. clone this repository
3. run the build script in your terminal:

[get-docker]: https://docs.docker.com/engine/installation/
[get-git]: https://git-scm.com/downloads
[get-docker-compose]: https://docs.docker.com/compose/install/

   ```sh-session
   $ ./build.sh
   ...
   Successfully built 9a18a1396977
   $ docker images | grep conjur
   conjurinc/conjur latest a8229592474c 7 minutes ago 560.7 MB
   conjur           latest a8229592474c 7 minutes ago 560.7 MB
   conjur-dev       latest af98cb5b2a68 4 days ago    639.9 MB
   ```

## Build the API documentation from source

```sh-session
$ apidocs/dev.sh
$ open localhost:3000  # To see the docs in your browser
```

## Set up a development environment

The `dev` directory contains a `docker-compose` file which creates a development
environment with a database container (`pg`, short for *postgres*), and a
`conjur` container with source code mounted into the directory `/src/conjur`.

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
   container.

4. run the server

   ```sh-session
   root@f39015718062:/src/conjur# conjurctl server
   <database migration>
   <find or create the token-signing key>
   <web server startup messages>
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

RSpec tests are easy to run from within the `conjur` container:

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
the service in the `conjur` container:

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

Main article: [Conjur Cryptography](https://try.conjur.org/reference/cryptography.html)

Conjur uses industry-standard cryptography to protect your data.

Some operations require storage and management of encrypted data. For example:

* Users and Hosts can have associated API keys, which are stored encrypted in
  the database.
* The `authenticate` function issues a signed JSON token. The signing key is a
  2048 bit RSA key which is stored encrypted in the database.

Data is encrypted in and out of the database
using [Slosilo](https://github.com/conjurinc/slosilo), a library which provides:

* symmetric encryption using AES-256-GCM
* a Ruby class mixin for easy encryption of object attributes into the database
* asymmetric encryption and signing
* a keystore in a Postgresql database for easy storage and retrieval of keys

Slosilo has been verified by a professional cryptographic audit. Ask in our
Slack community for more details. (You can join [here][join-slack].)

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
therefore privileges on the `!:webservice:accounts` can be managed via policies.
