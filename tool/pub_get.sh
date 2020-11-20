#!/usr/bin/env bash

EXIT_CODE=0

cd moor
echo $(pwd)
pub upgrade || EXIT_CODE=$?
cd ..

#cd moor_flutter
#echo $(pwd)
#flutter packages upgrade
#cd ..

cd moor_generator
echo $(pwd)
pub upgrade || EXIT_CODE=$?
cd ..

cd sqlparser
echo $(pwd)
pub upgrade || EXIT_CODE=$?
cd ..

#cd moor_ffi
#echo $(pwd)
#flutter packages upgrade
#cd ..

exit $EXIT_CODE