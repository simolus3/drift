#!/usr/bin/env bash

EXIT_CODE=0

pushd extras/integration_tests/pg
echo "Running integration tests with moor_ffi & VM"
dart pub upgrade
dart test || EXIT_CODE=$?
popd

exit $EXIT_CODE
