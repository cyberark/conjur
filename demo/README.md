
First, you need to build the project from the project directory.

Then build and run the demo with the start script:

```
$ ./start.sh
Creating demo_possum_1
Creating demo_watch_1
Creating demo_ui_1
...
possum_1  | * Listening on tcp://0.0.0.0:80
possum_1  | Use Ctrl-C to stop
```

Once the demo is up, it's tailing the log file of the Possum server.

You can Control-C the log tail, or open a new terminal.

The demo consists of a postgres container, possum server, a `watch` container, and the
Conjur UI:

```sh-session
$ docker-compose ps
    Name                   Command               State    Ports   
-----------------------------------------------------------------
demo_pg_1       /docker-entrypoint.sh postgres   Up      5432/tcp 
demo_possum_1   possum                           Up      80/tcp   
demo_watch_1    possum-watch                     Up      80/tcp
demo_ui_1       /start.py                        Up      0.0.0.0:32782->443/tcp, 80/tcp
```

Open the UI with your docker engine IP address, and the port number of the UI:

```sh-session
$ open https://172.28.128.3:32782/ui
```

By default, the policies are loaded from the demo `run` directory. If you change the policies,
you can trigger the `watch` container to reload them. For example, in the interactive terminal:

```sh-session
$ echo /var/run/possum/policy/Conjurfile > run/load
```

In the docker logs terminal you'll see something like this:

```sh-session
watch_1   | Loading /var/run/possum/policy/Conjurfile
watch_1   | Creating 'admin' user
watch_1   | Loading 23 records from policy /var/run/possum/policy/Conjurfile
watch_1   | Setting password for 'cucumber:user:kevin'
watch_1   | Setting password for 'cucumber:user:bob'
watch_1   | Loaded policy in 0.834751674 seconds
```

Refresh the UI, and you'll see the policy changes. If there is an error loading the policy, then
the whole thing will rollback to the previous policy state.
