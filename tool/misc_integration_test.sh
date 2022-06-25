#!/usr/bin/env bash

EXIT_CODE=0

pushd extras/drift_postgres
echo "Running integration tests with Postgres"
dart pub upgrade
dart test || EXIT_CODE=$?
popd

pushd examples/with_built_value
echo "Running build runner in with_built_value"
dart pub upgrade
dart run build_runner build --delete-conflicting-outputs || EXIT_CODE=$?
popd

pushd examples/migrations_example
echo "Testing migrations in migrations_example"
dart pub upgrade
dart test
popd

exit $EXIT_CODE
