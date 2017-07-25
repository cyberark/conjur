# Conjur Web Site

## Development

You can develop the website in a Docker container, which obviates the need for a local Ruby environment.

The script `dev.sh` starts by building the website development Docker image and installing the Ruby bundle:

```sh-session
$ ./dev.sh
+ cd ..
+ docker build -t possum-web -f docs/Dockerfile .
Sending build context to Docker daemon 2.062 MB
Step 1/5 : FROM ruby:2.2
...
Step 4/5 : RUN bundle --with website
...
Successfully built d0fb10c5277e
```

If `dev.sh` is run without arguments it launches Jekyll to serve the website on port 4000:

```sh-session
+ docker run --rm -it -v /Users/ajp/dev/conjur/possum/docs/..:/opt/conjur -p 4000:4000 possum-web jekyll serve -H 0.0.0.0 --source docs
Configuration file: docs/_config.yml
Configuration file: docs/_config.yml
            Source: docs
       Destination: /opt/conjur/_site
 Incremental build: disabled. Enable with --incremental
      Generating...
                    done in 2.238 seconds.
 Auto-regeneration: enabled for 'docs'
Configuration file: docs/_config.yml
    Server address: http://127.0.0.1:4000/
  Server running... press ctrl-c to stop.
```

When `dev.sh` is run with arguments, it passes them to `docker run`. For example, to run a shell instead of `jekyll`, invoke `dev.sh` this way:

```
$ ./dev.sh /bin/bash
...
+ docker run --rm -it -v /Users/ajp/dev/conjur/possum/docs/..:/opt/conjur -p 4000:4000 possum-web /bin/bash
root@734e94fd90c1:/opt/conjur#
```

You're now in the `/opt/conjur` directory in the container. Run `jekyll` to start the webserver. Be sure and use the `-H` option to override the default bind address from `localhost` to `0.0.0.0`:

```sh-session
root@d21ed1776173:/opt/conjur# jekyll serve -H 0.0.0.0
Configuration file: /opt/conjur/_config.yml
            Source: /opt/conjur
       Destination: /opt/conjur/_site
 Incremental build: disabled. Enable with --incremental
      Generating...
                    done in 5.144 seconds.
 Auto-regeneration: enabled for '/opt/conjur'
Configuration file: /opt/conjur/_config.yml
    Server address: http://127.0.0.1:4000/conjur/
  Server running... press ctrl-c to stop.
```

The container port 4000 is mapped to your host port 4000. You can open it like this from your host machine (not from the container):

```sh-session
$ open http://$DOCKER_IP:4000/conjur/
```

`DOCKER_IP` is the address of your Docker VM, or it's simply `localhost` if you`re running a native Docker.


#### API Blueprint Docs

We're using [API Blueprint](https://apiblueprint.org/documentation/) to document the Possum API. There is no Ruby specific implementation, so we're using the [Aglio](https://github.com/danielgtaylor/aglio) package. The final generated docs can be viewed in two ways:

##### Live Preview
```bash
$ cd docs
$ ./dev.sh /node_modules/.bin/aglio -i apidocs/src/api.md -s -h 0.0.0.0 -p 4000
```

The above will make the rendered API docs available on `http://localhost:4000/`.

Please note that the Docs Dockerfile contains the configuration to build both Jekyll and Aglio. This is why we execute commands from the `/docs` folder not the `/apidocs` folder. The API Blueprint reference path (`apidocs/src/api.md`) is from the project root.

##### Generated (Visible from Jekyll)

To compile API docs into the Jekyll project, first, start the Jekyll server:
```bash
$ cd docs && ./dev.sh
```
Now in a new shell, compile API docs into the running project:
```bash
$ docker exec possum-web /node_modules/.bin/aglio -i apidocs/src/api.md -o /opt/conjur/_site/apidocs.html
```
The above should be run from the root `possum` folder. 
