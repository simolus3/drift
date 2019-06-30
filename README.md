# Moor
[![Build Status](https://travis-ci.com/simolus3/moor.svg?token=u4VnFEE5xnWVvkE6QsqL&branch=master)](https://travis-ci.com/simolus3/moor)
[![codecov](https://codecov.io/gh/simolus3/moor/branch/master/graph/badge.svg)](https://codecov.io/gh/simolus3/moor)


| Core API      | Flutter           | Generator  |
|:-------------:|:-------------:|:-----:|
| [![Generator version](https://img.shields.io/pub/v/moor.svg)](https://pub.dartlang.org/packages/moor) | [![Flutter version](https://img.shields.io/pub/v/moor_flutter.svg)](https://pub.dartlang.org/packages/moor_flutter) | [![Generator version](https://img.shields.io/pub/v/moor_generator.svg)](https://pub.dartlang.org/packages/moor_generator) |

Moor is an easy to use, reactive persistence library for Flutter apps. Define your database tables in pure Dart and 
enjoy a fluent query API, auto-updating streams and more!

For more information, check out the [docs](https://moor.simonbinder.eu/).

-----

The `sqlparser` directory contains an sql parser and static analyzer, written in pure Dart.
At the moment, it can only parse a subset of sqlite, but most select statements are 
supported.