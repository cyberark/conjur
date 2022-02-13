# Contributing to Conjur

Thanks for your interest in Conjur. Before contributing, please take a moment to
read and sign our <a href="https://github.com/cyberark/community/blob/master/documents/CyberArk_Open_Source_Contributor_Agreement.pdf" download="conjur_contributor_agreement">Contributor Agreement</a>.
This provides patent protection for all Conjur users and allows CyberArk to enforce
its license terms. Please email a signed copy to <a href="oss@cyberark.com">oss@cyberark.com</a>.

For general contribution and community guidelines, please see the [community repo](https://github.com/cyberark/community).

- [Contributing to Conjur](#contributing-to-conjur)
  - [Prerequisites](#prerequisites)
    - [Prevent Secret Leaks](#prevent-secret-leaks)
  - [Build Conjur as a Docker image](#build-conjur-as-a-docker-image)
  - [Set up a development environment](#set-up-a-development-environment)
      - [LDAP Authentication](#ldap-authentication)
      - [Google Cloud Platform (GCP) Authentication](#google-cloud-platform-gcp-authentication)
      - [RubyMine IDE Debugging](#rubymine-ide-debugging)
      - [Visual Studio Code IDE Debugging](#visual-studio-code-ide-debugging)
    - [Development CLI](#development-cli)
      - [Step into the running Conjur container](#step-into-the-running-conjur-container)
      - [View the admin user's API key](#view-the-admin-users-api-key)
      - [Load a policy](#load-a-policy)
    - [Updating the API](#updating-the-api)
    - [Updating the database schema](#updating-the-database-schema)
  - [Testing](#testing)
    - [CI Pipeline](#ci-pipeline)
    - [RSpec](#rspec)
    - [Cucumber](#cucumber)
    - [Adding New Test Suites](#adding-new-test-suites)
      - [Spin up Open ID Connect (OIDC) Compatible Environment for testing](#spin-up-open-id-connect-oidc-compatible-environment-for-testing)
      - [Spin up Google Cloud Platform (GCP) Compatible Environment for testing](#spin-up-google-cloud-platform-gcp-compatible-environment-for-testing)
      - [Run all the cukes:](#run-all-the-cukes)
      - [Run just one feature:](#run-just-one-feature)
    - [Rake Tasks](#rake-tasks)
  - [Pull Request Workflow](#pull-request-workflow)
  - [Style guide](#style-guide)
  - [Changelog maintenance](#changelog-maintenance)
  - [Releasing](#releasing)
    - [Verify and update dependencies](#verify-and-update-dependencies)
    - [Update the version and changelog](#update-the-version-and-changelog)
    - [Tag the version](#tag-the-version)
    - [Add a new GitHub release](#add-a-new-github-release)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>


## Prerequisites

Before getting started, you should install some developer tools. These are not
required to deploy Conjur but they will let you develop using a standardized,
expertly configured environment.

1. [git][get-git] to manage source code
2. [Docker][get-docker] to manage dependencies and runtime environments
3. [Docker Compose][get-docker-compose] to orchestrate Docker environments
4. [Ruby version 3 or higher installed][install-ruby-3] - native installation or using [RVM][install-rvm].

[get-docker]: https://docs.docker.com/engine/installation
[get-git]: https://git-scm.com/downloads
[get-docker-compose]: https://docs.docker.com/compose/install
[install-ruby-3]: https://www.ruby-lang.org/en/documentation/installation/
[install-rvm]: https://rvm.io/rvm/install

### Prevent Secret Leaks
Pushing to github is a form of publication, especially when using a public repo. It is a good idea to use a hook to check for secrets before pushing code.
Follow this [link](https://github.com/cyberark/community/blob/master/Conjur/conventions/git-tips-and-tricks.md#preventing-leaks) to learn how to configure git checks for secrets before every push.

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
   - RubyMine and VS Code IDE, make sure you are in `/src/conjur-server` and run the following command: `rdebug-ide --port 1234 --dispatcher-port 26162 --host 0.0.0.0 -- bin/rails s -b 0.0.0.0 -u webrick`
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

### Updating the API

Are you planning a change to the Conjur API? This could involve adding a new endpoint, extending an
existing endpoint, or changing the response of an existing endpoint. **When you make changes to
the Conjur API, you must also update the [Conjur OpenAPI Spec](https://github.com/cyberark/conjur-openapi-spec).**

To prepare to make a change to the Conjur API, follow the process below:

1. Clone the [OpenAPI spec project](https://github.com/cyberark/conjur-openapi-spec) and create a branch.
1. Update the spec with your planned API changes and create a draft pull request; make sure it references
   the Conjur issue you are working on. Note: it is expected that the automated tests in your spec branch
   will fail, because they are running against the `conjur:edge` image which hasn't been updated with your
   API changes yet.
1. Return to your clone of the Conjur project, and make your planned changes to the Conjur API following
   the standard branch / review / merge workflow.
1. Once your Conjur changes have been merged and the new `conjur:edge` image has been published, rerun the
   automation in your OpenAPI pull request to ensure that the spec is consistent with your API changes. Have
   your spec PR reviewed and merged as usual.

Note: Conjur's current API version is in the `API_VERSION` file and should correspond to the OpenAPI version.

### Updating the database schema

The Conjur database schema is implemented as Sequel database migration files. To add
a new database migration, run the command inside the Conjur development container:

```sh-session
$ rails generate migration <migration_name>
   ...
   create    db/migrate/20210315172159_migration_name.rb
```

This creates a new file under `db/migrate` with the migration name prefixed by a
timestamp.

The initial contents of the file are similar to:

```ruby
Sequel.migration do
  up do
    ...
  end

  down do
    ...
  end
end
```

More documentation on how to write Sequel migrations is
[available here](https://github.com/jeremyevans/sequel/blob/master/doc/migration.rdoc).

Database migrations are applied automatically when starting Conjur with the
`conjurctl server` command.

## Testing

Conjur has `rspec` and `cucumber` tests, and an automated CI Pipeline.

Note on performance testing: set `WEB_CONCURRENCY: 0` - this configuration is
useful for recording accurate coverage data that can be used in
the[ci/docker-compose.yml](ci/docker-compose.yml) and
[conjur/ci/authn-k8s/dev/dev_conjur.template.yaml](conjur/ci/authn-k8s/dev/dev_conjur.template.yaml).
This isn't a realistic configuration and should not be used for benchmarking.

### CI Pipeline

The CI Pipeline is defined in the `Jenkinsfile`, and documented in [CI_README.md](./CI_README.md)

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

### Adding New Test Suites

When adding new test suites, please follow the guidelines in the top comments
of the file [`ci/test`](https://github.com/cyberark/conjur/blob/master/ci/test).

#### Spin up Open ID Connect (OIDC) Compatible Environment for testing

To run the cukes with an Open ID Connect (OIDC) compatible environment, run `cli`
with the `--authn-oidc` flag:

```sh-session
$ ./cli exec --authn-oidc
...
root@9feae5e5e001:/src/conjur-server#
```

#### Spin up Google Cloud Platform (GCP) Compatible Environment for testing

**Prerequisites**
- A Google Cloud Platform account. To create an account see https://cloud.google.com/.
- Google Cloud SDK installed. For information on how to install see https://cloud.google.com/sdk/docs
- Access to a running Google Compute Engine instance. 
- Access to predefined Google cloud function with the following [code](ci/authn-gcp/function/main.py).

To run the cukes with a Google Cloud Platform (GCP) compatible environment, run `cli`
with the `--authn-gcp` flag and pass the following:
1. The name of a running Google Compute Engine (GCE) instance. (for example: my-gce-instance)

2. The URL of the Google Cloud Function (GCF). (for example: https://us-central1-exmaple.cloudfunctions.net/idtoken?audience=conjur/cucumber/host/demo-host)

```sh-session
$ ./cli exec --authn-gcp --gce [GCE_INSTANCE_NAME] --gcf [GCF_URL]
...
root@9feae5e5e001:/src/conjur-server#
```

When running with `--authn-gcp` flag, the cli script executes another script which does the heavy lifting of 
provisioning the ID tokens (required by the tests) from Google Cloud Platform.
To run the GCP authenticator test suite:
```sh-session
root@9feae5e5e001:/src/conjur-server# cucumber -p authenticators_gcp cucumber/authenticators_gcp/features
```

#### Run all the cukes:
Below is the list of the available Cucumber suites:
  * api
  * authenticators_azure
  * authenticators_config
  * authenticators_gcp
  * authenticators_jwt
  * authenticators_ldap
  * authenticators_oidc
  * authenticators_status
  * manual-rotators
  * policy
  * rotators 
  
Each of the above suites can be executed using a profile of the same name.
For example, to execute the `api` suite, your command might look like the following:

```sh-session
root@9feae5e5e001:/src/conjur-server# cucumber --profile api  # runs api cukes
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

### Kubernetes specific Cucumber tests

Several cucumber tests are written to verify conjur works properly when 
authenticating to Kubernetes.  These tests have hooks to run against both 
Openshift and Google GKE.

The cucumber tests are located under `cucumber/kubernetes/features` and can be
run by going into the `ci/authn-k8s` directory and running:

```shell
$ summon -f [secrets.ocp.yml|secrets.yml] ./init_k8s.sh [openshift|gke]
$ summon -f [secrets.ocp.yml|secrets.yml] ./test.sh [openshift|gke]
```

- `init_k8s.sh` - executes a simple login to Openshift or GKE to verify
credentials as well as logging into the Docker Registry defined
- `test.sh` - executes the tests against the defined platform

#### Secrets file

The secrets file used for summons needs to contain the following environment
variables

  - openshift
    - `OPENSHIFT_USERNAME` - username of an account that can create 
      namespaces, adjust cluster properties, etc
    - `OPENSHIFT_PASSWORD` - password of the account
    - `OPENSHIFT_URL` - the URL of the RedHat CRC cluster
      - If running this locally - use `https://host.docker.internal:6443` so
         the docker container can talk to the CRC containers
    - `OPENSHIFT_TOKEN` - the login token of the above username/password
      - only needed for local execution because the docker container 
      executing the commands can't redirect for login
      - obtained by running the following command locally after login -
      `oc whoami -t`
  - gke
    - `GCLOUD_CLUSTER_NAME` - cluster name of the GKE environment in the cloud
    - `GCLOUD_ZONE` - zone of the GKE environment in the cloud
    - `GCLOUD_PROJECT_NAME` - project name of the GKE environment
    - `GCLOUD_SERVICE_KEY` - service key of the GKE environment
    
#### Local Execution Prerequisites

To execute the tests locally, a few things will have to be done:

  - Openshift
    - Download and install the RedHat Code Ready Container
      - This contains all the necessary pieces to have a local version of
        Openshift
    - After install, copy down the kubeadmin username/password and update the
      secrets.ocp.yml file with the password
    - Execute `oc whoami -t` and update the token property
  - GKE
    - Work with infrastructure to obtain a GKE environment

If the local revision of your files don't have a docker image built yet - build
the docker images using the following command:

```shell
$ ./build_locally.sh <sni cert file>
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
1. Change the API_VERSION file to reflect the correct
   [OpenAPI spec release](https://github.com/cyberark/conjur-openapi-spec/releases)
   if there has been an update to the API. **If the OpenAPI spec is out of date
   with the current API,** it will need to be updated and released before you
   can release this project.
1. Create a branch and commit these changes (including the changes to
   NOTICES.txt, if there are any). `Bump version to x.y.z` is an acceptable
   commit message.
1. Push your changes and get the PR reviewed and merged.

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

### Publishing images

Visit the [Red Hat project page](https://connect.redhat.com/project/5899451/images) once
the images have been pushed and manually choose to publish the latest release.
