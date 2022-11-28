#!/usr/bin/env bash

pushd extras/drift_postgres
echo "Running integration tests with Postgres"
dart pub upgrade
dart test || true
popd

pushd examples/with_built_value
echo "Running build runner in with_built_value"
dart pub upgrade
dart run build_runner build --delete-conflicting-outputs
popd

pushd examples/modular
echo "Running build runner in modular example"
dart pub upgrade
dart run build_runner build --delete-conflicting-outputs
popd

pushd examples/migrations_example
echo "Testing migrations in migrations_example"
dart pub upgrade
dart test
popd
