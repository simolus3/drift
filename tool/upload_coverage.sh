#!/usr/bin/env bash

pushd extras/coverage_formatting
pub upgrade
popd

dart extras/coverage_formatting/bin/coverage.dart

bash <(curl -s https://codecov.io/bash) -f lcov.info
