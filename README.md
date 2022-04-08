# Drift

_Note: Moor has been renamed to drift_

[![Build Status](https://api.cirrus-ci.com/github/simolus3/moor.svg)](https://github.com/simolus3/drift/actions/workflows/main.yml/badge.svg)
[![Chat on Gitter](https://img.shields.io/gitter/room/moor-dart/community)](https://gitter.im/moor-dart/community)

## Proudly Sponsored by [Stream 💙](https://getstream.io/chat/flutter/tutorial/?utm_source=Github&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=Github_Jan2022_FlutterChat&utm_term=moor)

<p align="center">
<table>
    <tbody>
        <tr>
            <td align="center">
                <a href="https://getstream.io/chat/flutter/tutorial/?utm_source=Github&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=Github_Jan2022_FlutterChat&utm_term=moor" target="_blank"><img width="250px" src="https://stream-blog.s3.amazonaws.com/blog/wp-content/uploads/fc148f0fc75d02841d017bb36e14e388/Stream-logo-with-background-.png"/></a><br/><span><a href="https://getstream.io/chat/flutter/tutorial/?utm_source=Github&utm_medium=Github_Repo_Content_Ad&utm_content=Developer&utm_campaign=Github_Jan2022_FlutterChat&utm_term=moor" target="_blank">Try the Flutter Chat Tutorial &nbsp💬</a></span>
            </td>
        </tr>
    </tbody>
</table>
</p>


| Core                                                                                      | Generator                                                                                              |
| :---------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------------------------: |
| [![Main version](https://img.shields.io/pub/v/drift.svg)](https://pub.dev/packages/drift) | [![Generator version](https://img.shields.io/pub/v/drift_dev.svg)](https://pub.dev/packages/drift_dev) |

Drift is a reactive persistence library for Flutter and Dart, built on top of
sqlite. 
Drift is

- __Flexible__: Drift let's you write queries in both SQL and Dart, 
providing fluent apis for both languages. You can filter and order results 
or use joins to run queries on multiple tables. You can even use complex 
sql features like `WITH` and `WINDOW` clauses.
- __🔥 Feature rich__: Drift has builtin support for transactions, schema 
migrations, complex filters and expressions, batched updates and joins. We 
even have a builtin IDE for SQL!
- __📦 Modular__: Thanks to builtin support for daos and `import`s in sql files, drift helps you keep your database code simple.
- __🛡️ Safe__: Drift generates typesafe code based on your tables and queries. If you make a mistake in your queries, drift will find it at compile time and
provide helpful and descriptive lints.
- __⚡ Fast__: Even though drift lets you write powerful queries, it can keep
up with the performance of key-value stores like shared preferences and Hive. Drift is the only major persistence library with builtin threading support, allowing you to run database code across isolates with zero additional effort.
- __Reactive__: Turn any sql query into an auto-updating stream! This includes complex queries across many tables
- __⚙️ Cross-Platform support__: Drift works on Android, iOS, macOS, Windows, Linux and the web. [This template](https://github.com/simolus3/drift/tree/develop/examples/app) is a Flutter todo app that works on all platforms.
- __🗡️ Battle tested and production ready__: Drift is stable and well tested with a wide range of unit and integration tests. It powers production Flutter apps.

With drift, persistence on Flutter is fun!

__To start using drift, read our detailed [docs](https://drift.simonbinder.eu/docs/getting-started/).__

If you have any questions, feedback or ideas, feel free to [create an
issue](https://github.com/simolus3/drift/issues/new). If you enjoy this
project, I'd appreciate your [🌟 on GitHub](https://github.com/simolus3/drift/).

-----

Important packages in this repo:

- `drift`: The main runtime for drift, which provides most apis
- `drift_dev`: The compiler for drift tables, databases and daos. It 
   also contains a fully-featured sql ide for the Dart analyzer.
- `sqlparser`: A sql parser and static analyzer, written in pure Dart. This package can be used without drift to perform analysis on sql statements.
It's on pub at 
[![sqlparser](https://img.shields.io/pub/v/sqlparser.svg)](https://pub.dev/packages/sqlparser)
