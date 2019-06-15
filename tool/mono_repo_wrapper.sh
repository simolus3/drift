#!/usr/bin/env bash

case $PKG in
moor_generator)
    ./tool/travis.sh dartfmt dartanalyzer test
;;
sqlparser)
    ./tool/travis.sh dartfmt dartanalyzer test
;;
moor)
    ./tool/travis.sh dartfmt dartanalyzer command
;;
esac
