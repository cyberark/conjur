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

