import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:moor_generator/src/errors.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/parser/parser.dart';
import 'package:moor_generator/src/shared_state.dart';
import 'package:moor_generator/src/utils/type_utils.dart';
import 'package:recase/recase.dart';

const String startInt = 'integer';
const String startString = 'text';
const String startBool = 'boolean';
const String startDateTime = 'dateTime';
const String startBlob = 'blob';
const String startReal = 'real';

final Set<String> starters = {
  startInt,
  startString,
  startBool,
  startDateTime,
  startBlob,
  startReal,
};

const String _methodNamed = 'named';
const String _methodPrimaryKey = 'primaryKey';
const String _methodReferences = 'references';
const String _methodAutoIncrement = 'autoIncrement';
const String _methodWithLength = 'withLength';
const String _methodNullable = 'nullable';
const String _methodCustomConstraint = 'customConstraint';
const String _methodDefault = 'withDefault';
const String _methodMap = 'map';

const String _errorMessage = 'This getter does not create a valid column that '
    'can be parsed by moor. Please refer to the readme from moor to see how '
    'columns are formed. If you have any questions, feel free to raise an issue.';

class ColumnParser extends ParserBase {
  ColumnParser(SharedState state) : super(state);

  SpecifiedColumn parse(MethodDeclaration getter, Element getterElement) {
    /*
      These getters look like this: ... get id => integer().autoIncrement()();
      The last () is a FunctionExpressionInvocation, the entries before that
      (here autoIncrement and integer) are MethodInvocations.
      We go through each of the method invocations until we hit one that starts
      the chain (integer, text, boolean, etc.). From each method in the chain,
      we can extract what it means for the column (name, auto increment, PK,
      constraints...).
     */

    final expr = returnExpressionOfMethod(getter);

    if (!(expr is FunctionExpressionInvocation)) {
      state.errors.add(MoorError(
        affectedElement: getter.declaredElement,
        message: _errorMessage,
        critical: true,
      ));

      return null;
    }

    var remainingExpr =
        (expr as FunctionExpressionInvocation).function as MethodInvocation;

    String foundStartMethod;
    String foundExplicitName;
    String foundCustomConstraint;
    Expression foundDefaultExpression;
    Expression foundTypeConverter;
    DartType overrideDartType;
    var wasDeclaredAsPrimaryKey = false;
    var nullable = false;

    final foundFeatures = <ColumnFeature>[];

    while (true) {
      final methodName = remainingExpr.methodName.name;

      if (starters.contains(methodName)) {
        foundStartMethod = methodName;
        break;
      }

      switch (methodName) {
        case _methodNamed:
          if (foundExplicitName != null) {
            state.errors.add(
              MoorError(
                critical: false,
                affectedElement: getter.declaredElement,
                message:
                    "You're setting more than one name here, the first will "
                    'be used',
              ),
            );
          }

          foundExplicitName =
              readStringLiteral(remainingExpr.argumentList.arguments.first, () {
            state.errors.add(
              MoorError(
                critical: false,
                affectedElement: getter.declaredElement,
                message:
                    'This table name is cannot be resolved! Please only use '
                    'a constant string as parameter for .named().',
              ),
            );
          });
          break;
        case _methodPrimaryKey:
          wasDeclaredAsPrimaryKey = true;
          break;
        case _methodReferences:
          break;
        case _methodWithLength:
          final args = remainingExpr.argumentList;
          final minArg = findNamedArgument(args, 'min');
          final maxArg = findNamedArgument(args, 'max');

          foundFeatures.add(LimitingTextLength.withLength(
            min: readIntLiteral(minArg, () {}),
            max: readIntLiteral(maxArg, () {}),
          ));
          break;
        case _methodAutoIncrement:
          wasDeclaredAsPrimaryKey = true;
          foundFeatures.add(AutoIncrement());
          break;
        case _methodNullable:
          nullable = true;
          break;
        case _methodCustomConstraint:
          foundCustomConstraint =
              readStringLiteral(remainingExpr.argumentList.arguments.first, () {
            state.errors.add(
              MoorError(
                critical: false,
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

          foundTypeConverter = expression;
          overrideDartType = type;
          break;
      }

      // We're not at a starting method yet, so we need to go deeper!
      final inner = (remainingExpr.target) as MethodInvocation;
      remainingExpr = inner;
    }

    ColumnName name;
    if (foundExplicitName != null) {
      name = ColumnName.explicitly(foundExplicitName);
    } else {
      name = ColumnName.implicitly(ReCase(getter.name.name).snakeCase);
    }

    return SpecifiedColumn(
      type: _startMethodToColumnType(foundStartMethod),
      dartGetterName: getter.name.name,
      name: name,
      overriddenJsonName: _readJsonKey(getterElement),
      declaredAsPrimaryKey: wasDeclaredAsPrimaryKey,
      customConstraints: foundCustomConstraint,
      nullable: nullable,
      features: foundFeatures,
      defaultArgument: foundDefaultExpression,
      typeConverter: foundTypeConverter,
      overriddenDartType: overrideDartType,
    );
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
