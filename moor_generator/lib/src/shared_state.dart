import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:moor/moor.dart' show Table;
import 'package:moor_generator/src/parser/column_parser.dart';
import 'package:moor_generator/src/parser/table_parser.dart';
import 'package:source_gen/source_gen.dart';

import 'errors.dart';
import 'model/specified_table.dart';
import 'options.dart';

/// Information that is needed for both the regular generator and the dao
/// generator. Kept in sync so it only needs to be evaluated once.
class SharedState {
  final ErrorStore errors = ErrorStore();
  final MoorOptions options;

  TableParser tableParser;
  ColumnParser columnParser;

  final tableTypeChecker = const TypeChecker.fromRuntime(Table);

  final Map<DartType, SpecifiedTable> foundTables = {};

  SharedState(this.options) {
    tableParser = TableParser(this);
    columnParser = ColumnParser(this);
  }

  ElementDeclarationResult loadElementDeclaration(Element element) {
    final result =
        element.library.session.getParsedLibraryByElement(element.library);
    return result.getElementDeclaration(element);
  }

  SpecifiedTable parseType(DartType type, Element initializedBy) {
    return foundTables.putIfAbsent(type, () {
      if (!tableTypeChecker.isAssignableFrom(type.element)) {
        errors.add(MoorError(
          critical: true,
          message: 'The type $type is not a moor table',
          affectedElement: initializedBy,
        ));
        return null;
      } else {
        return tableParser.parse(type.element as ClassElement);
      }
    });
  }
}
