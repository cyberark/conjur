# Conjur

[![Conjur on DockerHub](https://img.shields.io/docker/pulls/cyberark/conjur.svg)](https://hub.docker.com/r/cyberark/conjur/)
[![Conjur on Quay.io](https://img.shields.io/badge/quay%20build-automated-0db7ed.svg)](https://quay.io/repository/cyberark/conjur)

[![Join Conjur Slack](https://img.shields.io/badge/slack-open-e01563.svg)][slack]
[![Follow Conjur on Twitter](https://img.shields.io/twitter/follow/conjurinc.svg?style=social&label=Follow%20%40ConjurInc)][twitter]

[slack]: https://slackin-conjur.herokuapp.com "Join our Slack community"
[quay]: https://quay.io/repository/cyberark/conjur "Conjur container image on Quay.io"
[twitter]: https://twitter.com/intent/user?screen_name=ConjurInc "Follow Conjur on Twitter"

Conjur provides secrets management and machine identity for modern infrastructure:

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

## Community Support

Our primary channel for support is through our Slack community. More
here: [community support](https://www.conjur.org/support.html)

## Migrating to Conjur EE

Migrating data from Conjur Open Source to Conjur EE is simple using our
[migration guide][migration]

[migration]: design/MIGRATION.md

# Development

We welcome contributions of all kinds to Conjur. See our [contributing
guide][contrib].

[contrib]: https://github.com/cyberark/conjur/blob/master/CONTRIBUTING.md

## Prerequisites

Before getting started, you should install some developer tools. These are not
required to deploy Conjur but they will let you develop using a standardized,
expertly configured environment.

1. [git][get-git] to manage source code
1. [Docker][get-docker] to manage dependencies and runtime environments
1. [Docker Compose][get-docker-compose] to orchestrate Docker environments

[get-docker]: https://docs.docker.com/engine/installation
[get-git]: https://git-scm.com/downloads
[get-docker-compose]: https://docs.docker.com/compose/install

## Build Conjur as a Docker image

It's easy to get started with Conjur and Docker:

1. install dependencies (as above)
1. clone this repository
1. run the build script in your terminal:

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

**Note**: If you are going to debug Conjur using [RubyMine IDE](https://www.jetbrains.com/ruby/) or [Visual Studio Code IDE](https://code.visualstudio.com),
see [RubyMine IDE Debugging](#rubymine-ide-debugging) or [Visual Studio Code IDE debugging](#visual-studio-code-ide-debugging) respectively before setting up the development environment.

The `dev` directory contains a `docker-compose` file which creates a development
environment with a database container (`pg`, short for *postgres*), and a
`conjur` server container with source code mounted into the directory
`/src/conjur-server`.

To use it:

1. Install dependencies (as above)
     
1. Start the container (and optional extensions):

   ```sh-session
   $ cd dev
   $ ./start
   ...
   root@f39015718062:/src/conjur-server#
   ```

   Once the `start` script finishes, you're in a Bash shell inside the Conjur
   server container.  To 

   After starting Conjur, your instance will be configured with the following:
   * Account: `cucumber`
   * User: `admin`
   * Password: Run `conjurctl role retrieve-key cucumber:user:admin` inside the container shell to retrieve the admin user API key (which is also the password)

1. Run the server

   ```sh-session
   root@f39015718062:/src/conjur-server# conjurctl server
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

   You may choose to debug Conjur using `pry.byebug`, RubyMine or Visual Studio Code IDEs. This will 
   allow you to work in the debugger without the server timing out. To do so, 
   run the following command instead of `conjurctl server`:
   - `pry.byebug`: `rails server -b 0.0.0.0 webrick`
   - RubyMine and VS Code IDE, make sure you are in `/src/conjur-server` and run the following command: `rdebug-ide --port 1234 --dispatcher-port 26162 --host 0.0.0.0 -- bin/rails s -b 0.0.0.0 webrick`
      - Now that the server is listening, debug the code via [RubyMine's](#rubymine-ide-debugging) or [VC Code's](#visual-studio-code-ide-debugging) debuggers.
   
1. Cleanup

    ```sh-session
    $ ./stop
    ```
    Running `stop` removes the running Docker Compose containers and the data key.

#### LDAP Authentication

To enable a user to log into Conjur using LDAP credentials, run `start` with the `--authn-ldap` flag:

```sh-session
$ cd dev
$ ./start --authn-ldap
...
root@f39015718062:/src/conjur-server#
```

The `--authn-ldap` flag will:
* Start an OpenLDAP container.
* Load a user `alice` with the password `alice` into the LDAP server.
* Load a policy `authn-ldap/test`, that grants `alice` the ability to authenticate via `http://localhost:3000/authn-ldap/test/cucumber/alice/authenticate` with the password `alice`.

Validate authentication using the username `alice` with the password `alice`:

```sh-session
$ curl -v -k -X POST -d "alice" http://localhost:3000/authn-ldap/test/cucumber/alice/authenticate
```

#### RubyMine IDE Debugging

If you are going to be debugging Conjur using [RubyMine IDE](https://www.jetbrains.com/ruby/), follow
these steps:

   1. Add a debug configuration
      1. Go to: Run -> Edit Configurations
      1. In the Run/Debug Configuration dialog, click + on the toolbar and 
      choose “Ruby remote debug”
      1. Specify a name for this configuration (i.e “debug Conjur server”)
      1. Specify these parameters:
         - Remote host - the address of Conjur. if it's a local docker environment the address 
         should be `localhost`, otherwise enter the address of Conjur
         - Remote port - the port which RubyMine will try to connect to for its debugging protocol. 
         The convention is `1234`. If you changing this, remember to change also the exposed port in
         `docker-compose.yml` & in the `rdebug-ide` command when running the server
         - Remote root folder: `/src/conjur-server`
         - Local port: 26162
         - Local root folder: `/local/path/to/conjur/repository`
      1. Click "OK"
      
   1. Create remote SDK
      1. Go to Preferences -> Ruby SDK and Gems
      1. In the Ruby SDK and Gems dialog, click + on the toolbar 
      and choose “New remote...”
      1. Choose “Docker Compose” and specify these parameters:
         - Server: Docker
            - If Docker isn't configured, click "New..." and configure it.
         - Configuration File(s): `./dev/docker-compose.yml`
            - Note: remove other `docker-compose` files if present.
         - Service: conjur
         - Environment variables: This can be left blank
         - Ruby or version manager path: ruby
      1. Click "OK" 

#### Visual Studio Code IDE Debugging

If you are going to be debugging Conjur using [VS Code IDE](https://code.visualstudio.com), follow
these steps:

   1. Go to: Debugger view
   1. Choose Ruby -> Listen for rdebug-ide from the prompt window, then you'll get the sample launch configuration in `.vscode/launch.json`.
   1. Edit "Listen for rdebug-ide" configuration in the `launch.json` file:
      - remoteHost - the address of Conjur. if it's a local docker environment the address 
      should be `localhost`, otherwise enter the address of Conjur
      - remotePort - the port which VS Code will try to connect to for its debugging protocol. 
      The convention is `1234`. If you changing this, remember to change also the exposed port in
      `docker-compose.yml` & in the `rdebug-ide` command when running the server
      - remoteWorkspaceRoot: `/src/conjur-server`

### Development CLI

As a developer, there are a number of common scenarios when actively working on Conjur.
The `./cli` script, located in the `dev` folder is intended to streamline these tasks.

```sh-session
$ ./cli --help

NAME
    cli - Development tool to simplify working with a Conjur container.

SYNOPSIS
    cli [global options] command [command options] [arguments...]

GLOBAL OPTIONS
    --help                                    - Show this message

COMMANDS

    exec                                      - Steps into the running Conjur container, into a bash shell.

    key                                       - Displays the admin user API key

    policy load <account> <policy/path.yml>   - Loads a conjur policy into the provided account.
```

#### Step into the running Conjur container

```sh-session
$ ./cli exec

root@88d43f7b3dfa:/src/conjur-server#
```

#### View the admin user's API key

```sh-session
$ ./cli key

3xmx4tn353q4m02f8e0xc1spj8zt6qpmwv178f5z83g6b101eepwn1
```

#### Load a policy

```sh-session
$ ./cli policy load <account> <policy/path/from/project/root.yml>
```

For most development work, the account will be `cucumber`, which is created when the development environment starts. The policy path must be inside the `cyberark/conjur` project folder, and referenced from the project root.

## Testing

Conjur has `rspec` and `cucumber` tests.

### RSpec

RSpec tests are easy to run from within the `conjur` server container:

```sh-session
root@aa8bc35ba7f4:/src/conjur-server# rspec
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
root@aa8bc35ba7f4:/src/conjur-server# conjurctl server
...
* Listening on tcp://localhost:3000
Use Ctrl-C to stop
```

Then, using the `dev/cli` script, step into the Conjur container to run the cukes:

```sh-session
$ ./cli exec
...
root@9feae5e5e001:/src/conjur-server#
```

To run the cukes with an Open ID Connect (OIDC) compatible environment, run `cli` 
with the `--authn-oidc` flag:

```sh-session
$ ./cli exec --authn-oidc
...
root@9feae5e5e001:/src/conjur-server#
```

#### Run all the cukes:

There are three different cucumber suites: `api`, `policy`, and `authenticators`. Each of these can be run using a profile of the same name:

```sh-session
root@9feae5e5e001:/src/conjur-server# cucumber --profile api               # runs api cukes
root@9feae5e5e001:/src/conjur-server# cucumber --profile policy            # runs policy cukes
root@9feae5e5e001:/src/conjur-server# cucumber --profile authenticators    # runs authenticators cukes
```


#### Run just one feature:

```sh-session
root@9feae5e5e001:/src/conjur-server# cucumber --profile api cucumber/api/features/resource_list.feature
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

## Authenticators

Conjur makes it easy to:

- Enable and disable built-in authenticators
- Secure access to authenticators using policy files
- Create custom authenticators

[Detailed authenticator design documentation](design/AUTHENTICATORS.md)

## Rotators

Conjur makes it easy to:

- Rotate variables regularly using built-in rotators
- Create custom rotators

[Detailed rotator design documenation](design/ROTATORS.md)

## Secrets and keys

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

# Versioning

Starting from version 0.1.0, this project follows
[Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Changelog maintenance

The [changelog file](CHANGELOG.md) is maintained based on
[Keep a Changelog](http://keepachangelog.com/en/1.0.0/) guidelines.

Each accepted change to the Conjur code (documentation and website updates
excepted) requires adding a changelog entry to the corresponding `Added`,
`Changed`, `Deprecated`, `Removed`, `Fixed` and/or `Security` sub-section (add
one as necessary) of the _Unreleased_ section in the changelog.

Bumping the version number after each and every change is not required,
advised nor expected. Valid reasons to bump the version are for example:

- enough changes have accumulated,
- an important feature has been implemented,
- an external project depends on one of the recent changes.

## Cutting a release

- Examine the changelog and decide on the version bump rank (major, minor, patch).
- Change the title of _Unreleased_ section of the changelog to the target
version.
  - Be sure to add the date (ISO 8601 format) to the section header.
- Add a new, empty _Unreleased_ section to the changelog.
  - Remember to update the references at the bottom of the document.
- Change VERSION file to reflect the change. This file is used by some scripts.
- Commit these changes. `Bump version to x.y.z` is an acceptable commit message.
- Tag the version using eg. `git tag -s v0.1.1`. Note this requires you to be
  able to sign releases. Consult the
  [github documentation on signing commits](https://help.github.com/articles/signing-commits-with-gpg/)
  on how to set this up.
  - git will ask you to enter the tag message. These will become the release notes.
  Format should be like this (note the subject line and message):

        Version x.y.z

        This is a human-readable overview of the changes in x.y.z. It should be a
        consise, at-a-glance summary. It certainly isn't a direct copy-and-paste
        from the changelog.

- Push the tag: `git push vx.y.z` (or `git push origin vx.y.z` if you are working from your local machine).
- Create a pull request to have the release acked and merged.
  - https://github.com/cyberark/conjur/pull/new/vx.y.z

Deleting and changing tags should be avoided. If in any doubt if the release will
be accepted, before creating a tag push the (VERSION and CHANGELOG) changes in
a branch and ask for approval. Then create and push a tag on `master` once it's
been merged.

# Licensing

The Conjur server (as in, the code within this repository) is licensed under the
Free Software Foundation's [GNU LGPL v3.0][lgpl]. This license was chosen to
ensure that all contributions to the Conjur server are made available to the
community. Commercial licenses are also available
from [CyberArk](https://www.cyberark.com).

The Conjur API clients and other extensions are licensed under
the [Apache Software License v2.0][apache]

[apache]: http://www.apache.org/licenses/LICENSE-2.0
[lgpl]: https://www.gnu.org/licenses/lgpl-3.0.en.html
