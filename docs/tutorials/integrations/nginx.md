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

[NGINX]: https://www.nginx.com

### Prerequisites

This tutorial requires Docker and a terminal application. Prepare by following
the prerequisite instructions found on [Install Conjur][prerequisites].

[prerequisites]: /get-started/install-conjur.html#prerequisites

Additionally, you will need the tutorial files from the Conjur source code
repository. Here's how you get them:

1. Install Git: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
1. Clone the Conjur repository
   
   In your terminal application, run:
   ```sh-session
   $ git clone https://github.com/cyberark/conjur.git
   ```
   This will create a folder called `conjur` in the current directory.

### The Good Part

To start out our experience on a high note, let's get the full Conjur+TLS stack
up and running so we can inspect it.

The tutorial script will install Conjur and NGINX, configure them to work
together, and connect a Conjur client to the running server. This is a full
end-to-end working installation to allow you to see how the pieces fit.

```sh-session
$ # start the Conjur+NGINX tutorial servers
$ cd conjur/docs/tutorials/integrations/nginx
$ ./start.sh
```

Take a look at the logs for the Conjur or NGINX servers:

```sh-session
$ # in the 'nginx' directory we navigated to previously:
$ docker-compose logs conjur
$ docker-compose logs proxy
```

Run some commands in the Conjur client:

```sh-session
$ # in the 'nginx' directory we navigated to previously:
$ docker-compose exec client bash
# conjur authn whoami
# conjur list
```

#### What's happening here?

When you read the Conjur access logs, you'll note that the Conjur server is
listening on port 80 (*insecure http*) inside its container. However, that port
is not exposed except on the local Docker network, so requests from the Internet
and LAN are unable to reach it.

Meanwhile, the NGINX container is exposing its port 443 (*https*) to the outside
network and proxying the traffic through to Conjur.

## Breaking Down the Tutorial

These files show how the proxy setup works. Note that, while this tutorial uses
Docker containers and NGINX, there's nothing magic about those technologies. You
can replicate the same strategy using a different endpoint such as
[HAProxy][haproxy-tls] and services that run in virtual machines or on bare
metal. To create a tutorial that can run as conveniently on a laptop as in the
cloud, we provide this setup.

[haproxy-tls]: https://www.haproxy.com/documentation/aloha/7-0/haproxy/tls/

### docker-compose.yml

This file declares services to be used in the tutorial. Let's break down each declaration:

```yaml
database:
  image: postgres:9.3
```

Conjur requires a Postgres database to store encrypted secrets and other data.
This service uses the [official Postgres image][postgres-image] from DockerHub.

#### Production tip

Just as we use a proxy in this tutorial to encrypt & authenticate traffic to the
Conjur server using TLS, you will also want to use TLS for your production
Postgres database. If you're using [Amazon RDS][rds], it already has TLS support
built-in. If you're hosting your own database, you'll want to use a technique
similar to the one described here in order to secure its traffic.

[rds]: https://aws.amazon.com/rds/

---

```yaml
conjur:
  image: cyberark/conjur
  command: server
  environment:
    DATABASE_URL: postgres://postgres@database/postgres
    CONJUR_DATA_KEY:
  depends_on: [ database ]
```

The Conjur service uses the image provided by CyberArk, connected to the
database service we just defined. The empty `CONJUR_DATA_KEY` field means that
Docker will pull that value in from the local environment. (Note later on that
in the tutorial script we export this value.)

Note also what's **not** present in these first two service definitions: exposed
ports. These services are only accessible on the local private Docker network,
not to the Internet or to the Local Area Network (LAN).

---

```yaml
proxy:
  image: nginx:1.13.6-alpine
  ports:
    - "8443:443"
  volumes:
    - ./default.conf:/etc/nginx/conf.d/default.conf:ro
    - ./tls/nginx.key:/etc/nginx/nginx.key:ro
    - ./tls/nginx.crt:/etc/nginx/nginx.crt:ro
  depends_on: [ conjur ]
```

The proxy service uses the [official NGINX image][nginx-image] from DockerHub.
It depends on the Conjur service, connecting using the local private Docker
network. Unlike the Conjur or database services, it exposes a port (443, the
standard port for HTTPS connections) to the Internet. This will serve as the TLS
gateway for Conjur.

This service defines three volumes: the NGINX config file, a self-signed
certificate, and a private key related to the certificate. Explanation of those
files follows below. The files are made accessible from the local file system
for read-only access by the container.

#### Production tips

For the convenience of a tutorial, we automatically generate a self-signed
certificate and provide it to the proxy service. For reasons that are described
in more detail [below](#tlstlsconf), this is unsuitable for production Conjur
deployments.

You can use your own certificate here by providing it to the container as a
volume. This allows your clients to verify that they are talking to the
authentic Conjur server. Your security team can provide certificates for your
organization, or you can create a certificate for any domain or sub-domain you
control with [certbot][certbot], which uses [Let's Encrypt][lets-encrypt] to
provide certificates for no cost.

To avoid conflicting with other services that might be running on the tutorial
user's port 443, we remap the port to 8443. On the production machine, the port
mapping should be changed to "443:443" instead of "8443:443".


[certbot]: https://certbot.eff.org/
[lets-encrypt]: https://letsencrypt.org/

---

```yaml
client:
  image: conjurinc/cli5
  depends_on: [ proxy ]
  entrypoint: sleep
  command: infinity
```

This service uses the `cli5` image with Conjur CLI pre-installed for convenient
tinkering. It is connected to the proxy service, allowing it to access Conjur
via TLS.

The "sleep" and "infinity" bits ensure that this container stays up for the
duration of the demo. Without these options, the `conjurinc/cli5` image gives
you an ephemeral stateless client container that performs a single command and
exits, a desirable behavior for common ops use cases.

[postgres-image]: https://hub.docker.com/_/postgres/
[nginx-image]: https://hub.docker.com/_/nginx/

### default.conf

This configuration file tells NGINX how to use TLS and behave as a proxy for
Conjur.

```nginx
listen              443 ssl;
server_name         proxy;
access_log          /var/log/nginx/access.log;
```

This block sets up a few basic properties of the NGINX server. Its hostname is
`proxy`, it listens on the standard port for HTTPS (port 443) and it has a
location for its access logs, useful for monitoring traffic.

---

```nginx
ssl_certificate     /etc/nginx/nginx.crt;
ssl_certificate_key /etc/nginx/nginx.key;
```

This block gives NGINX its directions on how to perform TLS ("ssl" is a name
for an older standard for TLS and is still often used interchangeably.)

The `certificate` is a public key, and the `certificate_key` is the
corresponding private key. NGINX maintains [documentation][nginx-https] about
how to configure the server for HTTPS, including production optimization
guidelines and the values of many default settings, so that is worth reading.

[nginx-https]: https://nginx.org/en/docs/http/configuring_https_servers.html

---

```nginx
location / {
  proxy_pass http://conjur;
}
```

This part instructs NGINX to proxy incoming traffic (secured by TLS) through to
the Conjur server.

### tls/tls.conf

This file describes to `openssl` what options to use when generating a
self-signed certificate. This allows you to use TLS in testing and staging, but
it does not allow clients to automatically authenticate the identity of the
Conjur server.

#### Production tip

Don't use a self-signed certificate in production. It's better than nothing, but
it's not a sustainable security practice because you're going to have to
manually verify that you're not talking to a man in the middle.

Instead, ask your security team to provide a certificate signed by a trusted
root and use that instead.

#### Modifying tls.conf for development use

These are blocks that you might want to change:

```ini
[ dn ]
C=US
ST=Wisconsin
L=Madison
O=CyberArk
OU=Onyx
CN=proxy
```

This block describes the distinguished name of the certificate using the
(C)ountry, (ST)ate, (L)ocation, (O)rganization, (O)rganizational (U)nit, and
(C)ommon (N)ame. You'll want to change all these to suit your own organization.

---

```ini
[ alt_names ]
DNS.1 = localhost
DNS.2 = proxy
IP.1 = 127.0.0.1
```

This block describes the names by which the server will be known, including its
hostnames and IP addresses. You'll want to modify it to match the hostnames and
IP addresses you use.

### start.sh

Here's the outline of the tutorial flow. Read through the file to see what it
does to accomplish each step.

* Pull required containers from Docker Hub
* Remove containers, certs and keys created in earlier tutorial runs (if any)
* Create a self-signed certificate and key for TLS
* Generate a data key for Conjur encryption of data at rest
  - Move this key to a safe place before deploying in production!
* Start services and wait a little while for them to become responsive
* Create a new account in Conjur and fetch its API key
  - [Rotate the admin's API key][rotate-api-key] regularly!
* Configure the Conjur client and log in as admin

[rotate-api-key]: https://www.conjur.org/api.html#authentication-rotate-an-api-key

## Up and running

Now that we've got a TLS endpoint for our Conjur server, you can check it with
your web browser.

The status page is available at https://localhost:8443 but your browser will
warn you about the self-signed certificate. To override the warning and see the
page, you'll have to instruct your browser to trust the certificate. Once you
switch to using your own certificate, the browser warning will go away
automatically.
