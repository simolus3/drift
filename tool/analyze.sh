#!/usr/bin/env bash

EXIT_CODE=0

cd moor
echo $(pwd)
dartfmt -n --set-exit-if-changed . || EXIT_CODE=$?
dartanalyzer --options analysis_options.yaml --fatal-infos --fatal-warnings lib/ test/ || EXIT_CODE=$?
cd ..

cd moor_flutter
echo $(pwd)
dartfmt -n --set-exit-if-changed . || EXIT_CODE=$?
dartanalyzer --options analysis_options.yaml --fatal-infos --fatal-warnings lib/ || EXIT_CODE=$?
cd ..

cd moor_generator
echo $(pwd)
dartfmt -n --set-exit-if-changed . || EXIT_CODE=$?
dartanalyzer --options analysis_options.yaml --fatal-infos --fatal-warnings lib/ test/ || EXIT_CODE=$?
cd ..

cd sqlparser
echo $(pwd)
dartfmt -n --set-exit-if-changed . || EXIT_CODE=$?
dartanalyzer --options analysis_options.yaml --fatal-infos --fatal-warnings lib/ test/ || EXIT_CODE=$?

exit $EXIT_CODE