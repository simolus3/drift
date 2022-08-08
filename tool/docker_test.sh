#!/bin/bash
set -e

cd ..
DOCKER_BUILDKIT=0 docker build -t drift-test .
docker run --rm --privileged -it drift-test
docker image rm drift-test
