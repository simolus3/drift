import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/results.dart'; // ignore: implementation_imports
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:sally_generator/src/errors.dart';
import 'package:sally_generator/src/parser/column_parser.dart';
import 'package:sally_generator/src/parser/table_parser.dart';
import 'package:source_gen/source_gen.dart';

class SallyGenerator extends Generator {
  final Map<String, ParsedLibraryResult> _astForLibs = {};
  final ErrorStore errors = ErrorStore();

  TableParser tableParser;
  ColumnParser columnParser;

  ElementDeclarationResult loadElementDeclaration(Element element) {
    final result = _astForLibs.putIfAbsent(element.library.name, () {
      // ignore: deprecated_member_use
      return ParsedLibraryResultImpl.tmp(element.library);
    });

    return result.getElementDeclaration(element);
  }

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final testUsers = library.findType('Users');

    if (testUsers == null) return '';

    TableParser(this).parse(testUsers);

    return '';
  }
}
