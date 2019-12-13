part of 'parser.dart';

const String startInt = 'integer';
const String startString = 'text';
const String startBool = 'boolean';
const String startDateTime = 'dateTime';
const String startBlob = 'blob';
const String startReal = 'real';

const Set<String> starters = {
  startInt,
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
const String _methodMap = 'map';

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

  SpecifiedColumn parse(MethodDeclaration getter, Element element) {
    final expr = base.returnExpressionOfMethod(getter);

    if (expr is! FunctionExpressionInvocation) {
      base.step.reportError(ErrorInDartCode(
        affectedElement: getter.declaredElement,
        message: _errorMessage,
        severity: Severity.criticalError,
      ));
      return null;
    }

    var remainingExpr =
        (expr as FunctionExpressionInvocation).function as MethodInvocation;

    String foundStartMethod;
    String foundExplicitName;
    String foundCustomConstraint;
    Expression foundDefaultExpression;
    Expression createdTypeConverter;
    DartType typeConverterRuntime;
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
          break;
        case _methodWithLength:
          final args = remainingExpr.argumentList;
          final minArg = base.findNamedArgument(args, 'min');
          final maxArg = base.findNamedArgument(args, 'max');

          foundFeatures.add(LimitingTextLength(
            minLength: base.readIntLiteral(minArg, () {}),
            maxLength: base.readIntLiteral(maxArg, () {}),
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
        case _methodMap:
          final args = remainingExpr.argumentList;
          final expression = args.arguments.single;

          // the map method has a parameter type that resolved to the runtime
          // type of the custom object
          final type = remainingExpr.typeArgumentTypes.single;

          createdTypeConverter = expression;
          typeConverterRuntime = type;
          break;
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

    UsedTypeConverter converter;
    if (createdTypeConverter != null && typeConverterRuntime != null) {
      converter = UsedTypeConverter(
          expression: createdTypeConverter,
          mappedType: typeConverterRuntime,
          sqlType: columnType);
    }

    final column = SpecifiedColumn(
        type: columnType,
        dartGetterName: getter.name.name,
        name: name,
        overriddenJsonName: _readJsonKey(element),
        customConstraints: foundCustomConstraint,
        nullable: nullable,
        features: foundFeatures,
        defaultArgument: foundDefaultExpression?.toSource(),
        typeConverter: converter);

    final declaration =
        ColumnDeclaration(column, base.step.file, element, null);
    return column..declaration = declaration;
  }

  ColumnType _startMethodToColumnType(String startMethod) {
    return const {
      startBool: ColumnType.boolean,
      startString: ColumnType.text,
      startInt: ColumnType.integer,
      startDateTime: ColumnType.datetime,
      startBlob: ColumnType.blob,
      startReal: ColumnType.real,
    }[startMethod];
  }

  String _readJsonKey(Element getter) {
    final annotations = getter.metadata;
    final object = annotations.singleWhere((e) {
      final value = e.computeConstantValue();
      return isFromMoor(value.type) && value.type.name == 'JsonKey';
    }, orElse: () => null);

    if (object == null) return null;

    return object.constantValue.getField('key').toStringValue();
  }
}
