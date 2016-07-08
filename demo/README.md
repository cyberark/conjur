
Generate and export the data key:

```
$ docker run --rm possum rake generate-data-key 
POSSUM_DATA_KEY="4BzuAIRxEXq+HjXL7d5qS1mt2DDtNt9CeWV5rmTl6DA="
$ export POSSUM_DATA_KEY="4BzuAIRxEXq+HjXL7d5qS1mt2DDtNt9CeWV5rmTl6DA="
```

Generate and export the token signing key:

```sh-session
/src/possum # ssh-keygen -f ./id_rsa
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in ./id_rsa.
Your public key has been saved in ./id_rsa.pub.
The key fingerprint is:
7c:c3:60:d3:2b:c0:0a:ff:0a:2b:9f:f0:02:31:12:11 kgilpin@spudling-2.local
The key's randomart image is:
+--[ RSA 2048]----+
|Eo               |
|.    .   .       |
| ..   o + .      |
|+  o . + + .     |
|.o  o   S =      |
|.    .   o .     |
|o .   .          |
|oo + .           |
| += .            |
+-----------------+
/src/possum # export POSSUM_PRIVATE_KEY="$(cat id_rsa)"
```

Run the database:

```
$ docker-compose up -d pg
demo_pg_1
```

Build the database tables:

```
$ docker-compose run --no-deps --rm possum bundle exec rake db:migrate
```

Bring up the rest of the services:

```
$ docker-compose up -d --no-deps --no-recreate
Creating demo_possum_1
Creating demo_watch_1
Creating demo_ui_1
Creating demo_cli_1
$ docker-compose ps
    Name                   Command               State    Ports   
-----------------------------------------------------------------
demo_cli_1      /sbin/my_init                    Up
demo_pg_1       /docker-entrypoint.sh postgres   Up      5432/tcp 
demo_possum_1   possum                           Up      80/tcp   
demo_watch_1    possum-watch                     Up      80/tcp
demo_ui_1       /start.py                        Up      0.0.0.0:32771->443/tcp, 80/tcp
```

Services are up and healthy!

Load a policy:

```
$ cp ../tmp/policy.yml run
$ # Trigger the possum-watch to load the policy
$ echo /var/run/possum/policy/policy.yml > run/load
$ docker-compose logs watch
Attaching to demo_watch_1
watch_1   | + bundle exec rake 'policy:watch[/var/run/possum/policy]'
watch_1   | Loading /var/run/possum/policy/policy.yml
watch_1   | Creating 'admin' user
watch_1   | Loading 7 records from policy /var/run/possum/policy/policy.yml
watch_1   | Setting password for 'cucumber:user:alice'
watch_1   | Loaded policy in 0.363426253 seconds
```

Open the UI:

```
$ open https://172.28.128.3:32771/ui
```

