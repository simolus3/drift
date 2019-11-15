import 'dart:async';

import 'package:meta/meta.dart';
import 'package:moor/moor.dart';
import 'package:moor/src/runtime/executor/stream_queries.dart';

part 'batch.dart';
part 'connection.dart';
part 'db_base.dart';
part 'dao_base.dart';
part 'query_engine.dart';

/// Defines additional runtime behavior for moor. Changing the fields of this
/// class is rarely necessary.
class MoorRuntimeOptions {
  /// Don't warn when a database class isn't used as singleton.
  bool dontWarnAboutMultipleDatabases = false;
}

/// Stores the [MoorRuntimeOptions] describing global moor behavior across
/// databases.
///
/// Note that is is adapting this behavior is rarely needed.
MoorRuntimeOptions moorRuntimeOptions = MoorRuntimeOptions();
