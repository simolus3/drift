#!/bin/bash
set -e

function run_test() {
    echo "------------- Running test: $1 -------------"
    pushd $1 > /dev/null
    rm -rf .dart_tool
    dart pub get
    dart format -o none --set-exit-if-changed .
    dart analyze --fatal-infos --fatal-warnings
    if [[ "$2" == 'vm+web' ]]; then
      dart test
      dart test -p chrome
    elif [[ "$2" == 'web-only' ]]; then
      dart test -p chrome
    else
      dart test
    fi
    popd > /dev/null
}

function run_test_flutter() {
    echo "------------- Running flutter test: $1 -------------"
    pushd $1 > /dev/null
    rm -rf .dart_tool
    flutter pub get
    flutter clean
    dart format -o none --set-exit-if-changed .
    flutter analyze --fatal-infos --fatal-warnings
    flutter test $2
    popd > /dev/null
}

cd ..
run_test 'drift' 'vm+web'
run_test 'drift_dev'
run_test 'sqlparser'
run_test_flutter 'drift_sqflite' 'integration_test'
run_test_flutter 'examples/app'
run_test 'examples/migrations_example'
run_test_flutter 'extras/integration_tests/ffi_on_flutter' 'integration_test/drift_native.dart'
run_test 'extras/integration_tests/web' 'web-only'
#run_test 'extras/drift_postgres'