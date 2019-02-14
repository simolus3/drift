#!/usr/bin/env bash

case $PKG in
sally_generator)
    ./tool/travis.sh dartfmt dartanalyzer test
;;
sally)
    ./tool/travis.sh dartfmt dartanalyzer command
;;
esac