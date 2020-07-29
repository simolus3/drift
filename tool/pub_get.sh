#!/usr/bin/env bash

cd moor
echo $(pwd)
pub upgrade
cd ..

cd moor_flutter
echo $(pwd)
flutter packages upgrade
cd ..

cd moor_generator
echo $(pwd)
pub upgrade
cd ..

cd sqlparser
echo $(pwd)
pub upgrade
cd ..

cd moor_ffi
echo $(pwd)
flutter packages upgrade
cd ..