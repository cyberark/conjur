# Conjur Web Site

## Development

You can develop the website in a Docker container, which removes the need for a local Ruby environment. We use docker-compose for this.

```sh-session
$ cd ..  # project root
$ docker-compose build --pull docs
$ docker-compose up -d docs
```

The container port 4000 is mapped to your host port 4000. You can open it like this from your host machine (not from the container):

```sh-session
$ open http://$DOCKER_IP:4000/conjur/
```

`DOCKER_IP` is the address of your Docker VM, or it's simply `localhost` if you're running a native Docker. http://localhost:4000.

The website will be rebuilt automatically on changes.
Refresh your browser tab to see updates.

### Check for broken links

```sh-session
$ cd ..  # project root
$ ./checklinks.sh
```

This script builds the `conjur-docs` Docker image and then runs
[html-proofer](https://github.com/gjtorikian/html-proofer) against the rendered HTML.

---

### API Blueprint Docs

TODO: move this section out of `docs/` and into project root or `apidocs/`.

We're using [API Blueprint](https://apiblueprint.org/documentation/) to document the Conjur API. There is no Ruby specific implementation, so we're using the [Aglio](https://github.com/danielgtaylor/aglio) package. The final generated docs can be viewed in two ways:

##### Live Preview
```sh-session
$ cd docs
$ ./dev.sh /node_modules/.bin/aglio -i apidocs/src/api.md -s -h 0.0.0.0 -p 4000
```

The above will make the rendered API docs available on `http://localhost:4000/`.

Please note that the Docs Dockerfile contains the configuration to build both Jekyll and Aglio. This is why we execute commands from the `/docs` folder not the `/apidocs` folder. The API Blueprint reference path (`apidocs/src/api.md`) is from the project root.

##### Generated (Visible from Jekyll)

To compile API docs into the Jekyll project, first, start the Jekyll server:

```sh-session
$ cd docs && ./dev.sh
```

Now in a new shell, compile API docs into the running project:
```sh-session
$ docker exec conjur-web /node_modules/.bin/aglio -i apidocs/src/api.md -o /opt/conjur/_site/apidocs.html
```
The above should be run from the root `conjur` folder.
