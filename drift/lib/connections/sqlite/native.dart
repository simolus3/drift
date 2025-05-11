/// A drift database implementation built on `package:sqlite3/`.
///
/// The [NativeDatabase] class uses `dart:ffi` to access `sqlite3` APIs.
///
/// When using a [NativeDatabase], you need to ensure that `sqlite3` is
/// available when running your app. For mobile Flutter apps, you can simply
/// depend on the `sqlite3_flutter_libs` package to ship the latest sqlite3
/// version with your app.
/// For more information other platforms, see [other engines](https://drift.simonbinder.eu/docs/other-engines/vm/).
library;

import 'dart:async';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../../src/connections/connection.dart';
import 'sqlite3.dart';

/// Signature of a function that can perform setup work on a [database] before
/// drift is fully ready.
///
/// This could be used to, for instance, set encryption keys for SQLCipher
/// implementations.
typedef DatabaseSetup = void Function(Database database);

/// Signature of a function that can perform setup work on the isolate before
/// opening the database.
///
/// This could be used to override libraries.
/// For example:
/// ```
/// open.overrideFor(OperatingSystem.android, openCipherOnAndroid)
/// ```
typedef IsolateSetup = FutureOr<void> Function();

/// A drift database implementation based on `dart:ffi`, running directly in a
/// Dart VM or an AOT compiled Dart/Flutter application.
final class NativeDatabase {
  // when changing this, also update the documentation in `drift_vm_database_factory`.
  static const _cacheStatementsByDefault = true;
  static const _defaultReadPoolSize = 0;

  /// Creates a database that will store its result in the [file], creating it
  /// if it doesn't exist.
  ///
  /// {@template drift_vm_database_factory}
  /// The [cachePreparedStatements] flag (defaults to `true`) controls whether
  /// drift will cache prepared statement objects, which improves performance as
  /// sqlite3 doesn't have to parse statements that are frequently used multiple
  /// times.
  ///
  /// The optional [setup] function can be used to perform a setup just after
  /// the database is opened, before drift is fully ready. This can be used to
  /// add custom user-defined sql functions or to provide encryption keys in
  /// SQLCipher implementations.
  /// {@endtemplate}
  static DriftDatabaseImplementation blocking(
    File file, {
    DatabaseSetup? setup,
    bool cachePreparedStatements = _cacheStatementsByDefault,
  }) {}

  static Database _openDatabase({
    required String path,
    required DatabaseSetup? setup,
    required bool cachePreparedStatements,
  }) {}
}
