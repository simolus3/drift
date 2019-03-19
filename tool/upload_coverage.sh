#!/usr/bin/env bash

if [ "$PKG" == "moor" ]; then
    pushd moor
    pub run coveralls lcov.info
fi