import 'package:drift/drift3.dart';
import 'package:sqlparser/sqlparser.dart' as sql;

import '../../analysis/dialect.dart';
import '../../analysis/options.dart';
import '../../analysis/results/results.dart';

Map<RegisteredDriftDialect, String> defaultConstraints(
    DriftOptions options, DriftColumn column) {
  final allDialects = options.dialects.values.toList();
  final defaultConstraints = <String>[];
  final dialectSpecificConstraints = <RegisteredDriftDialect, List<String>>{
    for (final dialect in allDialects) dialect: [],
  };

  var wrotePkConstraint = false;

  for (final feature in column.constraints) {
    if (feature is PrimaryKeyColumn) {
      if (!wrotePkConstraint) {
        if (feature.isAutoIncrement) {
          // TODO: Use runtime column builder for this?
          for (final dialect in allDialects) {
            if (dialect is DriftMariadbDialect) {
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
      final tableName = feature.otherColumn.owner.id.name;
      final columnName = feature.otherColumn.nameInSql;

      var constraint = 'REFERENCES "$tableName" ("$columnName")';

      final onUpdate = feature.onUpdate;
      final onDelete = feature.onDelete;

      if (onUpdate != null) {
        constraint = '$constraint ON UPDATE ${onUpdate.description}';
      }

      if (onDelete != null) {
        constraint = '$constraint ON DELETE ${onDelete.description}';
      }

      if (feature.initiallyDeferred) {
        constraint = '$constraint DEFERRABLE INITIALLY DEFERRED';
      }

      defaultConstraints.add(constraint);
    } else if (feature is DefaultConstraintsFromSchemaFile) {
      String buildFor(RegisteredDriftDialect dialect) {
        final result = StringBuffer();
        if (feature.forAllDialects case final defaults?) {
          result.write(defaults);
        }
        if (feature.dialectSpecific[dialect] case final specific?) {
          if (result.isNotEmpty) {
            result.write(' ');
          }
          result.write(specific);
        }
        return result.toString();
      }

      return {
        for (final dialect in allDialects) dialect: buildFor(dialect),
      };
    }
  }

  if (column.sqlType case ColumnDriftType(builtin: BuiltinDriftType.bool)) {
    final name = column.nameInSql;

    dialectSpecificConstraints.forEach((dialect, constraints) {
      if (dialect is DriftSqliteDialect || dialect is DriftMariadbDialect) {
        dialectSpecificConstraints[dialect]!.add('CHECK ("$name" IN (0, 1))');
      }
    });
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
