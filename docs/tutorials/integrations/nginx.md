---
title: Tutorial - NGINX Proxy
layout: page
section: tutorials
description: Conjur Tutorial - NGINX
---

If you're deploying Conjur in production, you need to set up Transport Layer
Security so that requests made to the server are encrypted in transit.

*Note: if you use Conjur Enterprise, we handle this for you using an audited
implementation that works similar to the technique described here.*

## First: A Brief Primer On Transport Layer Security (TLS)

This gets at the heart of the issue we're trying to address with this tutorial.

Suppose you install Conjur and make it available at `http://conjur.local`. Then
you configure clients to fetch secrets from that address. When they
[authenticate][authn] using the API, they provide their identity by sending
their API key to the Conjur server. The Conjur server validates that the
identity is authentic, then checks that the provided ID is authorized to
[retrieve the secret][secret-get]. Assuming this check passes, the Conjur server
returns the secret value to the client.

However, this flow would be vulnerable in two ways. Suppose I were to
impersonate the Conjur server and listen with my own illegitimate server on
`http://conjur.local`. Then when your client goes to fetch a secret, I can take
the API key you send and impersonate you to the real Conjur server. Now I
control your identity and can learn your secrets without you finding out. This
is called a **man in the middle attack**.

Even if I'm not able to impersonate the Conjur server, I could still learn your
secrets by joining your network and listening for traffic coming and going from
the Conjur server. This is called **passive surveillance**.

### TLS defeats passive and active attacks

Transport Layer Security allows your client to verify that it's talking to the
real Conjur server, and it uses standard secure technology to encrypt your
secrets in transit. This means:

* Your Conjur server will be `https:` instead of `http:`, just like a secure
  website
* Because the client knows it's talking to the real server, the "man in the
  middle" will be exposed and the client won't leak any secret information
* Since the traffic to and from Conjur is scrambled using secure encryption,
  passive listeners on your network can't learn anything about the contents of
  your secrets

For these reasons, it is crucial to set up TLS correctly when you deploy Conjur.

### Protect Your Secrets

Do not leave this to chance: even a small flaw can totally compromise your
secrets. Setting up Conjur and TLS without the appropriate expertise is like
packing your own parachute and jumping out of a plane.

That doesn't mean you should close the tab and walk away. It means you should get
in touch with us and your own security team so we can ensure that you can employ
Conjur successfully.

[authn]: https://www.conjur.org/api.html#authentication-authenticate-post
[secret-get]: https://www.conjur.org/api.html#secrets-retrieve-a-secret-get

## Using NGINX To Proxy Traffic With TLS To Conjur

[NGINX][NGINX] is a web proxy that's Free Software and easy to configure. This
tutorial will show you how to use Docker to install Conjur and NGINX and
configure them to provide Conjur with TLS.

### Prerequisites

This tutorial requires Docker and a terminal application. Prepare by following
the prerequisite instructions found on [Install Conjur][prerequisites].

Additionally, you will need the tutorial files from the Conjur source code
repository. Here's how you get them:

1. Install Git: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
1. Clone the Conjur repository
   
   In your terminal application, run:
   ```sh-session
   $ git clone git@github.com:cyberark/conjur.git
   ```
   This will create a folder called `conjur` in the current directory.

### The Good Part

The tutorial script will install Conjur and NGINX, configure them to work
together, and connect a Conjur client to the running server. This is a full
end-to-end working installation to allow you to see how the pieces connect
together.

```sh-session
$ # start the Conjur+NGINX tutorial servers
$ cd conjur/docs/tutorials/integrations/nginx
$ ./start.sh
```

Take a look at the logs for the Conjur or NGINX servers:

```sh-session
$ docker-compose logs conjur
$ docker-compose logs proxy
```

Run some commands in the Conjur client:

```sh-session
$ docker-compose exec client bash
# conjur authn whoami
# conjur list
```

These files show how the proxy setup works:

* `docker-compose.yml` declares services and the connections between them
* `default.conf` configures NGINX to use a self-signed certificate for TLS and
  sets up a proxy to Conjur
* `tls/tls.conf` sets the parameters of the self-signed certificate
* `start.sh` shows the installation flow

### About that self-signed certificate

In production, don't use a self-signed certificate. It's better than nothing,
but it's not a sustainable security practice because you're going to have to
manually verify that you're not talking to a man in the middle.

Instead, ask your security team to provide a certificate signed by a trusted
root and modify `default.conf` to use that certificate instead.

[NGINX]: https://www.nginx.com
[prerequisites]: /get-started/install-conjur.html#prerequisites
