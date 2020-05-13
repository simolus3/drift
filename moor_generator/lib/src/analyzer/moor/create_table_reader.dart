import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:moor_generator/moor_generator.dart';
import 'package:moor_generator/src/analyzer/errors.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';
import 'package:moor_generator/src/analyzer/sql_queries/type_mapping.dart';
import 'package:moor_generator/src/backends/backend.dart';
import 'package:moor_generator/src/model/declarations/declaration.dart';
import 'package:moor_generator/src/model/used_type_converter.dart';
import 'package:moor_generator/src/utils/names.dart';
import 'package:moor_generator/src/utils/string_escaper.dart';
import 'package:moor_generator/src/utils/type_converter_hint.dart';
import 'package:recase/recase.dart';
import 'package:sqlparser/sqlparser.dart';

class CreateTableReader {
  /// The AST of this `CREATE TABLE` statement.
  final TableInducingStatement stmt;
  final Step step;
  final List<ImportStatement> imports;

  static const _schemaReader = SchemaFromCreateTable(moorExtensions: true);
  static final RegExp _enumRegex =
      RegExp(r'^enum\((\w+)\)$', caseSensitive: false);

  CreateTableReader(this.stmt, this.step, [this.imports = const []]);

  Future<MoorTable> extractTable(TypeMapper mapper) async {
    Table table;
    try {
      table = _schemaReader.read(stmt);
    } catch (e) {
      step.reportError(ErrorInMoorFile(
        span: stmt.tableNameToken.span,
        message: 'Could not extract schema information for this table: $e',
      ));
    }

    final foundColumns = <String, MoorColumn>{};
    final primaryKey = <MoorColumn>{};

    for (final column in table.resultColumns) {
      var isPrimaryKey = false;
      final features = <ColumnFeature>[];
      final sqlName = column.name;
      final dartName = ReCase(sqlName).camelCase;
      final constraintWriter = StringBuffer();
      final moorType = mapper.resolvedToMoor(column.type);
      UsedTypeConverter converter;
      String defaultValue;
      String overriddenJsonKey;

      final enumMatch = column.definition != null
          ? _enumRegex.firstMatch(column.definition.typeName)
          : null;
      if (enumMatch != null) {
        final dartTypeName = enumMatch.group(1);
        final dartType = await _readDartType(dartTypeName);

        if (dartType == null) {
          step.reportError(ErrorInMoorFile(
            message: 'Type $dartTypeName could not be found. Are you missing '
                'an import?',
            severity: Severity.error,
            span: column.definition.typeNames.span,
          ));
        } else {
          try {
            converter = UsedTypeConverter.forEnumColumn(dartType);
          } on InvalidTypeForEnumConverterException catch (e) {
            step.reportError(ErrorInMoorFile(
              message: e.errorDescription,
              severity: Severity.error,
              span: column.definition.typeNames.span,
            ));
          }
        }
      }

      // columns from virtual tables don't necessarily have a definition, so we
      // can't read the constraints.
      final constraints = column.hasDefinition
          ? column.constraints
          : const Iterable<ColumnConstraint>.empty();
      for (final constraint in constraints) {
        if (constraint is PrimaryKeyColumn) {
          isPrimaryKey = true;
          features.add(const PrimaryKey());
          if (constraint.autoIncrement) {
            features.add(AutoIncrement());
          }
        }
        if (constraint is Default) {
          final dartType = dartTypeNames[moorType];
          final expressionName = 'const CustomExpression<$dartType>';
          final sqlDefault = constraint.expression.span.text;
          defaultValue = '$expressionName(${asDartLiteral(sqlDefault)})';
        }

        if (constraint is MappedBy) {
          if (converter != null) {
            // Already has a converter from an ENUM type
            step.reportError(ErrorInMoorFile(
              message: 'This column has an ENUM type, which implicitly creates '
                  "a type converter. You can't apply another converter to such "
                  'column. ',
              span: constraint.span,
              severity: Severity.warning,
            ));
            continue;
          }

          converter = await _readTypeConverter(moorType, constraint);
          // don't write MAPPED BY constraints when creating the table, they're
          // a convenience feature by the compiler
          continue;
        }
        if (constraint is JsonKey) {
          overriddenJsonKey = constraint.jsonKey;
          // those are moor-specific as well, don't write them
          continue;
        }

        if (constraintWriter.isNotEmpty) {
          constraintWriter.write(' ');
        }
        constraintWriter.write(constraint.span.text);
      }

      // if the column definition isn't set - which can happen for CREATE
      // VIRTUAL TABLE statements - use the entire statement as declaration.
      final declaration =
          MoorColumnDeclaration(column.definition ?? stmt, step.file);

      if (converter != null) {
        column.applyTypeHint(TypeConverterHint(converter));
      }

      final parsed = MoorColumn(
        type: moorType,
        nullable: column.type.nullable,
        dartGetterName: dartName,
        name: ColumnName.implicitly(sqlName),
        features: features,
        customConstraints: constraintWriter.toString(),
        defaultArgument: defaultValue,
        typeConverter: converter,
        overriddenJsonName: overriddenJsonKey,
        declaration: declaration,
      );

      foundColumns[column.name] = parsed;
      if (isPrimaryKey) {
        primaryKey.add(parsed);
      }
    }

    final tableName = table.name;
    final dartTableName = ReCase(tableName).pascalCase;
    final dataClassName = stmt.overriddenDataClassName ??
        dataClassNameForClassName(dartTableName);

    final constraints = table.tableConstraints.map((c) => c.span.text).toList();

    for (final keyConstraint in table.tableConstraints.whereType<KeyClause>()) {
      if (keyConstraint.isPrimaryKey) {
        primaryKey.addAll(keyConstraint.indexedColumns
            .map((r) => foundColumns[r.columnName])
            .where((c) => c != null));
      }
    }

    return MoorTable(
      fromClass: null,
      columns: foundColumns.values.toList(),
      sqlName: table.name,
      dartTypeName: dataClassName,
      overriddenName: dartTableName,
      primaryKey: primaryKey,
      overrideWithoutRowId: table.withoutRowId ? true : null,
      overrideTableConstraints: constraints.isNotEmpty ? constraints : null,
      // we take care of writing the primary key ourselves
      overrideDontWriteConstraints: true,
      declaration: MoorTableDeclaration(stmt, step.file),
    )..parserTable = table;
  }

  Future<UsedTypeConverter> _readTypeConverter(
      ColumnType sqlType, MappedBy mapper) async {
    final code = mapper.mapper.dartCode;
    final type = await step.task.backend.resolveTypeOf(step.file.uri, code);

    // todo report lint for any of those cases or when resolveTypeOf throws
    if (type is! InterfaceType) {
      return null;
    }

    final interfaceType = type as InterfaceType;
    // TypeConverter declares a "D mapToDart(S fromDb);". We need to know D
    final typeInDart = interfaceType.getMethod('mapToDart').returnType;

    return UsedTypeConverter(
        expression: code, mappedType: typeInDart, sqlType: sqlType);
  }

  Future<DartType> _readDartType(String typeIdentifier) async {
    final dartImports = imports
        .map((import) => import.importedFile)
        .where((importUri) => importUri.endsWith('.dart'));

    for (final import in dartImports) {
      final resolved = step.task.session.resolve(step.file, import);
      LibraryElement library;
      try {
        library = await step.task.backend.resolveDart(resolved.uri);
      } on NotALibraryException {
        continue;
      }

      final foundElement = library.exportNamespace.get(typeIdentifier);
      if (foundElement is ClassElement) {
        return foundElement.instantiate(
          typeArguments: const [],
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }
    }

    return null;
  }
}
