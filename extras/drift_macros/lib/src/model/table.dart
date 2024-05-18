import 'package:drift/drift.dart';
import 'package:macros/macros.dart';

import 'column.dart';

final class ResolvedTable {
  final List<ResolvedColumn> columns;
  final Identifier rowClass;
  final Identifier tableClass;

  final bool withoutRowId;
  final bool strict;

  late final ResolvedColumn? rowid = _findRowId();
  ResolvedColumn? _implicitRowId;

  ResolvedTable({
    required this.columns,
    required this.rowClass,
    required this.tableClass,
    this.withoutRowId = false,
    this.strict = false,
  }) {
    if (!withoutRowId) {
      _implicitRowId = ResolvedColumn(
        sqlType: ColumnType.drift(DriftSqlType.int),
        nullable: false,
        nameInSql: 'rowid',
        nameInDart: 'rowid',
      );
    }
  }

  /// Determines whether [column] would be required for inserts performed via
  /// companions.
  bool isColumnRequiredForInsert(ResolvedColumn column) {
    assert(columns.contains(column));

    if (column.nullable) {
      // default value would be applied, so it's not required for inserts
      return false;
    }

    if (rowid == column) {
      // If the column is an alias for the rowid, it will get set automatically
      // by sqlite and isn't required for inserts either.
      return false;
    }

    // In other cases, we need a value for inserts into the table.
    return true;
  }

  ResolvedColumn? _findRowId() {
    if (withoutRowId) return null;

    // See if we have an integer primary key as defined by
    // https://www.sqlite.org/lang_createtable.html#rowid
    final primaryKey = <ResolvedColumn>[]; // todo...
    if (primaryKey.length == 1) {
      final column = primaryKey.single;
      final builtinType = column.sqlType.builtin;
      if (builtinType == DriftSqlType.int ||
          builtinType == DriftSqlType.bigInt) {
        // So this column is an alias for the rowid
        return column;
      }
    }

    // Otherwise, expose the implicit rowid column.
    return _implicitRowId;
  }
}
