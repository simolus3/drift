#!/usr/bin/env bash

cd moor
dart tool/coverage.dart
#pub run build_runner test --delete-conflicting-outputs