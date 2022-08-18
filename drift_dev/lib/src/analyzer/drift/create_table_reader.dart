import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:drift_dev/moor_generator.dart';
import 'package:drift_dev/src/analyzer/data_class.dart';
import 'package:drift_dev/src/analyzer/errors.dart';
import 'package:drift_dev/src/analyzer/runner/steps.dart';
import 'package:drift_dev/src/analyzer/sql_queries/type_mapping.dart';
import 'package:drift_dev/src/backends/backend.dart';
import 'package:drift_dev/src/utils/string_escaper.dart';
import 'package:drift_dev/src/utils/type_converter_hint.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart' hide Expression;

import '../dart_types.dart';
import '../helper.dart';
import 'find_dart_class.dart';

class CreateTableReader {
  /// The AST of this `CREATE TABLE` statement.
  final TableInducingStatement stmt;
  final Step step;
  final List<ImportStatement> imports;
  final HelperLibrary helper;

  static final RegExp _enumRegex =
      RegExp(r'^enum\((\w+)\)$', caseSensitive: false);

  CreateTableReader(this.stmt, this.step, this.helper,
      [this.imports = const []]);

  Future<DriftTable?> extractTable(TypeMapper mapper) async {
    Table table;
    try {
      final reader = SchemaFromCreateTable(
        driftExtensions: true,
        driftUseTextForDateTime:
            step.task.session.options.storeDateTimeValuesAsText,
      );

      table = reader.read(stmt);
    } catch (e, s) {
      print(s);
      step.reportError(ErrorInDriftFile(
        span: stmt.tableNameToken!.span,
        message: 'Could not extract schema information for this table: $e',
      ));

      return null;
    }

    final foundColumns = <String, DriftColumn>{};
    Set<DriftColumn>? primaryKeyFromTableConstraint;

    for (final column in table.resultColumns) {
      final features = <ColumnFeature>[];
      final sqlName = column.name;
      String? overriddenDartName;
      final dartName = ReCase(sqlName).camelCase;
      final constraintWriter = StringBuffer();
      final driftType = mapper.resolvedToMoor(column.type);
      UsedTypeConverter? converter;
      String? defaultValue;
      String? overriddenJsonKey;
      ColumnGeneratedAs? generatedAs;

      final typeName = column.definition?.typeName;

      final enumMatch =
          typeName != null ? _enumRegex.firstMatch(typeName) : null;
      if (enumMatch != null) {
        final dartTypeName = enumMatch.group(1)!;
        final dartType = await _readDartType(dartTypeName);

        if (dartType == null) {
          step.reportError(ErrorInDriftFile(
            message: 'Type $dartTypeName could not be found. Are you missing '
                'an import?',
            severity: Severity.error,
            span: column.definition!.typeNames!.span,
          ));
        } else {
          try {
            converter = UsedTypeConverter.forEnumColumn(
              dartType,
              helper.helperLibrary.typeProvider,
            );
          } on InvalidTypeForEnumConverterException catch (e) {
            step.reportError(ErrorInDriftFile(
              message: e.errorDescription,
              severity: Severity.error,
              span: column.definition!.typeNames!.span,
            ));
          }
        }
      }

      // columns from virtual tables don't necessarily have a definition, so we
      // can't read the constraints.
      final constraints =
          column.hasDefinition ? column.constraints : const <Never>[];
      for (final constraint in constraints) {
        if (constraint is PrimaryKeyColumn) {
          features.add(const PrimaryKey());
          if (constraint.autoIncrement) {
            features.add(AutoIncrement());
          }
        }
        if (constraint is Default) {
          final dartType = dartTypeNames[driftType];
          final expressionName = 'const CustomExpression<$dartType>';
          final sqlDefault = constraint.expression.span!.text;
          defaultValue = '$expressionName(${asDartLiteral(sqlDefault)})';
        }

        if (constraint is MappedBy) {
          if (converter != null) {
            // Already has a converter from an ENUM type
            step.reportError(ErrorInDriftFile(
              message: 'This column has an ENUM type, which implicitly creates '
                  "a type converter. You can't apply another converter to such "
                  'column. ',
              span: constraint.span!,
              severity: Severity.warning,
            ));
            continue;
          }

          converter = await _readTypeConverter(
              driftType, column.type.nullable ?? true, constraint);
          // don't write MAPPED BY constraints when creating the table, they're
          // a convenience feature by the compiler
          continue;
        }
        if (constraint is JsonKey) {
          overriddenJsonKey = constraint.jsonKey;
          // those are moor-specific as well, don't write them
          continue;
        }
        if (constraint is DriftDartName) {
          overriddenDartName = constraint.dartName;
          // ditto
          continue;
        }

        if (constraintWriter.isNotEmpty) {
          constraintWriter.write(' ');
        }
        constraintWriter.write(constraint.span!.text);
      }

      // if the column definition isn't set - which can happen for CREATE
      // VIRTUAL TABLE statements - use the entire statement as declaration.
      final declaration =
          DriftColumnDeclaration(column.definition ?? stmt, step.file);

      if (converter != null) {
        column.applyTypeHint(TypeConverterHint(converter));
      }

      final parsed = DriftColumn(
        type: driftType,
        nullable: column.type.nullable != false,
        dartGetterName: overriddenDartName ?? dartName,
        name: ColumnName.implicitly(sqlName),
        features: features,
        customConstraints: constraintWriter.toString(),
        defaultArgument: defaultValue,
        typeConverter: converter,
        overriddenJsonName: overriddenJsonKey,
        declaration: declaration,
        generatedAs: generatedAs,
      );

      foundColumns[column.name] = parsed;
    }

    final tableName = table.name;
    String? dartTableName, dataClassName;
    ExistingRowClass? existingRowClass;

    final moorTableInfo = stmt.driftTableName;
    if (moorTableInfo != null) {
      final overriddenNames = moorTableInfo.overriddenDataClassName;

      if (moorTableInfo.useExistingDartClass) {
        final clazz = await findDartClass(step, imports, overriddenNames);
        if (clazz == null) {
          step.reportError(ErrorInDriftFile(
            span: stmt.tableNameToken!.span,
            message: 'Existing Dart class $overriddenNames was not found, are '
                'you missing an import?',
          ));
        } else {
          existingRowClass = validateExistingClass(
              foundColumns.values, clazz, '', false, step);
          dataClassName = existingRowClass?.targetClass.name;
        }
      } else if (overriddenNames.contains('/')) {
        // Feature to also specify the generated table class. This is extremely
        // rarely used if there's a conflicting class from moor. See #932
        final names = overriddenNames.split('/');
        dataClassName = names[0];
        dartTableName = names[1];
      } else {
        dataClassName = overriddenNames;
      }
    }

    dartTableName ??= ReCase(tableName).pascalCase;
    dataClassName ??= dataClassNameForClassName(dartTableName);

    final constraints =
        table.tableConstraints.map((c) => c.span!.text).toList();

    for (final keyConstraint in table.tableConstraints.whereType<KeyClause>()) {
      if (keyConstraint.isPrimaryKey) {
        primaryKeyFromTableConstraint = {};
        for (final column in keyConstraint.columns) {
          final expr = column.expression;
          if (expr is Reference && foundColumns.containsKey(expr.columnName)) {
            primaryKeyFromTableConstraint.add(foundColumns[expr.columnName]!);
          }
        }
      }
    }

    final moorTable = DriftTable(
      fromClass: null,
      columns: foundColumns.values.toList(),
      sqlName: table.name,
      dartTypeName: dataClassName,
      overriddenName: dartTableName,
      primaryKey: primaryKeyFromTableConstraint,
      overrideWithoutRowId: table.withoutRowId ? true : null,
      overrideTableConstraints: constraints.isNotEmpty ? constraints : null,
      // we take care of writing the primary key ourselves
      overrideDontWriteConstraints: true,
      declaration: DriftTableDeclaration(stmt, step.file),
      existingRowClass: existingRowClass,
      isStrict: table.isStrict,
    )..parserTable = table;

    // Having a mapping from parser table to moor tables helps with IDE features
    // like "go to definition"
    table.setMeta<DriftTable>(moorTable);

    return moorTable;
  }

  Future<UsedTypeConverter?> _readTypeConverter(
      DriftSqlType sqlType, bool nullable, MappedBy mapper) async {
    final code = mapper.mapper.dartCode;

    Expression expression;
    try {
      expression = await step.task.backend.resolveExpression(
          step.file.uri,
          code,
          imports.map((e) => e.importedFile).where((e) => e.endsWith('.dart')));
    } on CannotReadExpressionException catch (e) {
      step.reportError(ErrorInDriftFile(span: mapper.span!, message: e.msg));
      return null;
    }

    return readTypeConverter(
      helper.helperLibrary,
      expression,
      sqlType,
      nullable,
      (errorMsg) => step
          .reportError(ErrorInDriftFile(span: mapper.span!, message: errorMsg)),
      helper,
    );
  }

  Future<DartType?> _readDartType(String typeIdentifier) async {
    final foundClass = await findDartClass(step, imports, typeIdentifier);

    return foundClass?.classElement.instantiate(
      typeArguments: const [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}
