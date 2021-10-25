#!/bin/bash
set -e
echo "- Generate drift"
(cd ../drift && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate benchmarks"
(cd ../extras/benchmarks && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate integration_tests/tests"
(cd ../extras/integration_tests/tests && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate integration_tests/web"
(cd ../extras/integration_tests/web && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate migrations_example"
(cd ../extras/migrations_example && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate web_worker_example"
(cd ../extras/web_worker_example && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate with_built_value"
(cd ../extras/with_built_value && dart pub get && dart run build_runner build --delete-conflicting-outputs)
