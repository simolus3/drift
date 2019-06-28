import 'package:analyzer/dart/element/type.dart';
import 'package:moor/moor.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/results.dart'; // ignore: implementation_imports
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:moor_generator/src/errors.dart';
import 'package:moor_generator/src/model/specified_database.dart';
import 'package:moor_generator/src/model/specified_table.dart';
import 'package:moor_generator/src/options.dart';
import 'package:moor_generator/src/parser/column_parser.dart';
import 'package:moor_generator/src/parser/table_parser.dart';
import 'package:moor_generator/src/writer/database_writer.dart';
import 'package:source_gen/source_gen.dart';

import 'model/sql_query.dart';
import 'parser/sql/sql_parser.dart';

class MoorGenerator extends GeneratorForAnnotation<UseMoor> {
  //final Map<String, ParsedLibraryResult> _astForLibs = {};
  final ErrorStore errors = ErrorStore();
  final MoorOptions options;

  TableParser tableParser;
  ColumnParser columnParser;

  final tableTypeChecker = const TypeChecker.fromRuntime(Table);

  final Map<DartType, SpecifiedTable> _foundTables = {};

  MoorGenerator(this.options);

  ElementDeclarationResult loadElementDeclaration(Element element) {
    /*final result = _astForLibs.putIfAbsent(element.library.name, () {
      // ignore: deprecated_member_use
      return ParsedLibraryResultImpl.tmp(element.library);
    });*/
    // ignore: deprecated_member_use
    final result = ParsedLibraryResultImpl.tmp(element.library);
    return result.getElementDeclaration(element);
  }

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final tableTypes =
        annotation.peek('tables').listValue.map((obj) => obj.toTypeValue());
    final daoTypes = annotation
        .peek('daos')
        .listValue
        .map((obj) => obj.toTypeValue())
        .toList();
    final queries = annotation.peek('queries')?.listValue ?? [];

    tableParser ??= TableParser(this);
    columnParser ??= ColumnParser(this);

    final tablesForThisDb = <SpecifiedTable>[];
    var resolvedQueries = <SqlQuery>[];

    for (var table in tableTypes) {
      if (!tableTypeChecker.isAssignableFrom(table.element)) {
        errors.add(MoorError(
            critical: true,
            message: 'The type $table is not a moor table',
            affectedElement: element));
      } else {
        final specifiedTable = tableParser.parse(table.element as ClassElement);
        _foundTables[table] = specifiedTable;
        tablesForThisDb.add(specifiedTable);
      }
    }

    if (errors.errors.isNotEmpty) {
      print('Warning: There were some errors while running moor_generator:');

      for (var error in errors.errors) {
        print(error.message);

        if (error.affectedElement != null) {
          final span = spanForElement(error.affectedElement);
          print('${span.start.toolString}\n${span.highlight()}');
        }
      }
      errors.errors.clear();
    }

    if (queries.isNotEmpty) {
      final parser = SqlParser(options, tablesForThisDb, queries)..parse();
      errors.errors.addAll(parser.errors);

      resolvedQueries = parser.foundQueries;
    }

    if (_foundTables.isEmpty) return '';

    final specifiedDb = SpecifiedDatabase(
        element as ClassElement, tablesForThisDb, daoTypes, resolvedQueries);

    final buffer = StringBuffer()
      ..write('// ignore_for_file: unnecessary_brace_in_string_interps\n');

    DatabaseWriter(specifiedDb, options).write(buffer);

    return buffer.toString();
  }
}
