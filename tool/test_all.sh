#!/bin/bash
set -e
cd ../drift
dart pub get
dart format -o none --set-exit-if-changed .
dart analyze --fatal-infos --fatal-warnings
dart run build_runner build --delete-conflicting-outputs
dart test

cd ../drift_dev
dart pub get
dart format -o none --set-exit-if-changed .
dart analyze --fatal-infos --fatal-warnings
dart test

cd ..
./tool/misc_integration_test.sh
