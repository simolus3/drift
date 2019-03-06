import 'package:analyzer/dart/element/type.dart';
import 'package:sally/sally.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/results.dart'; // ignore: implementation_imports
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:sally_generator/src/errors.dart';
import 'package:sally_generator/src/model/specified_database.dart';
import 'package:sally_generator/src/model/specified_table.dart';
import 'package:sally_generator/src/parser/column_parser.dart';
import 'package:sally_generator/src/parser/table_parser.dart';
import 'package:sally_generator/src/writer/database_writer.dart';
import 'package:source_gen/source_gen.dart';

class SallyGenerator extends GeneratorForAnnotation<UseSally> {
  //final Map<String, ParsedLibraryResult> _astForLibs = {};
  final ErrorStore errors = ErrorStore();

  TableParser tableParser;
  ColumnParser columnParser;

  final tableTypeChecker = const TypeChecker.fromRuntime(Table);

  final Map<DartType, SpecifiedTable> _foundTables = {};

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

    tableParser ??= TableParser(this);
    columnParser ??= ColumnParser(this);

    final tablesForThisDb = <SpecifiedTable>[];

    for (var table in tableTypes) {
      if (!tableTypeChecker.isAssignableFrom(table.element)) {
        errors.add(SallyError(
            critical: true,
            message: 'The type $table is not a sally table',
            affectedElement: element));
      } else {
        final specifiedTable = tableParser.parse(table.element as ClassElement);
        _foundTables[table] = specifiedTable;
        tablesForThisDb.add(specifiedTable);
      }
    }

    if (errors.errors.isNotEmpty) {
      print('Warning: There were some errors whily running sally_generator:');

      for (var error in errors.errors) {
        print(error.message);

        if (error.affectedElement != null) {
          final span = spanForElement(error.affectedElement);
          print('${span.start.toolString}\n${span.highlight()}');
        }
      }
      errors.errors.clear();
    }

    if (_foundTables.isEmpty) return '';

    final specifiedDb =
        SpecifiedDatabase(element as ClassElement, tablesForThisDb, daoTypes);

    final buffer = StringBuffer();
    DatabaseWriter(specifiedDb).write(buffer);

    return buffer.toString();
  }
}
