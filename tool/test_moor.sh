#!/usr/bin/env bash

EXIT_CODE=0

cd moor || exit 1
pub run build_runner build --delete-conflicting-outputs

pub run test --coverage=coverage || EXIT_CODE=$?

# Testing on the web doesn't work on CI (we're running into out-of-memory issues even with 12G of RAM)
#if [ $EXIT_CODE -eq 0 ]
#  then pub run test -P browsers || EXIT_CODE=$?
#fi

exit $EXIT_CODE