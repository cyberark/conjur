# Contributing to Conjur

Thanks for your interest in Conjur. Before contributing, please take a moment to
read and sign our <a href="https://github.com/cyberark/conjur/blob/master/Contributing_OSS/CyberArk_Open_Source_Contributor_Agreement.pdf" download="conjur_contributor_agreement">Contributor Agreement</a>.
This provides patent protection for all Conjur users and allows CyberArk to enforce
its license terms. Please email a signed copy to <a href="oss@cyberark.com">oss@cyberark.com</a>.

For general contribution and community guidelines, please see the [community repo](https://github.com/cyberark/community).

- [Prerequisites](#prerequisites)
- [Build Conjur as a Docker image](#build-conjur-as-a-docker-image)
- [Set up a development environment](#set-up-a-development-environment)
    + [LDAP Authentication](#ldap-authentication)
    + [RubyMine IDE Debugging](#rubymine-ide-debugging)
    + [Visual Studio Code IDE Debugging](#visual-studio-code-ide-debugging)
  * [Development CLI](#development-cli)
    + [Step into the running Conjur container](#step-into-the-running-conjur-container)
    + [View the admin user's API key](#view-the-admin-user-s-api-key)
    + [Load a policy](#load-a-policy)
- [Testing](#testing)
  
  * [RSpec](#rspec)
  * [Cucumber](#cucumber)
    + [Run all the cukes:](#run-all-the-cukes-)
    + [Run just one feature:](#run-just-one-feature-)
- [Pull Request Workflow](#pull-request-workflow)
- [Style guide](#style-guide)
- [Changelog maintenance](#changelog-maintenance)
- [Releasing](#releasing)
  * [Verify and update dependencies](#verify-and-update-dependencies)
  * [Update the version and changelog](#update-the-version-and-changelog)
  * [Tag the version](#tag-the-version)
  * [Add a new GitHub release](#add-a-new-github-release)
  * [Publishing AMIs](#publishing-amis)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>


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

1. Install dependencies (as above)
1. Clone this repository
1. Run the build script in your terminal:

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

#### Google Cloud Platform (GCP) Authentication

To enable a host to log into Conjur using GCP identity token, run `start` with the `--authn-gcp` flag.
Form more information on how to setup Conjur Google Cloud (GCP) authenticator, follow the official [documentation](https://www.conjur.org/). 

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

Note on performance testing: [ci/docker-compose.yml](ci/docker-compose.yml) and
[conjur/ci/authn-k8s/dev/dev_conjur.template.yaml](conjur/ci/authn-k8s/dev/dev_conjur.template.yaml)
set `WEB_CONCURRENCY: 0` a configuration that is useful for recording accurate
coverage data, but isn't a realistic configuration, so shouldn't be used for
benchmarking.

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

###### Run Cukes with Open ID Connect (OIDC) Compatible Environment

To run the cukes with an Open ID Connect (OIDC) compatible environment, run `cli`
with the `--authn-oidc` flag:

```sh-session
$ ./cli exec --authn-oidc
...
root@9feae5e5e001:/src/conjur-server#
```

###### Run Cukes with Google Cloud Platform (GCP) Compatible Environment

**Prerequisites**
- A Google Cloud Platform account. https://cloud.google.com/.
- Google Cloud SDK installed. https://cloud.google.com/sdk/docs
- Access to a running Google Compute Engine instance. 

To run the cukes with Google Cloud Platform (GCP) compatible environment, run `cli`
with the `--authn-gcp` flag and pass a name of a running Google Compute Engine (GCE) instance:

```sh-session
$ ./cli exec --authn-gcp my-gce-instance
...
root@9feae5e5e001:/src/conjur-server#
```

When running with `--authn-gcp` flag, the cli script executes another script which does the heavy lifting of provisioning the ID tokens (required by the tests) from Google Cloud Platform.

#### Run all the cukes:

There are three different Cucumber suites: `api`, `policy`, and `authenticators`. Each of these can be run using a profile of the same name:

```sh-session
root@9feae5e5e001:/src/conjur-server# cucumber --profile api               # runs api cukes
root@9feae5e5e001:/src/conjur-server# cucumber --profile policy            # runs policy cukes
root@9feae5e5e001:/src/conjur-server# cucumber --profile authenticators    # runs authenticators cukes
```


#### Run just one feature:

```sh-session
root@9feae5e5e001:/src/conjur-server# cucumber --profile api cucumber/api/features/resource_list.feature
```

### Rake Tasks

Rake tasks are easy to run from within the `conjur` server container:

- Get the next available error code from [errors](./app/domain/errors.rb)
  ```sh-session
  root@aa8bc35ba7f4:/src/conjur-server# rake error_code:next
  ```
    The output will be similar to
  ```sh-session
  The next available error number is 63 ( CONJ00063E )
  ```

## Pull Request Workflow

1. [Fork the project](https://help.github.com/en/github/getting-started-with-github/fork-a-repo)
2. [Clone your fork](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository)
3. Make local changes to your fork by editing files
3. [Commit your changes](https://help.github.com/en/github/managing-files-in-a-repository/adding-a-file-to-a-repository-using-the-command-line)
4. [Push your local changes to the remote server](https://help.github.com/en/github/using-git/pushing-commits-to-a-remote-repository)
5. [Create new Pull Request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork)

From here your pull request will be reviewed and once you've responded to all
feedback it will be merged into the project. Congratulations, you're a
contributor!

## Style guide

Use [this guide][style] to maintain consistent style across the Conjur project.

[style]: STYLE.md
[tests]: README.md#Testing
[issues]: https://github.com/cyberark/conjur/issues

## Changelog maintenance

The [changelog file](CHANGELOG.md) is maintained based on
[Keep a Changelog](http://keepachangelog.com/en/1.0.0/) guidelines.

Each accepted change to the Conjur code (documentation and website updates
excepted) requires adding a changelog entry to the corresponding `Added`,
`Changed`, `Deprecated`, `Removed`, `Fixed` and/or `Security` sub-section (add
one as necessary) of the _Unreleased_ section in the changelog.

Bumping the version number after each and every change is not required,
advised nor expected. Valid reasons to bump the version are for example:

- Enough changes have accumulated,
- An important feature has been implemented,
- An external project depends on one of the recent changes.

## Releasing

### Verify and update dependencies
1. Review the [NOTICES.txt](./NOTICES.txt) file and ensure it reflects the current
   set of dependencies in the [Gemfile](./Gemfile)
1. If a new dependency has been added, a dependency has been dropped, or a version
   has changed since the last tag - make sure the NOTICES file is up-to-date with
   the new versions

### Update the version and changelog
1. Examine the changelog and decide on the version bump rank (major, minor, patch).
1. Change the title of _Unreleased_ section of the changelog to the target
version.
   - Be sure to add the date (ISO 8601 format) to the section header.
1. Add a new, empty _Unreleased_ section to the changelog.
   - Remember to update the references at the bottom of the document.
1. Change VERSION file to reflect the change. This file is used by some scripts.
1. Commit these changes (including the changes to NOTICES.txt, if there are any).
   `Bump version to x.y.z` is an acceptable commit message.
1. Push your changes to a branch, and get the PR reviewed and merged.

### Tag the version
1. Tag the version on the master branch using eg. `git tag -s v1.2.3`. Note this
   requires you to be able to sign releases. Consult the
   [github documentation on signing commits](https://help.github.com/articles/signing-commits-with-gpg/)
   on how to set this up.
   - Git will ask you to enter the tag message, which should just be `v1.2.3`.

1. Push the tag: `git push v1.2.3` (or `git push origin v1.2.3` if you are working
   from your local machine).

Note: you may find it convenient to use the [`release`](./release) script to add the
tag. In general, deleting and changing tags should be avoided.

### Add a new GitHub release

1. Create a new release from the tag in the GitHub UI
1. Add the CHANGELOG for the current version to the GitHub release description

### Publishing AMIs

Run the [AMI builder](https://jenkins.conjur.net/job/cyberark--conjur-aws/job/master/build)
Jenkins job with `v#.#.#` as the `CONJUR_VERSION` parameter. Find the artifacts `us-east-1.yml`
and `copied-amis.json` to collect the AMI IDs for various regions.
