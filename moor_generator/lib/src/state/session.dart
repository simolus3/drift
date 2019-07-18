import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/parser/column_parser.dart';
import 'package:moor_generator/src/parser/table_parser.dart';

import 'errors.dart';
import 'generator_state.dart';
import 'options.dart';

class GeneratorSession {
  final GeneratorState state;
  final ErrorStore errors = ErrorStore();
  final BuildStep step;

  TableParser _tableParser;
  ColumnParser _columnParser;

  MoorOptions get options => state.options;

  GeneratorSession(this.state, this.step) {
    _tableParser = TableParser(this);
    _columnParser = ColumnParser(this);
  }

  Future<ElementDeclarationResult> loadElementDeclaration(
      Element element) async {
    final resolvedLibrary = await element.library.session
        .getResolvedLibraryByElement(element.library);

    return resolvedLibrary.getElementDeclaration(element);
  }

  /// Resolves a [SpecifiedTable] for the class of each [DartType] in [types].
  /// The [initializedBy] element should be the piece of code that caused the
  /// parsing (e.g. the database class that is annotated with `@UseMoor`). This
  /// will allow for more descriptive error messages.
  Future<List<SpecifiedTable>> parseTables(
      Iterable<DartType> types, Element initializedBy) {
    return Future.wait(types.map((type) {
      if (!state.tableTypeChecker.isAssignableFrom(type.element)) {
        errors.add(MoorError(
          critical: true,
          message: 'The type $type is not a moor table',
          affectedElement: initializedBy,
        ));
        return null;
      } else {
        return _tableParser.parse(type.element as ClassElement);
      }
    }));
  }

  Future<SpecifiedColumn> parseColumn(MethodDeclaration m, Element e) {
    return Future.value(_columnParser.parse(m, e));
  }
}
