import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show DriftSqlType;
import 'package:sqlparser/sqlparser.dart' show ReferenceAction;
import 'package:sqlparser/sqlparser.dart' as sql;

import '../../driver/error.dart';
import '../../results/results.dart';
import '../resolver.dart';
import '../shared/dart_types.dart';
import 'helper.dart';
import 'table.dart';

const String _startInt = 'integer';
const String _startInt64 = 'int64';
const String _startIntEnum = 'intEnum';
const String _startTextEnum = 'textEnum';
const String _startString = 'text';
const String _startBool = 'boolean';
const String _startDateTime = 'dateTime';
const String _startBlob = 'blob';
const String _startReal = 'real';
const String _startCustom = 'customType';

const Set<String> _starters = {
  _startInt,
  _startInt64,
  _startIntEnum,
  _startTextEnum,
  _startString,
  _startBool,
  _startDateTime,
  _startBlob,
  _startReal,
  _startCustom,
};

const String _methodNamed = 'named';
const String _methodReferences = 'references';
const String _methodAutoIncrement = 'autoIncrement';
const String _methodWithLength = 'withLength';
const String _methodNullable = 'nullable';
const String _methodUnique = 'unique';
const String _methodCustomConstraint = 'customConstraint';
const String _methodDefault = 'withDefault';
const String _methodClientDefault = 'clientDefault';
const String _methodMap = 'map';
const String _methodGenerated = 'generatedAs';
const String _methodCheck = 'check';
const Set<String> _addsSqlConstraint = {
  _methodReferences,
  _methodAutoIncrement,
  _methodUnique,
  _methodDefault,
  _methodGenerated,
  _methodCheck,
};

const String _errorMessage = 'This getter does not create a valid column that '
    'can be parsed by drift. Please refer to the readme from drift to see how '
    'columns are formed. If you have any questions, feel free to raise an '
    'issue.';

/// Parses a single column defined in a Dart table. These columns are a chain
/// or [MethodInvocation]s. An example getter might look like this:
/// ```dart
/// IntColumn get id => integer().autoIncrement()();
/// ```
/// The last call `()` is a [FunctionExpressionInvocation], the entries for
/// before that (in this case `autoIncrement()` and `integer()` are a)
/// [MethodInvocation]. We work our way through that syntax until we hit a
/// method that starts the chain (contained in [starters]). By visiting all
/// the invocations on our way, we can extract the constraint for the column
/// (e.g. its name, whether it has auto increment, is a primary key and so on).
class ColumnParser {
  final DartTableResolver _resolver;

  ColumnParser(this._resolver);

  Future<PendingColumnInformation?> parse(
      MethodDeclaration getter, Element element) async {
    final expr = returnExpressionOfMethod(getter);

    if (expr is! FunctionExpressionInvocation) {
      _resolver.reportError(
          DriftAnalysisError.forDartElement(element, _errorMessage));
      return null;
    }

    var remainingExpr = expr.function as MethodInvocation;

    String? foundStartMethod;
    String? foundExplicitName;
    String? foundCustomConstraint;
    Expression? customConstraintSource;
    AnnotatedDartCode? foundDefaultExpression;
    AnnotatedDartCode? clientDefaultExpression;
    Expression? mappedAs;
    String? referencesColumnInSameTable;

    var nullable = false;
    var hasDefaultConstraints = false;

    final foundConstraints = <DriftColumnConstraint>[];

    while (true) {
      final methodName = remainingExpr.methodName.name;

      if (_starters.contains(methodName)) {
        foundStartMethod = methodName;
        break;
      }

      if (_addsSqlConstraint.contains(methodName)) {
        hasDefaultConstraints = true;
      }

      switch (methodName) {
        case _methodNamed:
          if (foundExplicitName != null) {
            _resolver.reportError(
              DriftAnalysisError.forDartElement(
                element,
                "You're setting more than one name here, the first will "
                'be used',
              ),
            );
          }

          foundExplicitName =
              readStringLiteral(remainingExpr.argumentList.arguments.first);
          if (foundExplicitName == null) {
            _resolver.reportError(DriftAnalysisError.inDartAst(
                element,
                remainingExpr.argumentList,
                'This table name is cannot be resolved! Please only use '
                'a constant string as parameter for .named().'));
          }
          break;
        case _methodReferences:
          final args = remainingExpr.argumentList.arguments;
          final first = args.first;

          if (first is! Identifier) {
            _resolver.reportError(DriftAnalysisError.inDartAst(
              element,
              first,
              'This parameter should be a simple class name',
            ));
            break;
          }

          final staticElement = first.staticElement;
          if (staticElement is! ClassElement) {
            _resolver.reportError(DriftAnalysisError.inDartAst(
              element,
              first,
              '`${first.name}` is not a class!',
            ));
            break;
          }

          final columnNameNode = args[1];
          if (columnNameNode is! SymbolLiteral) {
            _resolver.reportError(DriftAnalysisError.inDartAst(
              element,
              columnNameNode,
              'This should be a symbol literal (`#columnName`)',
            ));
            break;
          }

          final columnName =
              columnNameNode.components.map((token) => token.lexeme).join('.');

          ReferenceAction? onUpdate, onDelete;

          ReferenceAction? parseAction(Expression expr) {
            if (expr is! PrefixedIdentifier) {
              _resolver.reportError(DriftAnalysisError.inDartAst(element, expr,
                  'Should be a direct enum reference (`KeyAction.cascade`)'));
              return null;
            }

            final name = expr.identifier.name;
            switch (name) {
              case 'setNull':
                return ReferenceAction.setNull;
              case 'setDefault':
                return ReferenceAction.setDefault;
              case 'cascade':
                return ReferenceAction.cascade;
              case 'restrict':
                return ReferenceAction.restrict;
              case 'noAction':
              default:
                return ReferenceAction.noAction;
            }
          }

          for (final expr in args) {
            if (expr is! NamedExpression) continue;

            final name = expr.name.label.name;
            final value = expr.expression;
            if (name == 'onUpdate') {
              onUpdate = parseAction(value);
            } else if (name == 'onDelete') {
              onDelete = parseAction(value);
            }
          }

          final referencedTable = await _resolver.resolver
              .resolveDartReference(_resolver.discovered.ownId, staticElement);

          if (referencedTable is ReferencesItself) {
            // "Foreign" key to a column in the same table.
            foundConstraints
                .add(ForeignKeyReference.unresolved(onUpdate, onDelete));
            referencesColumnInSameTable = columnName;
          } else if (referencedTable is ResolvedReferenceFound) {
            final driftElement = referencedTable.element;

            if (driftElement is DriftTable) {
              final column = driftElement.columns.firstWhereOrNull(
                  (element) => element.nameInDart == columnName);

              if (column == null) {
                _resolver.reportError(DriftAnalysisError.inDartAst(
                  element,
                  columnNameNode,
                  'The referenced table `${driftElement.schemaName}` has no '
                  'column named `$columnName` in Dart.',
                ));
              } else {
                foundConstraints
                    .add(ForeignKeyReference(column, onUpdate, onDelete));
              }
            } else {
              _resolver.reportError(
                  DriftAnalysisError.inDartAst(element, first, 'Not a table'));
            }
          } else {
            // Could not resolve foreign table, emit warning
            _resolver.reportErrorForUnresolvedReference(referencedTable,
                (msg) => DriftAnalysisError.inDartAst(element, first, msg));
          }

          break;
        case _methodWithLength:
          final args = remainingExpr.argumentList;
          final minArg = findNamedArgument(args, 'min');
          final maxArg = findNamedArgument(args, 'max');

          foundConstraints.add(LimitingTextLength(
            minLength: minArg != null ? readIntLiteral(minArg) : null,
            maxLength: maxArg != null ? readIntLiteral(maxArg) : null,
          ));
          break;
        case _methodAutoIncrement:
          foundConstraints.add(PrimaryKeyColumn(true));
          break;
        case _methodNullable:
          nullable = true;
          break;
        case _methodUnique:
          foundConstraints.add(const UniqueColumn());
          break;
        case _methodCustomConstraint:
          if (foundCustomConstraint != null) {
            _resolver.reportError(
              DriftAnalysisError.inDartAst(
                element,
                remainingExpr.methodName,
                "You've already set custom constraints on this column, "
                'they will be overriden by this call.',
              ),
            );
          }

          final stringLiteral = customConstraintSource =
              remainingExpr.argumentList.arguments.first;
          foundCustomConstraint = readStringLiteral(stringLiteral);

          if (foundCustomConstraint == null) {
            _resolver.reportError(DriftAnalysisError.forDartElement(
              element,
              'This constraint is cannot be resolved! Please only use '
              'a constant string as parameter for .customConstraint().',
            ));
          }
          break;
        case _methodDefault:
          final args = remainingExpr.argumentList;
          final expression = args.arguments.single;
          foundDefaultExpression = AnnotatedDartCode.ast(expression);
          break;
        case _methodClientDefault:
          clientDefaultExpression = AnnotatedDartCode.ast(
              remainingExpr.argumentList.arguments.single);
          break;
        case _methodMap:
          final args = remainingExpr.argumentList;
          mappedAs = args.arguments.single;
          break;
        case _methodGenerated:
          Expression? generatedExpression;
          var stored = false;

          for (final expr in remainingExpr.argumentList.arguments) {
            if (expr is NamedExpression && expr.name.label.name == 'stored') {
              final storedValue = expr.expression;
              if (storedValue is BooleanLiteral) {
                stored = storedValue.value;
              } else {
                _resolver.reportError(DriftAnalysisError.inDartAst(
                    element, expr, 'Must be a boolean literal'));
              }
            } else {
              generatedExpression = expr;
            }
          }

          if (generatedExpression != null) {
            final code = AnnotatedDartCode.ast(generatedExpression);
            foundConstraints.add(ColumnGeneratedAs(code, stored));
          }
          break;
        case _methodCheck:
          final expr = remainingExpr.argumentList.arguments.first;
          foundConstraints
              .add(DartCheckExpression(AnnotatedDartCode.ast(expr)));
      }

      // We're not at a starting method yet, so we need to go deeper!
      final inner = remainingExpr.target as MethodInvocation;
      remainingExpr = inner;
    }

    final sqlName = foundExplicitName ??
        _resolver.resolver.driver.options.caseFromDartToSql
            .apply(getter.name.lexeme);
    ColumnType columnType;

    final helper = await _resolver.resolver.driver.loadKnownTypes();

    if (foundStartMethod == _startCustom) {
      final expression = remainingExpr.argumentList.arguments.single;

      final custom = readCustomType(
        element.library!,
        expression,
        helper,
        (message) => _resolver.reportError(
          DriftAnalysisError.inDartAst(element, mappedAs!, message),
        ),
      );
      columnType = custom != null
          ? ColumnType.custom(custom)
          // Fallback if we fail to read the custom type - we'll also emit an
          // error int that case.
          : ColumnType.drift(DriftSqlType.any);
    } else {
      columnType =
          ColumnType.drift(_startMethodToBuiltinColumnType(foundStartMethod));
    }

    AppliedTypeConverter? converter;
    if (mappedAs != null) {
      converter = readTypeConverter(
        element.library!,
        mappedAs,
        columnType,
        nullable,
        (message) => _resolver.reportError(
            DriftAnalysisError.inDartAst(element, mappedAs!, message)),
        helper,
      );
    }

    if (foundStartMethod == _startIntEnum) {
      if (converter != null) {
        _resolver.reportError(DriftAnalysisError.forDartElement(
          element,
          'Using $_startIntEnum will apply a custom converter by default, '
          "so you can't add an additional converter",
        ));
      }

      final enumType = remainingExpr.typeArgumentTypes!.first;
      converter = readEnumConverter(
        (msg) => _resolver.reportError(DriftAnalysisError.inDartAst(element,
            remainingExpr.typeArguments ?? remainingExpr.methodName, msg)),
        enumType,
        EnumType.intEnum,
        helper,
      );
    } else if (foundStartMethod == _startTextEnum) {
      if (converter != null) {
        _resolver.reportError(DriftAnalysisError.forDartElement(
          element,
          'Using $_startTextEnum will apply a custom converter by default, '
          "so you can't add an additional converter",
        ));
      }

      final enumType = remainingExpr.typeArgumentTypes!.first;
      converter = readEnumConverter(
        (msg) => _resolver.reportError(DriftAnalysisError.inDartAst(element,
            remainingExpr.typeArguments ?? remainingExpr.methodName, msg)),
        enumType,
        EnumType.textEnum,
        helper,
      );
    }

    if (foundDefaultExpression != null && clientDefaultExpression != null) {
      _resolver.reportError(
        DriftAnalysisError.forDartElement(
          element,
          'clientDefault() and withDefault() are mutually exclusive, '
          "they can't both be used. Use clientDefault() for values that "
          'are different for each row and withDefault() otherwise.',
        ),
      );
    }

    if (foundConstraints.contains(const UniqueColumn()) &&
        foundConstraints.any((e) => e is PrimaryKeyColumn)) {
      _resolver.reportError(
        DriftAnalysisError.forDartElement(
          element,
          'Primary key column cannot have UNIQUE constraint',
        ),
      );
    }

    if (hasDefaultConstraints && foundCustomConstraint != null) {
      _resolver.reportError(
        DriftAnalysisError.forDartElement(
          element,
          'This column definition is using both drift-defined '
          'constraints (like references, autoIncrement, ...) and a '
          'customConstraint(). Only the custom constraint will be added '
          'to the column in SQL!',
        ),
      );
    }

    final docString =
        getter.documentationComment?.tokens.map((t) => t.toString()).join('\n');

    foundConstraints.addAll(await _driftConstraintsFromCustomConstraints(
      isNullable: nullable,
      customConstraints: foundCustomConstraint,
      sourceForCustomConstraints: customConstraintSource,
    ));

    return PendingColumnInformation(
      DriftColumn(
        sqlType: columnType,
        nullable: nullable,
        nameInSql: sqlName,
        nameInDart: element.name!,
        declaration: DriftDeclaration.dartElement(element),
        typeConverter: converter,
        clientDefaultCode: clientDefaultExpression,
        defaultArgument: foundDefaultExpression,
        overriddenJsonName: _readJsonKey(element),
        documentationComment: docString,
        constraints: foundConstraints,
        customConstraints: foundCustomConstraint,
      ),
      referencesColumnInSameTable: referencesColumnInSameTable,
    );
  }

  DriftSqlType _startMethodToBuiltinColumnType(String name) {
    return const {
      _startBool: DriftSqlType.bool,
      _startString: DriftSqlType.string,
      _startInt: DriftSqlType.int,
      _startInt64: DriftSqlType.bigInt,
      _startIntEnum: DriftSqlType.int,
      _startTextEnum: DriftSqlType.string,
      _startDateTime: DriftSqlType.dateTime,
      _startBlob: DriftSqlType.blob,
      _startReal: DriftSqlType.double,
    }[name]!;
  }

  String? _readJsonKey(Element getter) {
    final annotations = getter.metadata;
    final object = annotations.firstWhereOrNull((e) {
      final value = e.computeConstantValue();
      final valueType = value?.type;

      return valueType is InterfaceType &&
          isFromDrift(valueType) &&
          valueType.element.name == 'JsonKey';
    });

    if (object == null) return null;

    return object.computeConstantValue()!.getField('key')!.toStringValue();
  }

  Future<List<DriftColumnConstraint>> _driftConstraintsFromCustomConstraints({
    required bool isNullable,
    String? customConstraints,
    AstNode? sourceForCustomConstraints,
  }) async {
    if (customConstraints == null) return const [];

    final engine = _resolver.resolver.driver.newSqlEngine();
    final parseResult = engine.parseColumnConstraints(customConstraints);
    final constraints =
        (parseResult.rootNode as sql.ColumnDefinition).constraints;

    for (final error in parseResult.errors) {
      _resolver.reportError(DriftAnalysisError(error.token.span,
          'Parse error in customConstraint(): ${error.message}'));
    }

    // Constraints override all constraints that drift will add. So if the
    // column is non-nullable, there should be a `NON NULL` constraint.
    if (!isNullable && !constraints.any((e) => e is sql.NotNull)) {
      _resolver.reportError(DriftAnalysisError.inDartAst(
        _resolver.discovered.dartElement,
        sourceForCustomConstraints!,
        "This column is not declared to be `.nullable()`, but also doesn't "
        'have `NOT NULL` in its custom constraints. Please explicitly declare '
        'the column to be nullable in Dart, or add a `NOT NULL` constraint for '
        'consistency.',
      ));
    }

    final parsedConstraints = <DriftColumnConstraint>[];

    for (final constraint in constraints) {
      if (constraint is sql.GeneratedAs) {
        parsedConstraints.add(ColumnGeneratedAs.fromParser(constraint));
      } else if (constraint is sql.PrimaryKeyColumn) {
        parsedConstraints.add(PrimaryKeyColumn(constraint.autoIncrement));
      } else if (constraint is sql.UniqueColumn) {
        parsedConstraints.add(UniqueColumn());
      } else if (constraint is sql.ForeignKeyColumnConstraint) {
        final clause = constraint.clause;

        final table =
            await _resolver.resolveSqlReferenceOrReportError<DriftTable>(
          clause.foreignTable.tableName,
          (msg) => DriftAnalysisError.inDartAst(
            _resolver.discovered.dartElement,
            sourceForCustomConstraints!,
            msg,
          ),
        );

        if (table != null) {
          final columnName = clause.columnNames.first;
          final column =
              table.columnBySqlName[clause.columnNames.first.columnName];

          if (column == null) {
            _resolver.reportError(DriftAnalysisError.inDartAst(
              _resolver.discovered.dartElement,
              sourceForCustomConstraints!,
              'The referenced table has no column named `$columnName`',
            ));
          } else {
            parsedConstraints.add(ForeignKeyReference(
              column,
              constraint.clause.onUpdate,
              constraint.clause.onDelete,
            ));
          }
        }
      }
    }

    return parsedConstraints;
  }
}

class PendingColumnInformation {
  final DriftColumn column;

  /// If the returned column references another column in the same table, its
  /// [ForeignKeyReference] is still unresolved when the local column resolver
  /// returns.
  ///
  /// It is the responsibility of the table resolver to patch the reference for
  /// this column in that case.
  final String? referencesColumnInSameTable;

  PendingColumnInformation(this.column, {this.referencesColumnInSameTable});
}
