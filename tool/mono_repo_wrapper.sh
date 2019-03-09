#!/usr/bin/env bash

case $PKG in
mono_generator)
    ./tool/travis.sh dartfmt dartanalyzer test
;;
mono)
    ./tool/travis.sh dartfmt dartanalyzer command
;;
esac
