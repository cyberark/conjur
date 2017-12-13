# API Documentation

The purpose of this sub-project/folder is to generate an html file
to be consumed by the documentation site. If you want to view the
file generated for this, perform this step:

```sh-session
$ cd "$(git rev-parse --show-toplevel)" # cd to project root
$ docker-compose run --rm apidocs > api.html
```

This will generate the HTML partial into the project root.

## Working on the API docs

If you're working on the API docs locally, you can get a live-updating
dev server:

```sh-session
$ cd $(git rev-parse --show-cdup) # start in the project root
$ docker-compose run --rm --service-ports apidocs -w
```

Then navigate to `localhost:3000` to see the API docs in your browser.

To stop the container, hit <kbd>Ctrl-c</kbd>.
