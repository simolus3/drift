import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/sqlite_keywords.dart';
import 'package:sqlparser/sqlparser.dart' as sql;

import '../../analysis/results/results.dart';
import '../../utils/string_escaper.dart';
import '../writer.dart';

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
              dialectSpecificConstraints[dialect]!.add(
                'PRIMARY KEY AUTO_INCREMENT',
              );
            } else if (dialect == SqlDialect.duckdb) {
              dialectSpecificConstraints[dialect]!.add('PRIMARY KEY');
            } else {
              dialectSpecificConstraints[dialect]!.add(
                'PRIMARY KEY AUTOINCREMENT',
              );
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

      if (feature.initiallyDeferred) {
        constraint = '$constraint DEFERRABLE INITIALLY DEFERRED';
      }

      defaultConstraints.add(constraint);
    } else if (feature is DefaultConstraintsFromSchemaFile) {
      String buildFor(SqlDialect dialect) {
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
        for (final dialect in SqlDialect.values) dialect: buildFor(dialect),
      };
    }
  }

  if (column.sqlType.builtin == DriftSqlType.bool) {
    final name = column.nameInSql;
    dialectSpecificConstraints[SqlDialect.sqlite]!.add(
      'CHECK (${SqlDialect.sqlite.escape(name)} IN (0, 1))',
    );
    dialectSpecificConstraints[SqlDialect.mariadb]!.add(
      'CHECK (${SqlDialect.mariadb.escape(name)} IN (0, 1))',
    );
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

/// Generates a list of expressions each evaluating to a `ColumnConstraint`
/// instance for column constraints set on the [column].
List<String> columnConstraintsDrift3(TextEmitter emitter, DriftColumn column) {
  final entries = <String>[];
  var wrotePkConstraint = false;

  for (final feature in column.constraints) {
    if (feature is PrimaryKeyColumn) {
      if (!wrotePkConstraint) {
        entries.add(
          'const ${emitter.drift('ColumnPrimaryKeyConstraint')}(isAutoIncrementing: ${feature.isAutoIncrement})',
        );
        wrotePkConstraint = true;
        break;
      }
    }
  }

  if (!column.nullable && column.owner is DriftTable) {
    entries.add('const ${emitter.drift('ColumnNotNullConstraint')}()');
  }

  if (column.defaultArgument case final columnDefault?) {
    final type = emitter.dartCode(emitter.innerColumnType(column.sqlType));

    entries.add(
      '${emitter.drift('ColumnDefaultConstraint')}<$type>(${emitter.dartCode(columnDefault)})',
    );
  }

  for (final feature in column.constraints) {
    if (feature is UniqueColumn && !wrotePkConstraint) {
      entries.add('const ${emitter.drift('ColumnUniqueConstraint')}()');
      wrotePkConstraint = true;
    }

    if (feature is ForeignKeyReference) {
      final tableName = feature.otherColumn.owner.id.name;
      final columnName = feature.otherColumn.nameInSql;

      var constraint =
          'const ${emitter.drift('ColumnForeignKeyConstraint')}('
          'otherTableName: ${asDartLiteral(tableName)},'
          'otherColumnName: ${asDartLiteral(columnName)},';

      if (feature.onUpdate case final onUpdate?) {
        constraint +=
            'onUpdate: ${emitter.drift('ReferenceAction')}.${onUpdate.name},';
      }
      if (feature.onDelete case final onDelete?) {
        constraint +=
            'onDelete: ${emitter.drift('ReferenceAction')}.${onDelete.name},';
      }
      if (feature.initiallyDeferred) {
        constraint += 'initiallyDeferred: true,';
      }

      entries.add('$constraint)');
    } else if (feature is DartCheckExpression) {
      final dartCheck = emitter.dartCode(feature.dartExpression);

      entries.add('${emitter.drift('ColumnCheckConstraint')}($dartCheck)');
    } else if (feature is ColumnGeneratedAs) {
      final dartCode = emitter.dartCode(feature.dartExpression);
      entries.add(
        '${emitter.drift('ColumnGeneratedAs')}($dartCode, stored: ${feature.stored})',
      );
    } else if (feature is DefaultConstraintsFromSchemaFile) {
      String buildFor(SqlDialect dialect) {
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

      final result = StringBuffer(
        '${emitter.drift('ColumnConstraint')}.custom({',
      );

      for (final dialect in emitter.writer.options.supportedDialects) {
        result.writeln('$dialect: ${asDartLiteral(buildFor(dialect))},');
      }

      result.write('})');
      return [result.toString()];
    }
  }

  return entries;
}
