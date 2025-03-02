import 'package:drift_dev/src/utils/string_escaper.dart';

import '../../analysis/dialect.dart';
import '../../analysis/results/results.dart';
import '../writer.dart';

/// Generates a list of expressions each evaluating to a `ColumnConstraint`
/// instance for column constraints set on the [column].
List<String> columnConstraints(TextEmitter emitter, DriftColumn column) {
  final entries = <String>[];
  var wrotePkConstraint = false;

  for (final feature in column.constraints) {
    if (feature is PrimaryKeyColumn) {
      if (!wrotePkConstraint) {
        entries.add(
            'const ${emitter.drift('ColumnPrimaryKeyConstraint')}(isAutoIncrementing: ${feature.isAutoIncrement})');
        wrotePkConstraint = true;
        break;
      }
    }
  }

  for (final feature in column.constraints) {
    if (feature is UniqueColumn && !wrotePkConstraint) {
      entries.add('const ${emitter.drift('ColumnUniqueConstraint')}()');
      wrotePkConstraint = true;
    }

    if (feature is ForeignKeyReference) {
      final tableName = feature.otherColumn.owner.id.name;
      final columnName = feature.otherColumn.nameInSql;

      var constraint = 'const ${emitter.drift('ColumnForeignKeyConstraint')}('
          'otherTableName: ${asDartLiteral(tableName)},'
          'otherColumnName: ${asDartLiteral(columnName)},';

      if (feature.onUpdate case final onUpdate?) {
        constraint =
            'onUpdate: ${emitter.drift('ReferenceAction')}.${onUpdate.name},';
      }
      if (feature.onDelete case final onDelete?) {
        constraint =
            'onDelete: ${emitter.drift('ReferenceAction')}.${onDelete.name},';
      }
      if (feature.initiallyDeferred) {
        constraint = 'initiallyDeferred: true,';
      }

      entries.add('$constraint)');
    } else if (feature is DartCheckExpression) {
      final dartCheck = emitter.dartCode(feature.dartExpression);

      entries
          .add('const ${emitter.drift('ColumnCheckConstraint')}($dartCheck)');
    } else if (feature is ColumnGeneratedAs) {
      final dartCode = emitter.dartCode(feature.dartExpression);
      entries
          .add('${emitter.drift('GeneratedAs')}($dartCode, ${feature.stored})');
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

      final result =
          StringBuffer('${emitter.drift('ColumnConstraint')}.custom({');

      for (final dialect in emitter.writer.options.dialects.values) {
        result.writeln('$dialect: ${asDartLiteral(buildFor(dialect))},');
      }

      result.write('})');
      return [result.toString()];
    }
  }

  return entries;
}
