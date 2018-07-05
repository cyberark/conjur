PROJECT_ROOT=$(readlink -f `dirname $0`/..)

# Run docker
# - without network (you can override with --network default)
# - removing the container
# - with project root mounted in /app
# - with current directory mounted in /app
# - with home directory set to /tmp
# - as current user and group
docker_run() {
  docker run --network none --rm -e HOME=/tmp -v $PROJECT_ROOT:/app -w /app -u `id -u`:`id -g` $*
}

GEMFILE_LOCK=$PROJECT_ROOT/Gemfile.lock

[ "$DEBUG" ] && set -x

# Extract exact gem version from Gemfile.lock
gem_version() {
  while [ "$#" != "0" ]; do
    local gem=$1
    local version="`grep -o "$gem ([.0-9]\\+" $GEMFILE_LOCK`"
    echo $gem:${version##*\(}
    shift
  done
}

# Pipe a dockerfile to this and it returns an image id.
# You can give extra options for docker build as arguments.
# Build output is redirected to stderr.
build_docker_image() {
  local iidfile=`mktemp`
  docker build $* --iidfile $iidfile - 1>&2
  local iid=`cat $iidfile`
  rm $iidfile
  echo $iid
}

# Give gems as arguments, get alpine image out.
build_ruby_image() {
  echo -n "Building ruby image with $*... " 1>&2
  # Don't be too verbose unless we're asked to
  local options=`[ "$DEBUG" ] || echo -q`

  build_docker_image $options << DOCKERFILE
    FROM ruby:alpine AS build
    RUN apk add --update make gcc libc-dev && rm -rf /var/cache/apk/*
    RUN gem install --no-doc $* && rm -rf /usr/local/bundle/cache

    FROM ruby:alpine
    COPY --from=build /usr/local/bundle /usr/local/bundle/
DOCKERFILE
}
