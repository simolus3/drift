#!/usr/bin/env bash

# The formatter is in the moor directory
pushd moor
dart tool/format_coverage.dart
popd

bash <(curl -s https://codecov.io/bash) -f lcov.info
