/// A version of moor that runs on the web by using [sql.js](https://github.com/sql-js/sql.js)
/// You manually need to include that library into your website to use the
/// web version of moor. See [the documentation](https://drift.simonbinder.eu/web)
/// for a more detailed instruction.
@experimental
@moorDeprecated
library moor_web;

import 'package:drift/web.dart';
import 'package:meta/meta.dart';
import 'package:moor/src/deprecated.dart';

export 'package:drift/web.dart' hide DriftWebStorage;

/// Interface to control how moor should store data on the web.
@pragma('moor2drift', 'DriftWebStorage')
typedef MoorWebStorage = DriftWebStorage;
