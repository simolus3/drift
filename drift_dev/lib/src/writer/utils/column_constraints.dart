import 'package:drift/drift.dart';
import 'package:drift/sqlite_keywords.dart';
import 'package:sqlparser/sqlparser.dart' as sql;

import '../../analysis/results/results.dart';

String defaultConstraints(DriftColumn column) {
  final defaultConstraints = <String>[];

  var wrotePkConstraint = false;

  for (final feature in column.constraints) {
    if (feature is PrimaryKeyColumn) {
      if (!wrotePkConstraint) {
        defaultConstraints.add(feature.isAutoIncrement
            ? 'PRIMARY KEY AUTOINCREMENT'
            : 'PRIMARY KEY');

        wrotePkConstraint = true;
        break;
      }
    }
  }

  if (!wrotePkConstraint) {
    for (final feature in column.constraints) {
      if (feature is UniqueColumn) {
        defaultConstraints.add('UNIQUE');
        break;
      }
    }
  }

  for (final feature in column.constraints) {
    if (feature is ForeignKeyReference) {
      final tableName = escapeIfNeeded(feature.otherColumn.owner.id.name);
      final columnName = escapeIfNeeded(feature.otherColumn.nameInSql);

      var constraint = 'REFERENCES $tableName ($columnName)';

      final onUpdate = feature.onUpdate;
      final onDelete = feature.onDelete;

      if (onUpdate != null) {
        constraint = '$constraint ON UPDATE ${onUpdate.description}';
      }

      if (onDelete != null) {
        constraint = '$constraint ON DELETE ${onDelete.description}';
      }

      defaultConstraints.add(constraint);
    }
  }

  if (column.sqlType == DriftSqlType.bool) {
    final name = escapeIfNeeded(column.nameInSql);
    defaultConstraints.add('CHECK ($name IN (0, 1))');
  }

  return defaultConstraints.join(' ');
}

extension on sql.ReferenceAction {
  String get description {
    switch (this) {
      case sql.ReferenceAction.setNull:
        return 'SET NULL';
      case sql.ReferenceAction.setDefault:
        return 'SET DEFAULT';
      case sql.ReferenceAction.cascade:
        return 'CASCADE';
      case sql.ReferenceAction.restrict:
        return 'RESTRICT';
      case sql.ReferenceAction.noAction:
        return 'NO ACTION';
    }
  }
}
