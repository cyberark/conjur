---
title: Installation - Self-Host
layout: page
---

# Installing self-hosted Conjur

You can easily download and run the Conjur software using the official
containers on Docker Hub.

1. [install Docker][get-docker]
1. [install Docker Compose][get-docker-compose]
1. run the Conjur self-host install script:

```sh-session
$ curl https://try.conjur.org/installation/self-host.sh | sh
```

1. run `docker-compose up` to run the Conjur server, database and client
1. run `docker-compose exec -it client bash` to get a bash shell with the Conjur
   client software

[get-docker]: https://docs.docker.com/engine/installation
[get-docker-compose]: https://docs.docker.com/compose/install
