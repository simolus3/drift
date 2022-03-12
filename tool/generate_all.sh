#!/bin/bash
set -e
echo "- Generate drift"
(cd ../drift && rm -rf .dart_tool && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate docs"
(cd ../docs && rm -rf .dart_tool && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate benchmarks"
(cd ../extras/benchmarks && rm -rf .dart_tool && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate integration_tests/tests"
(cd ../extras/integration_tests/tests && rm -rf .dart_tool && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate integration_tests/web"
(cd ../extras/integration_tests/web && rm -rf .dart_tool && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate migrations_example"
(cd ../extras/migrations_example && rm -rf .dart_tool && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate web_worker_example"
(cd ../extras/web_worker_example &&  rm -rf .dart_tool && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate with_built_value"
(cd ../extras/with_built_value &&  rm -rf .dart_tool && dart pub get && dart run build_runner build --delete-conflicting-outputs)
echo "- Generate flutter_web_worker_example"
(cd ../extras/flutter_web_worker_example && rm -rf .dart_tool && dart pub get && dart run build_runner build --delete-conflicting-outputs)
