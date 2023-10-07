import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/sqlite_keywords.dart';
import 'package:sqlparser/sqlparser.dart' as sql;

import '../../analysis/results/results.dart';

Map<SqlDialect, String> defaultConstraints(DriftColumn column) {
  final defaultConstraints = <String>[];
  final dialectSpecificConstraints = <SqlDialect, List<String>>{
    for (final dialect in SqlDialect.values) dialect: [],
  };

  var wrotePkConstraint = false;

  for (final feature in column.constraints) {
    if (feature is PrimaryKeyColumn) {
      if (!wrotePkConstraint) {
        if (feature.isAutoIncrement) {
          for (final dialect in SqlDialect.values) {
            if (dialect == SqlDialect.mariadb) {
              dialectSpecificConstraints[dialect]!
                  .add('PRIMARY KEY AUTO_INCREMENT');
            } else {
              dialectSpecificConstraints[dialect]!
                  .add('PRIMARY KEY AUTOINCREMENT');
            }
          }
        } else {
          defaultConstraints.add('PRIMARY KEY');
        }

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
    } else if (feature is DefaultConstraintsFromSchemaFile) {
      // TODO: Dialect-specific constraints in schema file
      return {
        for (final dialect in SqlDialect.values) dialect: feature.constraints,
      };
    }
  }

  if (column.sqlType.builtin == DriftSqlType.bool) {
    final name = column.nameInSql;
    dialectSpecificConstraints[SqlDialect.sqlite]!
        .add('CHECK (${SqlDialect.sqlite.escape(name)} IN (0, 1))');
    dialectSpecificConstraints[SqlDialect.mariadb]!
        .add('CHECK (${SqlDialect.mariadb.escape(name)} IN (0, 1))');
  }

  for (final constraints in dialectSpecificConstraints.values) {
    constraints.addAll(defaultConstraints);
  }

  return dialectSpecificConstraints.map(
    (dialect, constraints) => MapEntry(dialect, constraints.join(' ')),
  );
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
