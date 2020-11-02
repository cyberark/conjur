# Upgrading

This section describes how to upgrade a Conjur Server.

## Standard Process

The following steps describe a standard upgrade of the Conjur server, when deployed
using Docker Compose. These steps assume you have defined your Conjur image in
a service named `conjur`, and that you have access to the **Conjur data key**
that was used when you originally deployed your Conjur server.
1. In a local terminal session, set the `CONJUR_DATA_KEY` environment variable:
   ```
   export CONJUR_DATA_KEY=<Conjur data key content>
   ```
   *Note:* Information regarding the Conjur data key can be in this [article](https://www.conjur.org/blog/loading-your-database-credentials-at-runtime-with-conjur/).

2. Edit the Conjur image version in `docker-compose.yml` to reference the new
   version.

3. Pull the new Conjur image version:
   ```
   docker-compose pull conjur
   ```

4. Stop the Conjur container:
   ```
   docker-compose stop conjur
   ```

5. Bring up the Conjur service using the new image version without changing
   linked services:
   ```
   docker-compose up -d --no-deps conjur
   ```

6. View Docker containers and verify all are healthy, up and running:
   ```
   docker-compose ps -a
   ```

   It may also be useful to check if Conjur started successfully, which can be
   done by running
   ```
   $ docker-compose exec conjur conjurctl wait
    Waiting for Conjur to be ready...
    ...
    Conjur is ready!
   ```
   If Conjur does not report as ready please read the [troubleshooting section](#troubleshooting). 
   

### Troubleshooting

If you run through the steps above _without_ setting the `CONJUR_DATA_KEY`
environment variable first, you will be able to complete the steps without an
visible/explicit error message, but the logs of the new Conjur container will
show an error like:
```
$ docker-compose logs conjur_server
rake aborted!
No CONJUR_DATA_KEY
...
```

To fix this, set the `CONJUR_DATA_KEY` environment variable and run through
the [process](#standard-process) again. This time when you check the logs of the Conjur server
container you should see the service starting as expected:
```
$ docker-compose logs conjur_server
...
=> Booting Puma
=> Rails 5.2.4.3 application starting in production 
=> Run `rails server -h` for more startup options
[10] Puma starting in cluster mode...
[10] * Version 3.12.6 (ruby 2.5.1-p57), codename: Llamas in Pajamas
[10] * Min threads: 5, max threads: 5
[10] * Environment: development
[10] * Process workers: 2
[10] * Preloading application
[10] * Listening on tcp://0.0.0.0:80
[10] Use Ctrl-C to stop
[10] - Worker 0 (pid: 26) booted, phase: 0
[10] - Worker 1 (pid: 30) booted, phase: 0
```

## Version Specific Upgrade Instructions

### Version 1.9.0

When upgrading to version `1.9.0` and above, please ensure that you also upgrade your
[Ruby client library](https://github.com/cyberark/conjur-api-ruby) to at least `v5.3.4`.
The Ruby client changed to accommodate the changes in the REST API that were made in response to
this [security bulletin](https://github.com/cyberark/conjur/security/advisories/GHSA-qhjf-g9gm-64jq).

### Versions 1.8.0 and 1.8.1

#### Affected Upgrades:

Upgrading from versions `1.7.4` and below to versions `1.8.0` and `1.8.1`

#### Context:

Starting in version `1.8.0`, the hashing algorithm used to fingerprint and identify
encryption keys was changed from MD5 to a more secure SHA256. This fingerprint 
is stored in the Postgres database and must be updated to ensure a seamless
upgrade. However, the [standard upgrade process](#standard-process) does not address this
fingerprint update in both version `1.8.0` and `1.8.1`. A database migration,
which addresses this fingerprint update, is added in version `1.9.0`.

#### Recommendation:

Upgrade directly to versions `1.9.0` and above.
