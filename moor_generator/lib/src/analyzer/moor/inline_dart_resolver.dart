import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:moor_generator/src/analyzer/runner/steps.dart';

/// Resolves the type of Dart expressions given as a string. The
/// [importStatements] are used to discover types.
///
/// The way this works is that we create a fake file for the analyzer. That file
/// has the following content:
/// ```
/// import 'package:moor/moor.dart'; // always imported
/// // all import statements
///
/// var expr = $expression;
/// ```
///
/// We can then obtain the type of an expression by reading the inferred type
/// of the top-level `expr` variable in that source.
class InlineDartResolver {
  final List<String> importStatements = [];
  final ParseMoorFile step;

  InlineDartResolver(this.step);

  Future<DartType> resolveDartTypeOf(String expression) async {
    final template = _createDartTemplate(expression);
    final unit = await step.task.backend.parseSource(template);

    final declaration = unit.declarations.single as TopLevelVariableDeclaration;
    return declaration.variables.variables.single.initializer.staticType;
  }

  String _createDartTemplate(String expression) {
    final fakeDart = StringBuffer();

    fakeDart.write("import 'package:moor/moor.dart';\n");
    for (var import in importStatements) {
      fakeDart.write("import '$import';\n");
    }

    fakeDart.write('var expr = $expression;\n');

    return fakeDart.toString();
  }
}
