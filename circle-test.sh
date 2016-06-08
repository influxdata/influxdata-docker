#!/bin/bash

set -e

log_msg() {
  echo "[$(date "+%Y/%m/%d %H:%M:%S %z")] $@"
}

docker_build() {
  # CircleCI cannot build docker images with --rm=true correctly.
  if [ -z "$CIRCLE_BUILD_NUM" ]; then
    docker build --rm=false "$@"
  else
    docker build --rm=true "$@"
  fi
}

log_msg "Verifying docker daemon connectivity"
docker version

failed_builds=()

dockerfiles=$(find . -name Dockerfile -print0 | xargs -0 -I{} dirname {} | sed 's@./@@')
for path in $dockerfiles; do
  tag=$(echo $path | sed 's@/@:@' | sed 's@/@-@')
  log_msg "Building docker image $tag (from $path)"
  if ! docker_build -t "$tag" "$path"; then
    failed_builds+=("$tag")
  fi
done

if [ ${#failed_builds[@]} -eq 0 ]; then
  log_msg "All builds succeeded."
else
  log_msg "Failed to build the following images:"
  for tag in ${failed_builds[@]}; do
    echo "	$tag"
  done
fi
