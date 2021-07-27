# Moor
[![Build Status](https://api.cirrus-ci.com/github/simolus3/moor.svg)](https://cirrus-ci.com/github/simolus3/moor)
[![codecov](https://codecov.io/gh/simolus3/moor/branch/master/graph/badge.svg)](https://codecov.io/gh/simolus3/moor)
[![Chat on Gitter](https://img.shields.io/gitter/room/moor-dart/community)](https://gitter.im/moor-dart/community)

## Proudly Sponsored by [Stream 💙](https://getstream.io/chat/flutter/tutorial/?utm_source=https://github.com/simolus3/moor&utm_medium=github&utm_content=developer&utm_term=flutter)

<p align="center">
<table>    
    <tbody>
        <tr>
            <td align="center">
                <a href="https://getstream.io/chat/flutter/tutorial/?utm_source=https://github.com/simolus3/moor&utm_medium=github&utm_content=developer&utm_term=flutter" target="_blank"><img width="250px" src="https://stream-blog.s3.amazonaws.com/blog/wp-content/uploads/fc148f0fc75d02841d017bb36e14e388/Stream-logo-with-background-.png"/></a><br/><span><a href="https://getstream.io/chat/flutter/tutorial/?utm_source=https://github.com/simolus3/moor&utm_medium=github&utm_content=developer&utm_term=flutter" target="_blank">Try the Flutter Chat Tutorial &nbsp💬</a></span>
            </td>            
        </tr>
    </tbody>
</table>
</p>


| Core          | Flutter           | Generator  |
|:-------------:|:-------------:|:-----:|
| [![Generator version](https://img.shields.io/pub/v/moor.svg)](https://pub.dev/packages/moor) | [![Flutter version](https://img.shields.io/pub/v/moor_flutter.svg)](https://pub.dev/packages/moor_flutter) | [![Generator version](https://img.shields.io/pub/v/moor_generator.svg)](https://pub.dev/packages/moor_generator) |

Moor is a reactive persistence library for Flutter and Dart, built ontop of
sqlite. 
Moor is

- __Flexible__: Moor let's you write queries in both SQL and Dart, 
providing fluent apis for both languages. You can filter and order results 
or use joins to run queries on multiple tables. You can even use complex 
sql features like `WITH` and `WINDOW` clauses.
- __🔥 Feature rich__: Moor has builtin support for transactions, schema 
migrations, complex filters and expressions, batched updates and joins. We 
even have a builtin IDE for SQL!
- __📦 Modular__: Thanks to builtin support for daos and `import`s in sql files, moor helps you keep your database code simple.
- __🛡️ Safe__: Moor generates typesafe code based on your tables and queries. If you make a mistake in your queries, moor will find it at compile time and
provide helpful and descriptive lints.
- __⚡ Fast__: Even though moor lets you write powerful queries, it can keep
up with the performance of key-value stores like shared preferences and Hive. Moor is the only major persistence library with builtin threading support, allowing you to run database code across isolates with zero additional effort.
- __Reactive__: Turn any sql query into an auto-updating stream! This includes complex queries across many tables
- __⚙️ Cross-Platform support__: Moor works on Android, iOS, macOS, Windows, Linux and the web. [This template](https://github.com/rodydavis/moor_shared) is a Flutter todo app that works on all platforms
- __🗡️ Battle tested and production ready__: Moor is stable and well tested with a wide range of unit and integration tests. It powers production Flutter apps.

With moor, persistence on Flutter is fun!

__To start using moor, read our detailed [docs](https://moor.simonbinder.eu/docs/getting-started/).__

If you have any questions, feedback or ideas, feel free to [create an
issue](https://github.com/simolus3/moor/issues/new). If you enjoy this
project, I'd appreciate your [🌟 on GitHub](https://github.com/simolus3/moor/).

-----

Packages in this repo:
- `moor`: The main runtime for moor, which provides most apis
- `moor_ffi`: New and faster executor for moor, built with `dart:ffi`.
- `moor_flutter`: The standard executor wrapping the `sqflite` package
- `moor_generator`: The compiler for moor tables, databases and daos. It 
   also contains a fully-featured sql ide
- `sqlparser`: A sql parser and static analyzer, written in pure Dart. This package can be used without moor to perform analysis on sql statements.
It's on pub at 
[![sqlparser](https://img.shields.io/pub/v/sqlparser.svg)](https://pub.dev/packages/sqlparser)
