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

This script builds the `possum-docs` Docker image and then runs
[html-proofer](https://github.com/gjtorikian/html-proofer) against the rendered HTML.

---

### API Blueprint Docs

See [Build the API documentation from source](../README.md#build-the-api-documentation-from-source).
