#!/bin/bash
dart run ./tool/ci_build.dart
docker build -t squidfunk/mkdocs-material .
docker run --rm -it -p 7000:8000 -v ${PWD}:/docs squidfunk/mkdocs-material
