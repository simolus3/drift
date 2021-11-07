#!/bin/bash
set -e
cd ../drift
rm -rf .dart_tool
dart pub get
dart format -o none --set-exit-if-changed .
dart analyze --fatal-infos --fatal-warnings
dart run build_runner build --delete-conflicting-outputs
dart test

cd ../drift_dev
rm -rf .dart_tool
dart pub get
dart format -o none --set-exit-if-changed .
dart analyze --fatal-infos --fatal-warnings
dart test

cd ../sqlparser
rm -rf .dart_tool
dart pub get
dart format -o none --set-exit-if-changed .
dart analyze --fatal-infos --fatal-warnings
dart test

cd ..
./tool/misc_integration_test.sh
