#!/usr/bin/env bash

EXIT_CODE=0

pushd extras/integration_tests
find . -type d -name .dart_tool -exec rm -rf {} \;
popd

pushd extras/integration_tests/vm
echo "Running integration tests with moor_ffi & VM"
dart pub upgrade
dart test || EXIT_CODE=$?
popd

pushd extras/integration_tests/postgres
echo "Running integration tests with Postgres"
dart pub upgrade
dart test || EXIT_CODE=$?
popd

pushd extras/with_built_value
echo "Running build runner in with_built_value"
dart pub upgrade
dart run build_runner build --delete-conflicting-outputs || EXIT_CODE=$?
popd

pushd extras/migrations_example
echo "Testing migrations in migrations_example"
dart pub upgrade
dart test
popd

exit $EXIT_CODE
