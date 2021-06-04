//@dart=2.9
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
const String _methodForeignKey = 'foreignKey';

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

  String _parseKeyAction(String enumValue) {
    switch (enumValue) {
      case 'noAction':
        return 'NO ACTION';
      case 'cascade':
        return 'CASCADE';
      case 'restrict':
        return 'RESTRICT';
      case 'setNull':
        return 'SET NULL';
      case 'setDefault':
        return 'SET DEFAULT';
    }
    return '';
  }

  MoorColumn parse(MethodDeclaration getter, Element element) {
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
    Expression clientDefaultExpression;
    Expression createdTypeConverter;
    DartType typeConverterRuntime;
    DartType fkType;
    String fkUpdateAction;
    String fkDeleteAction;
    String fkColumn = 'id';
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
        case _methodClientDefault:
          clientDefaultExpression = remainingExpr.argumentList.arguments.single;
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
        case _methodForeignKey:
          fkType =
              ((remainingExpr.argumentList.arguments[0] as SimpleIdentifier)
                      .staticElement as ClassElement)
                  .thisType;

          final updateArg = remainingExpr.argumentList.arguments.firstWhere(
              (arg) =>
                  arg is NamedExpression &&
                  arg.name.label.token.toString() == 'onUpdate',
              orElse: () => null);

          if (updateArg != null) {
            fkUpdateAction = _parseKeyAction(((updateArg as NamedExpression)
                    .expression as PrefixedIdentifier)
                .identifier
                .token
                .toString());
          }

          final deleteArg = remainingExpr.argumentList.arguments.firstWhere(
              (arg) =>
                  arg is NamedExpression &&
                  arg.name.label.token.toString() == 'onDelete',
              orElse: () => null);

          if (deleteArg != null) {
            fkDeleteAction = _parseKeyAction(((deleteArg as NamedExpression)
                    .expression as PrefixedIdentifier)
                .identifier
                .token
                .toString());
          }

          final columnArg = remainingExpr.argumentList.arguments.firstWhere(
              (arg) =>
                  arg is NamedExpression &&
                  arg.name.label.token.toString() == 'column',
              orElse: () => null);

          if (columnArg != null) {
            fkColumn =
                ((columnArg as NamedExpression).expression as SymbolLiteral)
                    .components[0]
                    .toString();
          }
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
          expression: createdTypeConverter.toSource(),
          mappedType: typeConverterRuntime,
          sqlType: columnType);
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

      final enumType = remainingExpr.typeArgumentTypes[0];
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

    final docString = getter.documentationComment?.tokens
        ?.map((t) => t.toString())
        ?.join('\n');
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
      fkType: fkType,
      fkUpdateAction: fkUpdateAction,
      fkDeleteAction: fkDeleteAction,
      fkColumn: fkColumn,
    );
  }

  ColumnType _startMethodToColumnType(String startMethod) {
    return const {
      startBool: ColumnType.boolean,
      startString: ColumnType.text,
      startInt: ColumnType.integer,
      startEnum: ColumnType.integer,
      startDateTime: ColumnType.datetime,
      startBlob: ColumnType.blob,
      startReal: ColumnType.real,
    }[startMethod];
  }

  String _readJsonKey(Element getter) {
    final annotations = getter.metadata;
    final object = annotations.singleWhere((e) {
      final value = e.computeConstantValue();
      return isFromMoor(value.type) && value.type.element.name == 'JsonKey';
    }, orElse: () => null);

    if (object == null) return null;

    return object.computeConstantValue().getField('key').toStringValue();
  }
}
