part of 'parser.dart';

const String startInt = 'integer';
const String startEnum = 'intEnum';
const String startString = 'text';
const String startBool = 'boolean';
const String startDateTime = 'dateTime';
const String startBlob = 'blob';
const String startReal = 'real';

const Set<String> starters = {
  startInt,
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
const String _methodCustomConstraint = 'customConstraint';
const String _methodDefault = 'withDefault';
const String _methodClientDefault = 'clientDefault';
const String _methodMap = 'map';
const String _methodGenerated = 'generatedAs';

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
    Expression? createdTypeConverter;
    DartType? typeConverterRuntime;
    ColumnGeneratedAs? generatedAs;
    var nullable = false;

    final foundFeatures = <ColumnFeature>[];

    for (;;) {
      final methodName = remainingExpr.methodName.name;

      if (starters.contains(methodName)) {
        foundStartMethod = methodName;
        break;
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
        case _methodCustomConstraint:
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

          // the map method has a parameter type that resolved to the runtime
          // type of the custom object
          final type = remainingExpr.typeArgumentTypes!.single;

          createdTypeConverter = expression;
          typeConverterRuntime = type;
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
    if (createdTypeConverter != null && typeConverterRuntime != null) {
      converter = UsedTypeConverter(
          expression: createdTypeConverter.toSource(),
          mappedType: typeConverterRuntime,
          sqlType: columnType,
          nullable: nullable);
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
        converter = UsedTypeConverter.forEnumColumn(enumType, nullable);
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
