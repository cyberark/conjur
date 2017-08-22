---
title: Install Conjur CLI
layout: page
section: get-started
---

{% include toc.md key='get' %}

{% include toc.md key='get' section='docker' %}

<<<<<<< HEAD:docs/get-started/install-conjur-cli.md
You can easily download and run the Conjur CLI using the official pre-built images hosted by Docker Hub.
=======
# How to get the Conjur client
>>>>>>> Streamlines and updates CLI installation instructions:docs/installation/client.md

You can easily download and run the Conjur client (command line interface) using
the [official container on Docker Hub][dockerhub].

[dockerhub]: https://hub.docker.com/r/conjurinc/cli5/

1. [install Docker][get-docker]
1. run `docker pull cyberark/conjur`
1. launch a Conjur container:

   ```sh-session
   $ docker run --rm \
            -it -v $PWD:/work
            cyberark/conjur
   root@f58447f9a535:/#
   ```

1. run `conjur help`

   ```sh-session
   root@f58447f9a535:/# conjur help
   NAME
     conjur - Command-line toolkit for managing roles, resources and privileges

   SYNOPSIS
     conjur [global options] command [command options] [arguments...]
   […]
   ```

[get-docker]: https://docs.docker.com/engine/installation

<<<<<<< HEAD:docs/get-started/install-conjur-cli.md
And here's how to run a single Conjur command (without arguments, it prints the help string):
=======
When you run the container with interactive mode (`-it`), then you will get an
interactive `bash` shell.
>>>>>>> Streamlines and updates CLI installation instructions:docs/installation/client.md

Otherwise, you will run a single `conjur` command. The container is stateless
and destroyed after each command, so you need to put your credentials and
configuration into the environment like so:

```sh-session
$ docker run --rm \
    -e CONJUR_APPLIANCE_URL=http://conjur \
    -e CONJUR_ACCOUNT=myorg \
    -e CONJUR_AUTHN_LOGIN=admin \
    -e CONJUR_AUTHN_API_KEY=the-secret-api-key \
    conjurinc/cli5
NAME
    conjur - Command-line toolkit for managing roles, resources and privileges
[…]
```

{% include toc.md key='configure' %}

## Configuring the client

The Conjur command-line interface requires two settings to connect to the
server. You can configure these two settings along with some optional ones using
either the environment or using files.

{% include toc.md key='configure' section='environment' %}

To configure using the environment, export the following variables:

* **CONJUR_APPLIANCE_URL** The URL to the Conjur server (example: `http://conjur`)
* **CONJUR_ACCOUNT** The organization account name (example: "mycorp").

If your Conjur server is using a self-signed certificate, you can establish SSL
trust to Conjur with one of the following:

* **CONJUR_SSL_CERTIFICATE** The SSL certificate.
* **CONJUR_CERT_FILE** The path to the certificate file on disk.

<div class="note">
  <strong>Note</strong>
  Certificate configuration is not required if you are running Conjur in dev
  mode without HTTPS, or if you are running Conjur with HTTPS and the
  certificate is already trusted by your operating system.
</div>

You can configure a shell session for the CLI by exporting the variables shown
above. For example:

```sh-session
$ export CONJUR_APPLIANCE_URL=http://conjur
$ export CONJUR_ACCOUNT=mycorp
$ conjur authn login admin
Please enter admin's password (it will not be echoed): *******
Logged in
```

{% include toc.md key='configure' section='conjur-init' %}

You can use the command `conjur init` to automatically configure the connection
settings and save them to configuration files which will persist across
sessions. This is especially useful with certificates because it will fetch the
server certificate and show you how to verify its fingerprint.

Here's an example:

```sh-session
$ conjur init
Enter the URL of your Conjur service: https://conjur

SHA1 Fingerprint=08:3B:71:72:02:43:6E:CA:ED:42:86:93:BA:7E:DF:81:C4:BC:62:30

Please verify this certificate on the appliance using command:
    openssl x509 -fingerprint -noout -in ~conjur/etc/ssl/conjur.pem
Trust this certificate (yes/no): yes
Enter your organization account name: mycorp
Wrote certificate to /root/conjur-mycorp.pem
Wrote configuration to /root/.conjurrc
```

Two configuration files are saved to your home directory:

* **$HOME/conjur-$account.pem** The server certificate.
* **$HOME/.conjurrc** A YAML file containing configuration settings.

Here's an example of `$HOME/.conjurrc`:

```yaml
account: mycorp
appliance_url: https://conjur
cert_file: "/root/conjur-mycorp.pem"
```

<<<<<<< HEAD:docs/get-started/install-conjur-cli.md
You can create these files yourself without assistance from `conjur init` once you have obtained them once.
=======
You can create these files yourself without assistance from `conjur init` once
you have obtained them once.
>>>>>>> Streamlines and updates CLI installation instructions:docs/installation/client.md

You can also change the location where the CLI looks for the `.conjurrc` file by
setting the environment variable `$CONJURRC`. For example, to configure the CLI
to find the config file in `/etc/`:

```shell
export CONJURRC=/etc/conjur.conf
```

This is the recommended location when the Conjur configuration is installed
system-wide. Note that neither the Conjur configuration nor the server SSL
certificate are secret data. They can be safely distributed in the following
ways:

<<<<<<< HEAD:docs/get-started/install-conjur-cli.md
* Committed to source control.
* Distributed through configuration management.
* Baked into VM and container images.
=======
* committed to source control
* distributed through configuration management
* baked into VM and container images
>>>>>>> Streamlines and updates CLI installation instructions:docs/installation/client.md

{% include toc.md key='login' %}

## Basic CLI workflow

Once you've downloaded the client, you'll login to Conjur. If you started
the server yourself, you'll need the `admin` API key or password. If
someone else is managing the Conjur server, they will provide you with
your login information.

```sh-session
$ conjur authn login
Enter your username to log into Conjur: admin
Enter password for user admin (it will not be echoed):
Logged in
```

You can show your current logged-in user with `conjur authn whoami`:

```sh-session
$ conjur authn whoami
{"account":"mycorp","username":"admin"}
```
