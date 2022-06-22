part of 'parser.dart';

const String startInt = 'integer';
const String startInt64 = 'int64';
const String startEnum = 'intEnum';
const String startString = 'text';
const String startBool = 'boolean';
const String startDateTime = 'dateTime';
const String startBlob = 'blob';
const String startReal = 'real';

const Set<String> starters = {
  startInt,
  startInt64,
  startEnum,
  startString,
  startBool,
  startDateTime,
  startBlob,
  startReal,
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
    'can be parsed by moor. Please refer to the readme from moor to see how '
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
  final MoorDartParser base;

  ColumnParser(this.base);

  MoorColumn? parse(MethodDeclaration getter, Element element) {
    final expr = base.returnExpressionOfMethod(getter);

    if (expr is! FunctionExpressionInvocation) {
      base.step.reportError(ErrorInDartCode(
        affectedElement: getter.declaredElement,
        message: _errorMessage,
        severity: Severity.criticalError,
      ));
      return null;
    }

    var remainingExpr = expr.function as MethodInvocation;

    String? foundStartMethod;
    String? foundExplicitName;
    String? foundCustomConstraint;
    Expression? foundDefaultExpression;
    Expression? clientDefaultExpression;
    _PartialTypeConverterInformation? mappedAs;
    ColumnGeneratedAs? generatedAs;
    var nullable = false;
    var hasDefaultConstraints = false;

    final foundFeatures = <ColumnFeature>[];

    for (;;) {
      final methodName = remainingExpr.methodName.name;

      if (starters.contains(methodName)) {
        foundStartMethod = methodName;
        break;
      }

      if (_addsSqlConstraint.contains(methodName)) {
        hasDefaultConstraints = true;
      }

      switch (methodName) {
        case _methodNamed:
          if (foundExplicitName != null) {
            base.step.reportError(
              ErrorInDartCode(
                severity: Severity.warning,
                affectedElement: getter.declaredElement,
                message:
                    "You're setting more than one name here, the first will "
                    'be used',
              ),
            );
          }

          foundExplicitName = base.readStringLiteral(
              remainingExpr.argumentList.arguments.first, () {
            base.step.reportError(
              ErrorInDartCode(
                severity: Severity.error,
                affectedElement: getter.declaredElement,
                message:
                    'This table name is cannot be resolved! Please only use '
                    'a constant string as parameter for .named().',
              ),
            );
          });
          break;
        case _methodReferences:
          final args = remainingExpr.argumentList.arguments;
          final first = args.first;

          if (first is! Identifier) {
            base.step.reportError(ErrorInDartCode(
              message: 'This parameter should be a simple class name',
              affectedElement: getter.declaredElement,
              affectedNode: first,
            ));
            break;
          }

          final staticElement = first.staticElement;
          if (staticElement is! ClassElement) {
            base.step.reportError(ErrorInDartCode(
              message: '${first.name} is not a class!',
              affectedElement: getter.declaredElement,
              affectedNode: first,
            ));
            break;
          }

          final columnNameNode = args[1];
          if (columnNameNode is! SymbolLiteral) {
            base.step.reportError(ErrorInDartCode(
              message: 'This should be a symbol literal (`#columnName`)',
              affectedElement: getter.declaredElement,
              affectedNode: columnNameNode,
            ));
            break;
          }

          final columnName =
              columnNameNode.components.map((token) => token.lexeme).join('.');

          ReferenceAction? onUpdate, onDelete;

          ReferenceAction? parseAction(Expression expr) {
            if (expr is! PrefixedIdentifier) {
              base.step.reportError(ErrorInDartCode(
                message:
                    'Should be a direct enum reference (`KeyAction.cascade`)',
                affectedElement: getter.declaredElement,
                affectedNode: expr,
              ));
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

          foundFeatures.add(UnresolvedDartForeignKeyReference(
            staticElement,
            columnName,
            onUpdate,
            onDelete,
            getter.declaredElement,
            first,
            columnNameNode,
          ));
          break;
        case _methodWithLength:
          final args = remainingExpr.argumentList;
          final minArg = base.findNamedArgument(args, 'min');
          final maxArg = base.findNamedArgument(args, 'max');

          foundFeatures.add(LimitingTextLength(
            minLength:
                minArg != null ? base.readIntLiteral(minArg, () {}) : null,
            maxLength:
                maxArg != null ? base.readIntLiteral(maxArg, () {}) : null,
          ));
          break;
        case _methodAutoIncrement:
          foundFeatures.add(AutoIncrement());
          // a column declared as auto increment is always a primary key
          foundFeatures.add(const PrimaryKey());
          break;
        case _methodNullable:
          nullable = true;
          break;
        case _methodUnique:
          foundFeatures.add(const UniqueKey());
          break;
        case _methodCustomConstraint:
          if (foundCustomConstraint != null) {
            base.step.reportError(
              ErrorInDartCode(
                severity: Severity.warning,
                affectedElement: getter.declaredElement,
                affectedNode: remainingExpr.methodName,
                message:
                    "You've already set custom constraints on this column, "
                    'they will be overriden by this call.',
              ),
            );
          }

          foundCustomConstraint = base.readStringLiteral(
              remainingExpr.argumentList.arguments.first, () {
            base.step.reportError(
              ErrorInDartCode(
                severity: Severity.warning,
                affectedElement: getter.declaredElement,
                message:
                    'This constraint is cannot be resolved! Please only use '
                    'a constant string as parameter for .customConstraint().',
              ),
            );
          });
          break;
        case _methodDefault:
          final args = remainingExpr.argumentList;
          final expression = args.arguments.single;
          foundDefaultExpression = expression;
          break;
        case _methodClientDefault:
          clientDefaultExpression = remainingExpr.argumentList.arguments.single;
          break;
        case _methodMap:
          final args = remainingExpr.argumentList;
          final expression = args.arguments.single;

          // If the converter type references a class that doesn't exist yet,
          // (and is hence `dynamic`), we assume that it will be generated and
          // accessible in the code. In this case, we copy the source into the
          // generated code instead of potentially transforming it.
          final checkDynamic = _ContainsDynamicDueToMissingClass();
          remainingExpr.typeArguments?.accept(checkDynamic);
          expression.accept(checkDynamic);
          DriftDartType? resolved;

          if (checkDynamic.foundDynamicDueToMissingClass) {
            resolved = DriftDartType(
              type: remainingExpr.typeArgumentTypes!.single,
              overiddenSource:
                  remainingExpr.typeArguments!.arguments[0].toSource(),
              nullabilitySuffix: NullabilitySuffix.none,
            );
          }

          mappedAs = _PartialTypeConverterInformation(expression, resolved);
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
                base.step.reportError(ErrorInDartCode(
                  message: 'Must be a boolean literal',
                  affectedNode: expr,
                  affectedElement: element,
                ));
              }
            } else {
              generatedExpression = expr;
            }
          }

          if (generatedExpression != null) {
            final code = element.source!.contents.data
                .substring(generatedExpression.offset, generatedExpression.end);
            generatedAs = ColumnGeneratedAs(code, stored);
          }
          break;
        case _methodCheck:
          final expr = remainingExpr.argumentList.arguments.first.toSource();
          foundFeatures.add(DartCheckExpression(expr));
      }

      // We're not at a starting method yet, so we need to go deeper!
      final inner = remainingExpr.target as MethodInvocation;
      remainingExpr = inner;
    }

    ColumnName name;
    if (foundExplicitName != null) {
      name = ColumnName.explicitly(foundExplicitName);
    } else {
      name = ColumnName.implicitly(ReCase(getter.name.name).snakeCase);
    }

    final columnType = _startMethodToColumnType(foundStartMethod);
    UsedTypeConverter? converter;

    if (mappedAs != null) {
      converter = readTypeConverter(
        base.step.library,
        mappedAs.dartExpression,
        columnType,
        nullable,
        (message) => base.step.reportError(
          ErrorInDartCode(
            message: message,
            affectedNode: mappedAs!.dartExpression,
            affectedElement: element,
          ),
        ),
        base.step.resolvedHelper,
        resolvedDartType: mappedAs.literalDartType,
      );
    }

    if (foundStartMethod == startEnum) {
      if (converter != null) {
        base.step.reportError(ErrorInDartCode(
          message: 'Using $startEnum will apply a custom converter by default, '
              "so you can't add an additional converter",
          affectedElement: getter.declaredElement,
          severity: Severity.warning,
        ));
      }

      final enumType = remainingExpr.typeArgumentTypes![0];
      try {
        converter = UsedTypeConverter.forEnumColumn(
            enumType, nullable, base.step.library.typeProvider);
      } on InvalidTypeForEnumConverterException catch (e) {
        base.step.errors.report(ErrorInDartCode(
          message: e.errorDescription,
          affectedElement: getter.declaredElement,
          severity: Severity.error,
        ));
      }
    }

    if (foundDefaultExpression != null && clientDefaultExpression != null) {
      base.step.reportError(
        ErrorInDartCode(
          severity: Severity.warning,
          affectedElement: getter.declaredElement,
          message: 'clientDefault() and withDefault() are mutually exclusive, '
              "they can't both be used. Use clientDefault() for values that "
              'are different for each row and withDefault() otherwise.',
        ),
      );
    }

    if (foundFeatures.contains(const UniqueKey()) &&
        foundFeatures.contains(const PrimaryKey())) {
      base.step.reportError(
        ErrorInDartCode(
          severity: Severity.error,
          affectedElement: getter.declaredElement,
          message: 'Primary key column cannot have UNIQUE constraint',
        ),
      );
    }

    if (hasDefaultConstraints && foundCustomConstraint != null) {
      base.step.reportError(
        ErrorInDartCode(
          severity: Severity.warning,
          affectedElement: getter.declaredElement,
          message: 'This column definition is using both drift-defined '
              'constraints (like references, autoIncrement, ...) and a '
              'customConstraint(). Only the custom constraint will be added '
              'to the column in SQL!',
        ),
      );
    }

    final docString =
        getter.documentationComment?.tokens.map((t) => t.toString()).join('\n');
    return MoorColumn(
      type: columnType,
      dartGetterName: getter.name.name,
      name: name,
      overriddenJsonName: _readJsonKey(element),
      customConstraints: foundCustomConstraint,
      nullable: nullable,
      features: foundFeatures,
      defaultArgument: foundDefaultExpression?.toSource(),
      clientDefaultCode: clientDefaultExpression?.toSource(),
      typeConverter: converter,
      declaration: DartColumnDeclaration(element, base.step.file),
      documentationComment: docString,
      generatedAs: generatedAs,
    );
  }

  ColumnType _startMethodToColumnType(String name) {
    return const {
      startBool: ColumnType.boolean,
      startString: ColumnType.text,
      startInt: ColumnType.integer,
      startInt64: ColumnType.bigInt,
      startEnum: ColumnType.integer,
      startDateTime: ColumnType.datetime,
      startBlob: ColumnType.blob,
      startReal: ColumnType.real,
    }[name]!;
  }

  String? _readJsonKey(Element getter) {
    final annotations = getter.metadata;
    final object = annotations.firstWhereOrNull((e) {
      final value = e.computeConstantValue();
      return value != null &&
          isFromMoor(value.type!) &&
          value.type!.element!.name == 'JsonKey';
    });

    if (object == null) return null;

    return object.computeConstantValue()!.getField('key')!.toStringValue();
  }
}

class _ContainsDynamicDueToMissingClass extends RecursiveAstVisitor<void> {
  bool foundDynamicDueToMissingClass = false;

  @override
  void visitNamedType(NamedType node) {
    if (node.type is DynamicType && node.name.name != 'dynamic') {
      foundDynamicDueToMissingClass = true;
    } else {
      super.visitNamedType(node);
    }
  }
}

/// Information used to resolve a type converter later.
///
/// To check whether a type converter is valid, we need to know the exact
/// column type and whether `nullable` was called at some point.
/// So we just store some information when we hit a `map` call and resolve the
/// type converter after all other methods in the column builder chain have been
/// evaluated.
class _PartialTypeConverterInformation {
  final Expression dartExpression;

  /// An attempt to recover the syntactic type of [dartExpression] during
  /// generation in case it hasn't been generated yet when the analyzer runs.
  final DriftDartType? literalDartType;

  _PartialTypeConverterInformation(this.dartExpression, this.literalDartType);
}
