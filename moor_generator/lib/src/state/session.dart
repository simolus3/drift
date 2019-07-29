import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/model/specified_column.dart';
import 'package:moor_generator/src/model/specified_dao.dart';
import 'package:moor_generator/src/model/specified_database.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/model/sql_query.dart';
import 'package:moor_generator/src/parser/column_parser.dart';
import 'package:moor_generator/src/parser/moor/moor_analyzer.dart';
import 'package:moor_generator/src/parser/sql/sql_parser.dart';
import 'package:moor_generator/src/parser/sql/type_mapping.dart';
import 'package:moor_generator/src/parser/table_parser.dart';
import 'package:moor_generator/src/parser/use_dao_parser.dart';
import 'package:moor_generator/src/parser/use_moor_parser.dart';
import 'package:source_gen/source_gen.dart';

import 'errors.dart';
import 'generator_state.dart';
import 'options.dart';
import 'writer.dart';

class GeneratorSession {
  final GeneratorState state;
  final ErrorStore errors = ErrorStore();
  final BuildStep step;

  final Writer writer = Writer();

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

  /// Parses a [SpecifiedDatabase] from the [ClassElement] which was annotated
  /// with `@UseMoor` and the [annotation] reader that reads the `@UseMoor`
  /// annotation.
  Future<SpecifiedDatabase> parseDatabase(
      ClassElement element, ConstantReader annotation) {
    return UseMoorParser(this).parseDatabase(element, annotation);
  }

  /// Parses a [SpecifiedDao] from a class declaration that has a `UseDao`
  /// [annotation].
  Future<SpecifiedDao> parseDao(
      ClassElement element, ConstantReader annotation) {
    return UseDaoParser(this).parseDao(element, annotation);
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
    })).then((list) => List.from(list)); // make growable
  }

  Future<List<SpecifiedTable>> resolveIncludes(Iterable<String> paths) async {
    final mapper = TypeMapper();
    final foundTables = <SpecifiedTable>[];

    for (var path in paths) {
      final asset = AssetId.resolve(path, from: step.inputId);
      String content;
      try {
        content = await step.readAsString(asset);
      } catch (e) {
        errors.add(MoorError(
            critical: true,
            message: 'The included file $path could not be found'));
      }

      final parsed = await MoorAnalyzer(content).analyze();
      foundTables.addAll(
          parsed.parsedFile.declaredTables.map((t) => t.extractTable(mapper)));

      for (var parseError in parsed.errors) {
        errors.add(MoorError(message: "Can't parse sql in $path: $parseError"));
      }
    }

    return foundTables;
  }

  /// Parses a column from a getter [e] declared inside a table class and its
  /// resolved AST node [m].
  Future<SpecifiedColumn> parseColumn(MethodDeclaration m, Element e) {
    return Future.value(_columnParser.parse(m, e));
  }

  Future<List<SqlQuery>> parseQueries(
      Map<DartObject, DartObject> fromAnnotation,
      List<SpecifiedTable> availableTables) {
    // no queries declared, so there is no point in starting a sql engine
    if (fromAnnotation.isEmpty) return Future.value([]);

    final parser = SqlParser(this, availableTables, fromAnnotation)..parse();

    return Future.value(parser.foundQueries);
  }
}
