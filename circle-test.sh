#!/bin/bash

set -e

dir=.
if [ $# -gt 0 ]; then
  dir=("$@")
fi

log_msg() {
  echo "[$(date "+%Y/%m/%d %H:%M:%S %z")] $@"
}

docker_build() {
  if [ ! -z "$BUILD_NUMBER" ]; then
    # Build on Jenkins without using the cache.
    docker build --no-cache --force-rm "$@"
  elif [ ! -z "$CIRCLE_BUILD_NUM" ]; then
    # CircleCI cannot build docker images with --rm=true correctly.
    docker build --no-cache --rm=false "$@"
  else
    # Local building should use the cache for speedy development.
    docker build --rm=true "$@"
  fi
}

log_msg "Verifying docker daemon connectivity"
docker version

failed_builds=()
tags=()

# Gather directories with a Dockerfile and sanitize the path to remove leading
# a leading ./ and multiple slashes into a single slash.
dockerfiles=$(find "$dir" -name nightly -prune -o -name Dockerfile -print0 | xargs -0 -I{} dirname {} | grep -v dockerlib | sed 's@^./@@' | sed 's@//*@/@g')
for path in $dockerfiles; do
  # Generate a tag by replacing the first slash with a colon and all remaining slashes with a dash.
  tag=$(echo $path | sed 's@/@:@' | sed 's@/@-@g')
  log_msg "Building docker image $tag (from $path)"
  if ! docker_build -t "$tag" "$path"; then
    failed_builds+=("$tag")
  else
    if [ ! -z "$BUILD_NUMBER" ]; then
      # Remove the image if we are running on Jenkins.
      docker rmi "$tag"
    fi
    tags+=("$tag")
  fi
done

if [ ${#failed_builds[@]} -eq 0 ]; then
  log_msg "All builds succeeded."
else
  log_msg "Failed to build the following images:"
  for tag in ${failed_builds[@]}; do
    echo "	$tag"
  done
  exit ${#failed_builds[@]}
fi

# Image tests:

assert_equals() {
  local actual=$1
  local expected=$2
  local test_name=$3

  if [ "$actual" != "$expected" ]; then
    msg="$test_name: '$actual' is not equal to '$expected'"
    failed_tests+=("$msg")
  fi
}

assert_contains() {
  local actual="$1"
  local expected_substring="$2"
  local test_name="$3"

  if [[ "$actual" != *"$expected_substring"* ]]; then
    msg="$test_name: '$actual' does not contain '$expected_substring'"
    failed_tests+=("$msg")
  fi
}

failed_tests=()

# Iterate over every circle-test.sh script in any subdirectory
#circle_tests=$(find "$dir" -mindepth 2 -name circle-test.sh -print0)
#for path in $circle_tests; do
#  log_msg "Executing $path"
#  . $path
#done

if [ ${#failed_tests[@]} -eq 0 ]; then
  log_msg "All tests succeeded."
else
  log_msg "The following tests failed:"
  for ((i = 0; i < ${#failed_tests[@]}; i++)); do
    echo "  ${failed_tests[$i]}"
  done
  exit ${#failed_tests[@]}
fi

