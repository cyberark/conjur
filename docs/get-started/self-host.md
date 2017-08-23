---
title: Installing self-hosted Conjur
layout: page
---

You can easily download and run the Conjur software using the official
containers on Docker Hub.

## Pre-requisites

The easiest way to install and configure Conjur quickly is using Docker and
Docker Compose.

1. [install Docker][get-docker]
1. [install Docker Compose][get-docker-compose]

## Prepare to launch

1. download the Conjur quick-start configuration:

   ```sh-session
   $ curl -o docker-compose.yml https://try.conjur.org/get-started/quick-start.yml
   ```

1. generate your master data key and load it into the environment

   ```shell
   docker-compose run --no-deps --rm conjur data-key generate > data_key
   export CONJUR_DATA_KEY="$(< data_key)"
   ```

### Important: prevent data loss
The `conjurctl conjur data-key generate` command gives you a master data key.
Back it up in a safe location.

## Install and configure

1. run `docker-compose up -d` to run the Conjur server, database and client
1. create a default account (eg. `quick-start`):

   ```shell
   docker-compose exec conjur conjurctl account create quick-start
   ```

### Important: prevent data loss
The `conjurctl account create` command gives you the public key and admin API
key for the account you created. Back them up in a safe location.

## Connect

1. run `docker-compose exec client bash` to get a bash shell with the Conjur
   client software
1. initialize the Conjur client using the account name and admin API key you
   created:

   ```sh-session
   $ conjur init -u conjur -a quick-start # or whatever account you created
   $ conjur authn login -u admin
   Please enter admin's password (it will not be echoed):
   ```

## Explore

Conjur is installed and ready for use. Some suggestions:

```shell
conjur authn whoami
conjur help
conjur help policy load
```

[get-docker]: https://docs.docker.com/engine/installation
[get-docker-compose]: https://docs.docker.com/compose/install
