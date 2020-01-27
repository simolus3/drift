#!/usr/bin/env bash

EXIT_CODE=0

cd moor || exit 1
pub run build_runner build --delete-conflicting-outputs

pub run test --coverage=coverage || EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]
  then pub run test -P browsers || EXIT_CODE=$?
fi

exit $EXIT_CODE