# Possum Web Site

## Development

You can develop the website in a Docker container, which obviates the need for a local Ruby environment.

The script `dev.sh` builds a development Docker image, installs the Ruby bundle, and then launches it with a Bash shell:

```sh-session
$ ./dev.sh
Step 1 : FROM ruby:2.2.5
---> f505cf3c05a6
...
Step 7 : RUN bundle
...
Successfully built f22a9461a6c4
+ docker run --rm -it -v /Users/kgilpin/source/conjur/possum-pages:/opt/possum possum-pages-dev bash
root@58401c4fcc1c:/opt/possum#
```

You're now in the `/opt/possum` directory in the container. Run `jekyll` to start the webserver. Be sure and use the `-H` option to override the default bind address from `localhost` to `0.0.0.0`:

```sh-session
root@d21ed1776173:/opt/possum# jekyll serve -H 0.0.0.0
Configuration file: /opt/possum/_config.yml
            Source: /opt/possum
       Destination: /opt/possum/_site
 Incremental build: disabled. Enable with --incremental
      Generating... 
                    done in 5.144 seconds.
 Auto-regeneration: enabled for '/opt/possum'
Configuration file: /opt/possum/_config.yml
    Server address: http://127.0.0.1:4000/possum/
  Server running... press ctrl-c to stop.
```

The container port 4000 is mapped to your host port 4000. You can open it like this from your host machine (not from the container):

```sh-session
$ open http://$DOCKER_IP:4000/possum/
```

`DOCKER_IP` is the address of your Docker VM, or it's simply `localhost` if you`re running a native Docker.

