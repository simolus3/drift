import 'package:analyzer/dart/element/type.dart';
import 'package:sally/sally.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/results.dart'; // ignore: implementation_imports
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:sally_generator/src/errors.dart';
import 'package:sally_generator/src/model/specified_table.dart';
import 'package:sally_generator/src/parser/column_parser.dart';
import 'package:sally_generator/src/parser/table_parser.dart';
import 'package:sally_generator/src/writer/table_writer.dart';
import 'package:source_gen/source_gen.dart';

class SallyGenerator extends GeneratorForAnnotation<UseSally> {
  final Map<String, ParsedLibraryResult> _astForLibs = {};
  final ErrorStore errors = ErrorStore();

  TableParser tableParser;
  ColumnParser columnParser;

  final tableTypeChecker = const TypeChecker.fromRuntime(Table);

  final Map<DartType, SpecifiedTable> _foundTables = {};

  ElementDeclarationResult loadElementDeclaration(Element element) {
    final result = _astForLibs.putIfAbsent(element.library.name, () {
      // ignore: deprecated_member_use
      return ParsedLibraryResultImpl.tmp(element.library);
    });

    return result.getElementDeclaration(element);
  }

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    final types =
        annotation.peek('tables').listValue.map((obj) => obj.toTypeValue());

    tableParser ??= TableParser(this);
    columnParser ??= ColumnParser(this);

    for (var table in types) {
      if (!tableTypeChecker.isAssignableFrom(table.element)) {
        errors.add(SallyError(
            critical: true,
            message: 'The type $table is not a sally table',
            affectedElement: element));
      } else {
        _foundTables[table] = tableParser.parse(table.element as ClassElement);
      }
    }

    if (_foundTables.isEmpty)
      return '';

    final buffer = StringBuffer();
    for (var tbl in _foundTables.values) {
      TableWriter(tbl).writeInto(buffer);
    }

    return buffer.toString();
  }
}
