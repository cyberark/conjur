# Conjur Website

The web development environment uses Docker and Docker Compose to
provide an expertly configured local Ruby environment. Instructions on
how to install those are linked in the [top level
README][dependencies].

To build and serve the site on your computer, first run:

```sh-session
$ cd $(git rev-parse --show-cdup) # start in the project root
$ docker-compose up -d docs
```

Then `open localhost:4000` to view it in your browser.

The site is rebuilt automatically every time you save a file. Just
refresh your browser tab (<kbd>&#8984;-R</kbd> on Mac, <kbd>Ctrl-R</kbd>
elsewhere) to see updates.

To stop the container, `docker-compose kill docs`.

### Check for broken links

```sh-session
$ cd $(git rev-parse --show-cdup) # start in the project root
$ ./checklinks.sh
```

This script uses Docker to run [html-proofer][proofer] on the rendered
site and will report broken links as errors. It's automatically run as
part of our continuous integration pipeline, but it's a good idea to
run it yourself whenever you add or remove links.

[dependencies]: ../README.md#Development_Dependencies "Development Dependencies"
[proofer]: https://github.com/gjtorikian/html-proofer "HTML Proofer"

---

### API Documentation

Currently, the docker-compose setup described above assumes that the
API docs have been rendered to `docs/_includes/api.html`. Without that
file, the local server can't show the API docs.

If you want to view the API docs in your local site, perform this step:

```sh-session
$ cd "$(git rev-parse --show-toplevel)" # cd to project root
$ docker-compose run --rm apidocs > docs/_includes/api.html
```

#### Working on the API docs

Unlike the rest of the site, the API docs do not live-update as you
edit their source files. If you're just working on them, you can get a
live-updating dev server:

```sh-session
$ cd $(git rev-parse --show-cdup) # start in the project root
$ docker-compose run --rm --service-ports apidocs -w
```

Then `open localhost:3000` to see the API docs in your browser.

To stop the container, hit <kbd>Ctrl-c</kbd>.
