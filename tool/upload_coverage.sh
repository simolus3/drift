#!/usr/bin/env bash

if [ "$PKG" == "moor" ]; then
    pushd moor
    bash <(curl -s https://codecov.io/bash) -f lcov.info
fi