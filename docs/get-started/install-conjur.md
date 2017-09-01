---
title: Install Conjur
layout: page
section: get-started
---

You can easily download and run the Conjur software using the [official containers on DockerHub](https://hub.docker.com/r/cyberark/conjur/).

{% include toc.md key='prereq' %}

The easiest way to install and configure Conjur quickly is using Docker and Docker Compose.

1. [Install Docker][get-docker]
1. [Install Docker Compose][get-docker-compose]

{% include toc.md key='launch' %}

1. Download the Conjur quick-start configuration:

   ```sh-session
   $ curl -o docker-compose.yml https://www.conjur.org/get-started/docker-compose.quickstart.yml
   ```

1. Generate your master data key and load it into the environment:

   ```shell
   docker-compose run --no-deps --rm conjur data-key generate > data_key
   export CONJUR_DATA_KEY="$(< data_key)"
   ```

<div class="alert alert-info" role="alert"> <strong>Prevent data loss:</strong><br>
  The <code>conjurctl conjur data-key generate</code> command gives you a master data key.
  Back it up in a safe location.
</div>

{% include toc.md key='install' %}

1. Run `docker-compose up -d` to run the Conjur server, database and client
1. Create a default account (eg. `quick-start`):

   ```shell
   docker-compose exec conjur conjurctl account create quick-start
   ```

 <div class="alert alert-info" role="alert"> <strong>Prevent data loss:</strong><br>
  The <code>conjurctl account create</code> command gives you the public key and admin API
  key for the account you created. Back them up in a safe location.
 </div>

{% include toc.md key='connect' %}

1. Run `docker-compose exec client bash` to get a bash shell with the Conjur
   client software
1. Initialize the Conjur client using the account name and admin API key you
   created:

   ```sh-session
   $ conjur init -u conjur -a quick-start # or whatever account you created
   $ conjur authn login -u admin
   Please enter admin's password (it will not be echoed):
   ```

{% include toc.md key='explore' %}

Conjur is installed and ready for use! Ready to do more?  Here are some suggestions:

```shell
conjur authn whoami
conjur help
conjur help policy load
```


{% include toc.md key='next-steps' %}

* Go through the [Conjur Tutorials](/tutorials/)
* View Conjur's [API Documentation](/api.html)

[get-docker]: https://docs.docker.com/engine/installation
[get-docker-compose]: https://docs.docker.com/compose/install
