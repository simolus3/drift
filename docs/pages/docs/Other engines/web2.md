---
data:
  title: Web draft
  description: Draft for upcoming stable Drift web support.
  hidden: true
template: layouts/docs/single
---

This draft document describes different approaches allowing drift to run on the
web.
After community feedback, this restructured page will replace the [existing web documentation]({{ 'web.md' | pageUrl }}).

## Introduction

Drift first gained its initial web support in 2019. This implementation, which is still supported today, relies on
keeping an in-memory database that is periodically saved to local storage.
In the last years, development in web browsers and the Dart ecosystem enabled more performant approaches that are
unfortunately impossible to implement with the original drift web API.
This is the reason the original API is still considered experimental.

This page describes the fundamental challenges and required browser features used to efficiently run drift on the web.
It presents a guide on the current and most reliable approach to bring sqlite3 to the web, but older implementations
and approaches to migrate between them are still supported and documented as well.

### Technology challenges

Drift wraps [sqlite3](https://sqlite.org/index.html), a popular relational database written as a C library.
On native platforms, we can use `dart:ffi` to efficiently bind to C libraries. This is what a `NativeDatabase` does internally,
it gives us efficient and synchronous access to sqlite3.
On the web, C libraries can be compiled to [WebAssembly](https://webassembly.org/), a native-like low-level language.
While C code can be compiled to WebAssembly, there is no builtin support for file IO which would be required for a database.
This functionality needs to be implemented in JavaScript (or, in our case, in Dart).

For a long time, the web platform lacked a suitable persistence solution that could be used to give sqlite3 access to the
file system:

- Local storage is synchronous, but can't efficiently store binary data. Further, we can't efficiently change a portion of the
  data stored in local storage. A one byte write to a 10MB database file requires writing everything again.
- IndexedDb supports binary data and could be used to store chunks of a file in rows. However, it is asynchronous and sqlite3,
  being a C library, expects a synchronous IO layer.
- Finally, the newer Origin Private File System API (OPFS) supports synchronous access to app data _and_ synchronous writes.
  However, it is only supported in web workers.

While we can support asynchronous persistence APIs by keeping an in-memory cache for synchronous reads and simply not awaiting
writes, OPFS is more promising due to its synchronous nature that doesn't require storing the entire database in memory.

In addition to the persistence problem, there is an issue of concurrency when a user opens multiple tabs of your web app.
Natively, locks in the file system allow sqlite3 to guarantee that multiple processes can access the same database without causing
conflicts. On the web, no synchronous lock API exists between tabs.

The recommended solution to run drift on the web is to use

- OPFS for storing data, and
- shared web workers to share the database between multiple tabs.

Support for OPFS ([caniuse](https://caniuse.com/native-filesystem-api)) and shared web workers ([caniuse](https://caniuse.com/sharedworkers))
is supported on Desktop browsers, but not available on most mobile browsers yet. OPFS or other persistence API are sometimes disabled
in private or incognito tabs too.
You need to consider different fallbacks that you may want to support:

- If OPFS is not available, you may want to fall back to a different persistence layer like IndexedDb, silently use an in-memory database
  only or warn the user about these circumstances. Note that, even in modern browsers, OPFS may not be available in private/incognito tabs.
- If shared workers are not available, you can still safely use the database, but not if multiple tabs of your web app are opened.
  You could use [Web Locks](https://developer.mozilla.org/en-US/docs/Web/API/Web_Locks_API) to detect whether another instance of your
  database is currently open and inform the user about this.

The [Flutter app example](https://github.com/simolus3/drift/tree/develop/examples/app) which is part of the Drift repository implements all
of these fallbacks.
Snippets to detect these error conditions are provided on this website, but the integration with fallbacks or user-visible warnings depends
on the structure of your app in the end.

## Setup

The most stable setup recommended to run drift on the web requires shared web workers and the native filesystem API to be supported.

First, you'll need a version of sqlite3 that has been compiled to WASM and is ready to use Dart bindings for its IO work.
You can grab this `sqlite3.wasm` file from the [GitHub releases](https://github.com/simolus3/sqlite3.dart/releases) of the sqlite3 package,
or [compile it yourself](https://github.com/simolus3/sqlite3.dart/tree/main/sqlite3#compiling).
You can host this file on a CDN, or just put it in the `web/` folder of your Flutter app so that it is part of the final bundle.
It is important that your web server serves the file with `Content-Type: application/wasm`. Browsers will refuse to load it otherwise.

### Drift web worker

Since OPFS is only available in dedicated web workers, you need to define a worker responsible for hosting the database in its thread.
The main tab will connect to that worker to access the database with a communication protocol handled by drift.

In its `web/worker.dart` library, Drift provies a suitable entrypoint for both shared and dedicated web workers hosting a sqlite3
database. It takes a callback creating the actual database connection. Drift will be responsible for creating the worker in the
right configuration.
But since the worker depends on the way you set up the database, we can't ship a precompiled worker JavaScript file. You need to
write the worker yourself and compile it to JavaScript.

The worker's source could be put into `web/database_worker.dart` and have a structure like the following:

{% assign worker = 'package:drift_docs/snippets/engines/new_worker.dart.excerpt.json' | readString | json_decode %}

{% include "blocks/snippet" snippets = worker %}

Drift will detect whether the worker is running as a shared or as a dedicated worker and call the callback to open the
database at a suitable time.

How to compile the worker depends on your build setup:

1. With regular Dart web apps, you're likely using `build_web_compilers` with `build_runner` or `webdev` already.
   This build system can compile workers too.
   [This build configuration](https://github.com/simolus3/drift/blob/develop/examples/web_worker_example/build.yaml) shows
   how to configure `build_web_compilers` to always compile a worker with `dart2js`.
2. With Flutter wep apps, you can either use `build_web_compilers` too (since you're already using `build_runner` for
   drift), or compile the worker with `dart compile js`. When using `build_web_compilers`, explicitly enable `dart2js`
   or run the build with `--release`.

Make sure to always use `dart2js` (and not `dartdevc`) to compile a web worker, since modules emitted by `dartdevc` are
not directly supported in web workers.

#### Worker mode

| Dedicated | Shared | Dedicated in shared |
|-----------|--------|---------------------|
| ![](dedicated_in_shared.png) | ![](dedicated_in_shared.png) | ![](dedicated_in_shared.png) |
| Each tab uses its own worker with an independent database. | A single worker hosting the database is used across tabs | Like "shared", except that the shared worker forwards requests to a dedicated worker. |

### Using the database

To spawn and connect to such a web worker, drift provides the `connectToDriftWorker` method:

{% assign snippets = 'package:drift_docs/snippets/engines/new_connect.dart.excerpt.json' | readString | json_decode %}

{% include "blocks/snippet" snippets = snippets name = "approach1" %}

The "dedicated in shared" worker mode here makes drift create the following topology between tabs and workers:

## Legacy approaches

### sql.js {#sqljs}