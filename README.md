# Possum

Possum is an identity and authorization service for infrastructure. It provides:

* **A role-based access policy language** which is used to define system components, their roles, privileges and metadata.
* **A REST web service** to:
  * Enroll and revoke identities.
  * List roles and perform permission checks.
  * Store and serve secrets.
  * Receive and store audit records.
* **Integrations** with other popular software in the cloud toolchain such as IaaS, configuration management, continuous integration (CI), container management and cloud orchestration.

For more information, visit [possum.io](https://possum.io).

# Development

## Build the Docker image

Possum is packaged primarily as a Docker image. To build it:

```sh-session
$ ./build
...
Successfully built 9a18a1396977
$ docker images | grep possum
possum                                         latest                     9a18a1396977        21 hours ago        559.6 MB
```

## Development environment

The `dev` directory contains a `docker-compose` file which brings up a development environment consisting of a database container (`pg`), and `possum` container with the source code mounted into the directory `/src/possum`.

To use it, first build Possum from the project directory. Then:

```sh-session
$ cd dev
dev $ ./start.sh
...
root@f39015718062:/src/possum#
```

Once the start.sh script finishes, you're in a Bash shell in the Possum container. `bundle` to install the dependencies:

```sh-session
root@f39015718062:/src/possum# bundle
...
Bundle complete! 31 Gemfile dependencies, 95 gems now installed.
Use `bundle show [gemname]` to see where a bundled gem is installed.
```

Create the database schema:

```sh-session
root@f39015718062:/src/possum# possum db migrate
```

Load a token-signing private key:

```sh-session
root@cefeae7ce399:/src/possum# possum token-key generate
Created and saved new token-signing key. Public key is:
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1zFSIzvP1aVdFBlTWYHn
ESahqe4uHmDiEy0Bn8aOLOVTQ1/5YLe6h0Pv7xCyuk2w++gDD9gs5lSKhv4HZjmL
EV+qx/kJCWJDQCDmOysOlCO9Iw5Uwxgi+x1JrV5MhlEy5uu7mxr3W/rHiNBSF3y4
x3VRCni8Hw2TkxcXVqDcXWxFs//aoDnrUoDQXvqky76CnGdGJ7Fx90KVkfhyCecw
E44+rnqd6bDt6UCkayA+U2+b8gFPHgEO4NGwuC58K2OL14MxZhldKGwj9rTd9S15
h5cAJh9zqy4DQ7xymrOGe2RGlq8aaQX8A+/tf3zVQdgVKITx28ESFi2V9Fj/emYj
aQIDAQAB
-----END PUBLIC KEY-----
```

### Run the server

To run the Possum server in development mode, use `rails s`:

```
root@f39015718062:/src/possum# rails s -b 0.0.0.0
=> Booting Puma
...
* Listening on tcp://0.0.0.0:3000
Use Ctrl-C to stop
```

### Tests

Possum has `rspec` and `cucumber` tests. 

#### RSpec

RSpec tests are easy to run from within the `possum` container:

```sh-session
root@aa8bc35ba7f4:/src/possum# rspec
Run options: exclude {:performance=>true}

Randomized with seed 62317
.............................................

Finished in 3.84 seconds (files took 3.33 seconds to load)
45 examples, 0 failures
```

#### Cucumber

Cucumber tests require the Possum server to be running. It's easiest to achieve this by starting Possum in one container, and running Cucumber from another. In the first container:

```sh-session
root@aa8bc35ba7f4:/src/possum# rails s -o 0.0.0.0
=> Booting Puma
...
* Listening on tcp://localhost:3000
Use Ctrl-C to stop
```

Run the cucumber container:

```sh-session
$ ./cucumber.sh
...
root@9feae5e5e001:/src/possum# 
```

Run the cukes:

```sh-session
root@9feae5e5e001:/src/possum# cucumber
...
27 scenarios (27 passed)
101 steps (101 passed)
0m4.404s
```

# Architecture

Possum is designed to run in a Docker container(s), using Postgresql as the backing data store. It's easy to run both Possum and Postgresql in Docker; see the `demo` directory for an example.

## DATABASE_URL

Possum uses the `DATABASE_URL` environment variable to connect to the database. Typical options for this URL are:

* Local linked `pg` container
* External managed database such as AWS RDS.

## Database initialization

Possum creates and/or updates the database schema automatically when it starts up. Migration scripts are located in the `db/migrate` directory.

## Secrets and keys

Possum performs some operations which require storage and management of encrypted data. For example: 

* Users and Hosts can have associated API keys, which are stored encrypted in the database.
* The `authenticate` function issues a signed JSON token. The signing key is a 2048 bit RSA key which is stored encrypted in the database.

Data is encrypted in and out of the database using [Slosilo](https://github.com/conjurinc/slosilo), a library which provides:

* Symmetric encryption using AES-256-GCM.
* A mixin for easy encryption of object attributes into the database.
* Asymmetric encryption and signing.
* A keystore in a Postgresqsl, for easy storage and retrieval of keys.

The Slosilo project has been verified by a professional cryptographic audit. Contact Conjur Inc for more details.

When you start Possum, you must provide a Base64-encoded master data key in the environment variable `POSSUM_DATA_KEY`. You can generate a data key using the following command:

```
$ docker run --rm possum data-key generate
```

Do NOT lose the data key, or all the encrypted data will be unrecoverable.

