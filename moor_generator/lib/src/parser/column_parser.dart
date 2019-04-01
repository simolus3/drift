import 'package:analyzer/dart/ast/ast.dart';
import 'package:moor_generator/src/errors.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/parser/parser.dart';
import 'package:moor_generator/src/moor_generator.dart';
import 'package:recase/recase.dart';

const String startInt = 'integer';
const String startString = 'text';
const String startBool = 'boolean';
const String startDateTime = 'dateTime';
const String startBlob = 'blob';

final Set<String> starters =
    {startInt, startString, startBool, startDateTime, startBlob};

const String functionNamed = 'named';
const String functionPrimaryKey = 'primaryKey';
const String functionReferences = 'references';
const String functionAutoIncrement = 'autoIncrement';
const String functionWithLength = 'withLength';
const String functionNullable = 'nullable';
const String functionCustomConstraint = 'customConstraint';

const String errorMessage = 'This getter does not create a valid column that '
    'can be parsed by moor. Please refer to the readme from moor to see how '
    'columns are formed. If you have any questions, feel free to raise an issue.';

class ColumnParser extends ParserBase {
  ColumnParser(MoorGenerator generator) : super(generator);

  SpecifiedColumn parse(MethodDeclaration getter) {
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
      generator.errors.add(MoorError(
        affectedElement: getter.declaredElement,
        message: errorMessage,
        critical: true,
      ));

      return null;
    }

    var remainingExpr =
        (expr as FunctionExpressionInvocation).function as MethodInvocation;

    String foundStartMethod;
    String foundExplicitName;
    String foundCustomConstraint;
    var wasDeclaredAsPrimaryKey = false;
    var nullable = false;
    // todo parse reference
    final foundFeatures = <ColumnFeature>[];

    while (true) {
      final methodName = remainingExpr.methodName.name;

      if (starters.contains(methodName)) {
        foundStartMethod = methodName;
        break;
      }

      switch (methodName) {
        case functionNamed:
          if (foundExplicitName != null) {
            generator.errors.add(
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
            generator.errors.add(
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
        case functionPrimaryKey:
          wasDeclaredAsPrimaryKey = true;
          break;
        case functionReferences:
          break;
        case functionWithLength:
          final args = remainingExpr.argumentList;
          final minArg = findNamedArgument(args, 'min');
          final maxArg = findNamedArgument(args, 'max');

          foundFeatures.add(LimitingTextLength.withLength(
            min: readIntLiteral(minArg, () {}),
            max: readIntLiteral(maxArg, () {}),
          ));
          break;
        case functionAutoIncrement:
          wasDeclaredAsPrimaryKey = true;
          foundFeatures.add(AutoIncrement());
          break;
        case functionNullable:
          nullable = true;
          break;
        case functionCustomConstraint:
          foundCustomConstraint =
              readStringLiteral(remainingExpr.argumentList.arguments.first, () {
            generator.errors.add(
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
        declaredAsPrimaryKey: wasDeclaredAsPrimaryKey,
        customConstraints: foundCustomConstraint,
        nullable: nullable,
        features: foundFeatures);
  }

  ColumnType _startMethodToColumnType(String startMethod) {
    return const {
      startBool: ColumnType.boolean,
      startString: ColumnType.text,
      startInt: ColumnType.integer,
      startDateTime: ColumnType.datetime,
      startBlob: ColumnType.blob,
    }[startMethod];
  }
}
