#!/bin/bash
set -e

function generate() {
    echo "------------- Generate: $1 -------------"
    pushd $1 > /dev/null
    dart pub upgrade
    dart run build_runner build --delete-conflicting-outputs
    popd > /dev/null
}

cd "$(dirname "$0")/.."
generate 'drift'
generate 'drift_dev'
generate 'docs'
generate 'extras/benchmarks'
generate 'extras/integration_tests/drift_testcases'
generate 'extras/integration_tests/web'
generate 'examples/app'
generate 'examples/encryption'
generate 'examples/flutter_web_worker_example'
generate 'examples/migrations_example'
generate 'examples/web_worker_example'
generate 'examples/with_built_value'