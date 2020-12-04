#!/usr/bin/env bash

EXIT_CODE=0

pushd extras/integration_tests/vm
echo "Running integration tests with moor_ffi & VM"
dart pub upgrade
dart test || EXIT_CODE=$?
popd

pushd extras/with_built_value
echo "Running build runner in with_built_value"
dart pub upgrade
dart run build_runner build --delete-conflicting-outputs || EXIT_CODE=$?
popd

exit $EXIT_CODE