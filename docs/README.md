# Conjur Landing Page

The web development environment uses Docker to
provide an expertly configured local Ruby environment.

To build and serve the site on your computer, first run the following command
from this directory:

```sh-session
$ _deploy/run.sh
```

Then `open localhost:4000` to view it in your browser.

The site is rebuilt automatically every time you save a file. Just
refresh your browser tab (<kbd>&#8984;-R</kbd> on Mac, <kbd>Ctrl-R</kbd>
elsewhere) to see updates.

To stop the container, press <kbd>Ctrl-C</kbd> in the terminal.

### Jekyll Documentation

This website is generated using Jekyll. We've documented our use and
best practices in [separate file](jekyll-structure.md).

### Check for broken links

```sh-session
$ cd $(git rev-parse --show-cdup) # start in the project root
$ _deploy/checklinks.sh
```

This script uses Docker to run [html-proofer][proofer] on the rendered
site and will report broken links as errors. It's automatically run as
part of our continuous integration pipeline, but it's a good idea to
run it yourself whenever you add or remove links.

[dependencies]: ../README.md#Development_Dependencies "Development Dependencies"
[proofer]: https://github.com/gjtorikian/html-proofer "HTML Proofer"
