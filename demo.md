---
title: Demo
layout: page
---

## Build Possum

The build script creates a `deb` (Debian) package, plus a Docker container with the `deb` package installed and configured:

```sh-session
$ git clone git@github.com/conjurinc/possum.git
$ cd possum
possum $ ./build.sh
...
Successfully built af142b24a77d
possum$ docker images | grep possum
possum latest af142b24a77d
```

In the `demo` directory, you'll find a `docker-compose.yml` file which can be used to run a Postgresql database and Conjur in one step. It also contains some sample policies, which will be described here.

Enter the demo directory:

```sh-session
possum $ cd demo
possum/demo $ 
```

## Run the demo

Possum policies are used to define the infrastructure elements, their roles, and the permissions between them. Typical elements include:

* **User** A user.
* **Group** A group.
* **Host** A machine actor, such as a server, VM, container, job, script, or PaaS application.
* **Layer** A group of hosts.
* **Variable** An encrypted piece of data, such as a database password, cloud credential, or SSL private key.

Policies also include:

* **Grant** Gives a role, such as a Layer, to another role, such as a Host.
* **Permit** Gives a permission, such as `read` or `execute` on a protected element, such as a Host or Variable, to a role, such as a Group or Host.

Start the demo system:

```sh-session
$ ./start.sh
```

Open the UI:

```sh-session
# Find out the port of the UI
$ docker-compose port ui 443
0.0.0.0:32796
$ open https://172.28.128.3:32796/ui/
```

