// Mega compilation unit that includes all Dart apis related to generating SQL
// at runtime.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/sqlite_keywords.dart';
import 'package:drift/src/runtime/executor/stream_queries.dart';
import 'package:drift/src/utils/single_transformer.dart';
import 'package:meta/meta.dart';

// New files should not be part of this mega library, which we're trying to
// split up.
import 'expressions/case_when.dart';

part 'components/group_by.dart';
part 'components/join.dart';
part 'components/limit.dart';
part 'components/order_by.dart';
part 'components/where.dart';
part 'expressions/aggregate.dart';
part 'expressions/algebra.dart';
part 'expressions/bools.dart';
part 'expressions/comparable.dart';
part 'expressions/custom.dart';
part 'expressions/datetimes.dart';
part 'expressions/exists.dart';
part 'expressions/expression.dart';
part 'expressions/in.dart';
part 'expressions/null_check.dart';
part 'expressions/text.dart';
part 'expressions/variables.dart';

part 'schema/column_impl.dart';
part 'schema/entities.dart';
part 'schema/table_info.dart';
part 'schema/view_info.dart';

part 'statements/select/custom_select.dart';
part 'statements/select/select.dart';
part 'statements/select/select_with_join.dart';
part 'statements/delete.dart';
part 'statements/insert.dart';
part 'statements/query.dart';
part 'statements/update.dart';

part 'generation_context.dart';
part 'migration.dart';

/// A component is anything that can appear in a sql query.
abstract class Component {
  /// Default, constant constructor.
  const Component();

  /// Writes this component into the [context] by writing to its
  /// [GenerationContext.buffer] or by introducing bound variables. When writing
  /// into the buffer, no whitespace around the this component should be
  /// introduced. When a component consists of multiple composed component, it's
  /// responsible for introducing whitespace between its child components.
  void writeInto(GenerationContext context);
}

/// Writes all [components] into the [context], separated by commas.
void _writeCommaSeparated(
    GenerationContext context, Iterable<Component> components) {
  var first = true;
  for (final element in components) {
    if (!first) {
      context.buffer.write(', ');
    }
    element.writeInto(context);
    first = false;
  }
}

/// An enumeration of database systems supported by drift. Only
/// [SqlDialect.sqlite] is officially supported, all others are in an
/// experimental state at the moment.
enum SqlDialect {
  /// Use sqlite's sql dialect. This is the default option and the only
  /// officially supported dialect at the moment.
  sqlite,

  /// (currently unsupported)
  mysql,

  /// PostgreSQL (currently supported in an experimental state)
  postgres,
}
